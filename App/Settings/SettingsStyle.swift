import PofuDesignSystem
import SwiftUI

/// The kit's look for the native Settings list (UI v3 section 2, ADR-0020:
/// Settings stays a system `List`; paint is the header, the row surface,
/// the icons and the toggle tint).
enum SettingsTone {
    case honey, moss, cocoa

    func fill(_ palette: PofuKitPalette) -> Color {
        switch self {
        case .honey: palette.honey
        case .moss: PofuKitPalette.rgb(0x7FA36B)
        case .cocoa: palette.inkSoft
        }
    }
}

/// A two-tone row icon: a SF Symbol in cocoa and the tone on a soft tile,
/// until the batch-46 duo icons land.
struct SettingsIcon: View {
    let systemName: String
    let tone: SettingsTone
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 30

    var body: some View {
        let palette: PofuKitPalette = scheme == .dark ? .night : .day
        let ink = palette.isNight ? palette.onPaper : palette.ink
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(tone.fill(palette).opacity(palette.isNight ? 0.28 : 0.3))
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: systemName)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(ink, tone.fill(palette))
                    .font(.system(size: side * 0.5, weight: .semibold))
            }
            .accessibilityHidden(true)
    }
}

struct SettingsLabel: View {
    let title: LocalizedStringKey
    let systemName: String
    var tone: SettingsTone = .honey

    init(_ title: LocalizedStringKey, systemName: String, tone: SettingsTone = .honey) {
        self.title = title
        self.systemName = systemName
        self.tone = tone
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            SettingsIcon(systemName: systemName, tone: tone)
        }
    }
}

/// Paper rows on a linen canvas, ink text, moss (day) or amber (night)
/// toggles.
struct SettingsListStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let palette: PofuKitPalette = scheme == .dark ? .night : .day
        content
            .tint(scheme == .dark ? palette.honey : PofuKitPalette.rgb(0x7FA36B))
            .foregroundStyle(palette.onPaper)
            .scrollContentBackground(.hidden)
            .background(palette.linen.ignoresSafeArea())
    }
}

struct SettingsRowSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.listRowBackground(scheme == .dark ? PofuKitPalette.night.paperTop : PofuKitPalette.day.paperTop)
    }
}

extension View {
    func settingsList() -> some View { modifier(SettingsListStyle()) }
    func settingsRow() -> some View { modifier(SettingsRowSurface()) }
}

/// The painted header: a paper band with Pofu's face and "Ayarlar".
struct SettingsHeader: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette: PofuKitPalette = scheme == .dark ? .night : .day
        HStack(spacing: PofuSpacing.m) {
            PofuPaintedIcon(.iconMoodContent, size: 56)
                .padding(PofuSpacing.xs)
                .background { Circle().fill(palette.felt) }
                .overlay { Circle().strokeBorder(palette.stitch.opacity(0.7), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])) }
                .accessibilityHidden(true)
            Text("Settings")
                .font(PofuFont.largeTitle)
                .foregroundStyle(palette.onPaper)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
        }
        .pofuKitCard(.stitched)
        .accessibilityElement(children: .combine)
    }
}
