import Foundation
import Network
import Combine

struct StackResult: Equatable {
    var ip: String
    /// Страна из MaxMind-базы (api.country.is) — то, что видит большинство сайтов.
    /// Для "виртуальных" локаций VPN — заявленная провайдером страна.
    var registeredCountry: String
    /// Оценка Cloudflare по измерениям — фактическое расположение сервера.
    var physicalCountry: String
}

enum GeoMode: String {
    case virtualLocation = "virtual"
    case physicalLocation = "physical"
}

@MainActor
final class IPMonitor: ObservableObject {
    @Published var v4: StackResult?
    @Published var v6: StackResult?
    @Published var offline: Bool = false
    @Published var geoMode: GeoMode {
        didSet { UserDefaults.standard.set(geoMode.rawValue, forKey: "GeoMode") }
    }
    @Published var compact: Bool {
        didSet { UserDefaults.standard.set(compact, forKey: "CompactWindow") }
    }

    private var session: URLSession
    private var timer: Timer?
    private let pathMonitor = NWPathMonitor()
    private var inFlight = false
    private var lastFetch: Date = .distantPast
    private var lastSessionReset: Date = .distantPast

    // IP-литералы форсируют версию протокола: 1.1.1.1 — только IPv4,
    // 2606:4700:4700::1111 — только IPv6. Оба — Cloudflare DNS с валидным сертификатом.
    private static let v4URL = URL(string: "https://1.1.1.1/cdn-cgi/trace")!
    private static let v6URL = URL(string: "https://[2606:4700:4700::1111]/cdn-cgi/trace")!

    // Страна по IP. Геобаза Cloudflare отражает физическое расположение сервера,
    // а "виртуальные" локации VPN зарегистрированы только в MaxMind — поэтому страну
    // берём из api.country.is (MaxMind GeoLite2), loc= Cloudflare остаётся фолбэком.
    // Результат кэшируется по IP: сеть дёргается только при смене адреса.
    private var geoCache: [String: String] = [:]

    init() {
        geoMode = GeoMode(rawValue: UserDefaults.standard.string(forKey: "GeoMode") ?? "") ?? .virtualLocation
        compact = UserDefaults.standard.bool(forKey: "CompactWindow")
        session = Self.makeSession()
        lastSessionReset = Date()
    }

