import Foundation
import Network
import Combine

struct StackResult: Equatable {
    var ip: String
    var countryCode: String
}

@MainActor
final class IPMonitor: ObservableObject {
    @Published var v4: StackResult?
    @Published var v6: StackResult?
    @Published var offline: Bool = false

    private let session: URLSession
    private var timer: Timer?
    private let pathMonitor = NWPathMonitor()
    private var inFlight = false
    private var lastFetch: Date = .distantPast

    // IP-литералы форсируют версию протокола: 1.1.1.1 — только IPv4,
    // 2606:4700:4700::1111 — только IPv6. Оба — Cloudflare DNS с валидным сертификатом.
    private static let v4URL = URL(string: "https://1.1.1.1/cdn-cgi/trace")!
    private static let v6URL = URL(string: "https://[2606:4700:4700::1111]/cdn-cgi/trace")!

    init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 5
        cfg.timeoutIntervalForResource = 8
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: cfg)
    }

    /// Основной результат для флага/страны: v4 приоритетнее.
    var primary: StackResult? { v4 ?? v6 }

    var flag: String { Self.flagEmoji(primary?.countryCode) }
    var flag6: String { Self.flagEmoji(v6?.countryCode) }

    /// Страны v4 и v6 различаются — признак утечки одного из протоколов мимо VPN.
    var countryMismatch: Bool {
        guard let a = v4?.countryCode, let b = v6?.countryCode else { return false }
        return a != b
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
            v4 = StackResult(ip: "46.102.25.0", countryCode: "PT")
            v6 = StackResult(ip: "2a12:26c0:5483:3a00:d524:5be5:fa55:fbb7", countryCode: "RU")
            return
        }

        pathMonitor.pathUpdateHandler = { [weak self] _ in
            Task { @MainActor in self?.refresh(force: true) }
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
        let (n4, n6) = await (r4, r6)

        if n4 == nil && n6 == nil {
            offline = true
            return
        }
        offline = false
        if n4 != v4 { v4 = n4 }
        if n6 != v6 { v6 = n6 }
    }

    private func fetchTrace(_ url: URL) async -> StackResult? {
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
            return StackResult(ip: ip, countryCode: loc)
        } catch {
            return nil
        }
    }
}
