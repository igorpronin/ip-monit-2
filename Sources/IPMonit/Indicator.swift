import SwiftUI
import AppKit

enum IndicatorPalette {
    static let all: [(name: String, color: Color)] = [
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("red", .red),
        ("orange", .orange),
        ("purple", .purple),
    ]

    static func color(_ name: String) -> Color {
        all.first { $0.name == name }?.color ?? .gray
    }
}

/// Светящаяся полоска: цвет по правилу для текущей страны (в выбранном режиме MM/CF),
/// серая без свечения — если совпадения нет, офлайн или страна ещё не определена.
struct IndicatorView: View {
    @ObservedObject var monitor: IPMonitor

    var body: some View {
        let active = activeColor
        Capsule()
            .fill(active ?? Color.gray.opacity(0.45))
            .frame(width: 800, height: 6)
            .shadow(color: (active ?? .clear).opacity(0.85), radius: 4)
            .shadow(color: (active ?? .clear).opacity(0.5), radius: 9)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
    }

    private var activeColor: Color? {
        guard !monitor.offline,
              let primary = monitor.primary,
              let name = monitor.indicatorRules[monitor.country(of: primary)] else { return nil }
        return IndicatorPalette.color(name)
    }
}

struct IndicatorSettingsView: View {
    @ObservedObject var monitor: IPMonitor
    @ObservedObject var l10n = L10n.shared
    @State private var selectedCountry: String = "FR"
    @State private var selectedColor: String = "yellow"

    private var allCountries: [(code: String, name: String)] {
        Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
            .map { ($0, l10n.countryName($0)) }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !monitor.indicatorRules.isEmpty {
                ForEach(
                    monitor.indicatorRules.sorted { l10n.countryName($0.key) < l10n.countryName($1.key) },
                    id: \.key
                ) { cc, colorName in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(IndicatorPalette.color(colorName))
                            .frame(width: 10, height: 10)
                        Text("\(IPMonitor.flagEmoji(cc)) \(l10n.countryName(cc))")
                        Spacer()
                        Button {
                            monitor.indicatorRules.removeValue(forKey: cc)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Divider()
            }
            HStack(spacing: 8) {
                Picker("", selection: $selectedCountry) {
                    ForEach(allCountries, id: \.code) { country in
                        Text("\(IPMonitor.flagEmoji(country.code)) \(country.name)").tag(country.code)
                    }
                }
                .labelsHidden()
                .frame(width: 180)

                ForEach(IndicatorPalette.all, id: \.name) { entry in
                    Button {
                        selectedColor = entry.name
                    } label: {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle().strokeBorder(
                                    Color.primary.opacity(selectedColor == entry.name ? 0.9 : 0),
                                    lineWidth: 2
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button(l10n.t(.add)) {
                    monitor.indicatorRules[selectedCountry] = selectedColor
                }
            }
        }
        .padding(16)
        .frame(width: 440)
    }
}