    private static func makeSession() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 5
        cfg.timeoutIntervalForResource = 8
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: cfg)
    }

    // Сессия держит keep-alive сокеты к Cloudflare, а постоянный опрос не даёт им
    // закрыться. При поднятии VPN старый сокет может продолжать жить через физический
    // интерфейс — и Cloudflare бесконечно видит старый IP. Поэтому при смене сетевого
    // пути (и раз в минуту для страховки) сбрасываем пул соединений.
    private func resetSession() {
        session.finishTasksAndInvalidate()
        session = Self.makeSession()
        lastSessionReset = Date()
    }

    /// Основной результат для флага/страны: v4 приоритетнее.
    var primary: StackResult? { v4 ?? v6 }

    /// Страна с учётом выбранного режима отображения.
    func country(of result: StackResult) -> String {
        geoMode == .virtualLocation ? result.registeredCountry : result.physicalCountry
    }

    var flag: String { Self.flagEmoji(primary.map { country(of: $0) }) }
    var flag6: String { Self.flagEmoji(v6.map { country(of: $0) }) }

    /// Страны v4 и v6 различаются — признак утечки одного из протоколов мимо VPN.
    var countryMismatch: Bool {
        guard let a = v4, let b = v6 else { return false }
        return country(of: a) != country(of: b)
    }

    static func flagEmoji(_ cc: String?) -> String {
        guard let cc, cc.count == 2 else { return "🏳️" }
        var s = ""
        for u in cc.uppercased().unicodeScalars {
            guard let scalar = Unicode.Scalar(127397 + u.value) else { return "🏳️" }
            s.unicodeScalars.append(scalar)
        }
        return s
    }

    func start() {
        // Мок для визуальной проверки раскладки "страны не совпали": сеть не опрашивается.
        if ProcessInfo.processInfo.arguments.contains("--mock-mismatch") {
            v4 = StackResult(ip: "46.102.25.0", registeredCountry: "PT", physicalCountry: "PT")
            v6 = StackResult(ip: "2a12:26c0:5483:3a00:d524:5be5:fa55:fbb7", registeredCountry: "RU", physicalCountry: "FR")
            return
        }

        pathMonitor.pathUpdateHandler = { [weak self] _ in
            Task { @MainActor in
                self?.resetSession()
                self?.refresh(force: true)
            }
        }
        pathMonitor.start(queue: .global(qos: .utility))

        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh(force: true)
    }

    func refresh(force: Bool = false) {
        if inFlight { return }
        if !force && Date().timeIntervalSince(lastFetch) < 1.0 { return }
        if Date().timeIntervalSince(lastSessionReset) > 60 { resetSession() }
        inFlight = true
        lastFetch = Date()
        Task {
            await fetch()
            inFlight = false
        }
    }

    private func fetch() async {
        async let r4 = fetchTrace(Self.v4URL)
        async let r6 = fetchTrace(Self.v6URL)
        let (t4, t6) = await (r4, r6)

        if t4 == nil && t6 == nil {
            offline = true
            return
        }
        offline = false

        async let c4 = resolveCountry(t4)
        async let c6 = resolveCountry(t6)
        let (n4, n6) = await (c4, c6)
        if n4 != v4 { v4 = n4 }
        if n6 != v6 { v6 = n6 }
    }

    private func fetchTrace(_ url: URL) async -> (ip: String, loc: String)? {
        do {
            let (data, _) = try await session.data(from: url)
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            var ip: String?
            var loc: String?
            for line in text.split(separator: "\n") {
                if line.hasPrefix("ip=") { ip = String(line.dropFirst(3)) }
                else if line.hasPrefix("loc=") { loc = String(line.dropFirst(4)) }
            }
            guard let ip, let loc else { return nil }
            return (ip, loc)
        } catch {
            return nil
        }
    }

    private func resolveCountry(_ trace: (ip: String, loc: String)?) async -> StackResult? {
        guard let trace else { return nil }
        if let cached = geoCache[trace.ip] {
            return StackResult(ip: trace.ip, registeredCountry: cached, physicalCountry: trace.loc)
        }

        if let cc = await lookupRegisteredCountry(trace.ip) {
            geoCache[trace.ip] = cc
            return StackResult(ip: trace.ip, registeredCountry: cc, physicalCountry: trace.loc)
        }

        // Фолбэк на оценку Cloudflare; не кэшируем, чтобы повторить попытку на следующем опросе.
        return StackResult(ip: trace.ip, registeredCountry: trace.loc, physicalCountry: trace.loc)
    }

    /// Зарегистрированная страна IP: сначала ipwho.is (совпадает с тем, что показывают
    /// сайты, включая свежие виртуальные локации VPN), затем api.country.is как запасной.
    private func lookupRegisteredCountry(_ ip: String) async -> String? {
        struct WhoResponse: Decodable {
            let success: Bool?
            let country_code: String?
        }
        if let url = URL(string: "https://ipwho.is/\(ip)?fields=success,country_code"),
           let (data, response) = try? await session.data(from: url),
           (response as? HTTPURLResponse)?.statusCode == 200,
           let who = try? JSONDecoder().decode(WhoResponse.self, from: data),
           who.success != false,
           let cc = who.country_code, cc.count == 2 {
            return cc
        }

        struct GeoResponse: Decodable { let country: String }
        if let url = URL(string: "https://api.country.is/\(ip)"),
           let (data, response) = try? await session.data(from: url),
           (response as? HTTPURLResponse)?.statusCode == 200,
           let geo = try? JSONDecoder().decode(GeoResponse.self, from: data),
           geo.country.count == 2 {
            return geo.country
        }
        return nil
    }
}
