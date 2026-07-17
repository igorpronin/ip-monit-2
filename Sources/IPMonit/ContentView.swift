import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var monitor: IPMonitor
    @ObservedObject var l10n = L10n.shared

    var body: some View {
        content
            .shadow(color: .black.opacity(0.7), radius: 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contextMenu {
                Button(l10n.t(.refreshNow)) { monitor.refresh(force: true) }
                Button(l10n.t(.copyIPv4)) { copy(monitor.v4?.ip) }
                    .disabled(monitor.v4 == nil)
                Button(l10n.t(.copyIPv6)) { copy(monitor.v6?.ip) }
                    .disabled(monitor.v6 == nil)
                Divider()
                Button(l10n.t(.hideWindow)) {
                    (NSApp.delegate as? AppDelegate)?.setPanelVisible(false)
                }
                Button(l10n.t(.about)) {
                    (NSApp.delegate as? AppDelegate)?.showAbout()
                }
                Divider()
                Button(l10n.t(.quit)) { NSApp.terminate(nil) }
            }
    }

    @ViewBuilder
    private var content: some View {
        if monitor.offline {
            HStack(spacing: 6) {
                Text("🚫")
                    .font(.system(size: 15))
                Text(l10n.t(.noInternet))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.orange)
            }
        } else if monitor.countryMismatch, let v4 = monitor.v4, let v6 = monitor.v6 {
            // Страны не совпали: IPv6 — отдельным блоком со своей страной, ниже, через разделитель.
            let cc4 = monitor.country(of: v4)
            let cc6 = monitor.country(of: v6)
            VStack(alignment: .leading, spacing: 3) {
                block(
                    flag: IPMonitor.flagEmoji(cc4),
                    country: l10n.countryName(cc4),
                    lines: [("v4", v4.ip)]
                )
                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(height: 0.5)
                block(
                    flag: IPMonitor.flagEmoji(cc6),
                    country: l10n.countryName(cc6),
                    lines: [("v6", v6.ip)],
                    tint: .orange
                )
            }
        } else if let primary = monitor.primary {
            // Один смысловой блок; недоступный протокол не показывается вовсе.
            let cc = monitor.country(of: primary)
            block(
                flag: IPMonitor.flagEmoji(cc),
                country: l10n.countryName(cc),
                lines: [("v4", monitor.v4?.ip), ("v6", monitor.v6?.ip)]
                    .compactMap { label, ip in ip.map { (label, $0) } }
            )
        } else {
            block(flag: "🏳️", country: l10n.t(.detecting), lines: [])
        }
    }

    private func block(flag: String, country: String, lines: [(String, String)], tint: Color = .white) -> some View {
        HStack(spacing: 6) {
            Text(flag)
                .font(.system(size: 15))
            VStack(alignment: .leading, spacing: 0) {
                Text(country)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(tint)
                ForEach(lines, id: \.0) { label, ip in
                    HStack(spacing: 3) {
                        Text(label)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(tint.opacity(0.5))
                        Text(ip)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(tint.opacity(0.85))
                    }
                }
            }
        }
    }

    private func copy(_ value: String?) {
        guard let value else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
