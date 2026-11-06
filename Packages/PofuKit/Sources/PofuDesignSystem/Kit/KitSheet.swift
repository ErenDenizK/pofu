#if canImport(SwiftUI)
import SwiftUI

/// The kit sheet: every component in every state, in one scroll, for
/// review screenshots (day or night; the caller sets Dynamic Type).
public struct PofuKitSheet: View {
    let night: Bool
    let scrolls: Bool

    /// `scrolls: false` lays everything out at its full height, for
    /// image rendering.
    public init(night: Bool, scrolls: Bool = true) {
        self.night = night
        self.scrolls = scrolls
    }

    private var palette: PofuKitPalette { night ? .night : .day }

    public var body: some View {
        if scrolls {
            ScrollView { content }.background { PofuPaperSheetBackground() }.pofuNight(night).environment(\.colorScheme, night ? .dark : .light)
        } else {
            content.background { PofuPaperSheetBackground() }.pofuNight(night).environment(\.colorScheme, night ? .dark : .light)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.xl) {
                Text(verbatim: night ? "Kit v3 · night" : "Kit v3 · day")
                    .font(PofuFont.title2)
                    .foregroundStyle(palette.onPaper)
                    .accessibilityAddTraits(.isHeader)
                section("Plaque") {
                    Button("Boş ver") {}.buttonStyle(PofuPlaqueStyle(.primary))
                    Button("Boş ver, pressed") {}.buttonStyle(PofuPlaqueStyle(.primary)).environment(\.pofuForcePressed, true)
                    Button("3 dakika") {}.buttonStyle(PofuPlaqueStyle(.secondary))
                    Button("Şimdi değil") {}.buttonStyle(PofuPlaqueStyle(.quiet))
                    PofuPlaqueButton("20 çekirdek daha", reason: "Çekirdeklerin yetmiyor", isDisabled: true) {}
                    Button("Odakta") {}.buttonStyle(PofuPlaqueStyle(.primary)).environment(\.pofuForceFocused, true)
                }
                section("Chip") {
                    HStack {
                        Button("Instagram") {}.buttonStyle(PofuChipStyle(isSelected: true))
                        Button("YouTube") {}.buttonStyle(PofuChipStyle())
                        Button("TikTok") {}.buttonStyle(PofuChipStyle()).disabled(true)
                    }
                }
                section("Speech bubble") {
                    PofuPaperBubble(speaker: "Nazlı") {
                        Text(verbatim: "Bugün üç kez boş verdin. Çay benden.")
                    }
                }
                section("Card") {
                    Text(verbatim: "Dikişli kâğıt: ödül ve bilgi.").font(PofuFont.body).foregroundStyle(palette.onPaper).pofuKitCard(.stitched)
                    Text(verbatim: "Keten: sayılar.").font(PofuFont.body).foregroundStyle(palette.onPaper).pofuKitCard(.linen)
                    Text(verbatim: "Ahşap: oyun.").font(PofuFont.body).foregroundStyle(palette.onPaper).pofuKitCard(.wood)
                }
                section("Toast") {
                    PofuToast("Bahçe bir tur dinlendi.", systemImage: "leaf.fill")
                }
                section("Progress") {
                    PofuGroove(progress: 0.0)
                    PofuGroove(progress: 0.4, pips: 5)
                    PofuGroove(progress: 1.0)
                }
            }
        .padding(PofuSpacing.screen)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            Text(verbatim: title.uppercased())
                .font(PofuFont.caption)
                .foregroundStyle(palette.isNight ? palette.onPaper.opacity(0.7) : palette.inkSoft)
            content()
        }
    }
}
#endif
