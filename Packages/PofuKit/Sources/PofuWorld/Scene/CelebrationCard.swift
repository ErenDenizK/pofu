#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// A celebration moment (a station's new level, a new island) on the kit's
/// stitched paper card (asset system v1 section 2.3: stitched paper is for
/// rewards and days), the kicker on the speaker tab's ribbon. The rule
/// (look-dev C): **system UI is glass, celebration is painted.** Night
/// follows the world's hour, never the system's mode.
public struct CelebrationCard: View {
    let kicker: String
    let title: String
    let detail: String?

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme

    public init(kicker: String, title: String, detail: String? = nil) {
        self.kicker = kicker
        self.title = title
        self.detail = detail
    }

    private var palette: PofuKitPalette { (night ?? (scheme == .dark)) ? .night : .day }

    public var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(palette.onPaper)
                .multilineTextAlignment(.center)
            if let detail {
                Text(verbatim: detail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.onPaper.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 34)
        .padding(.bottom, 24)
        .frame(minWidth: 220)
        .background { PofuPaperSurface(kind: .stitched) }
        .overlay(alignment: .top) {
            // The kicker rides the ribbon tab, the one bubble's speaker tab (the bow, `ui-pin-ribbon`,
            // is a ribbon of its own and has no hook yet).
            PofuSpeakerTab(Text(verbatim: kicker.uppercased()), tint: PofuKitPalette.rgb(0xE8946B))
                .offset(y: -12)
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// The small level-up tag's paper: the kit's stitched strip, made for a line or two.
    func paintedPaper() -> some View {
        background { PofuStripSurface() }
    }
}

extension Color {
    /// Warm brown ink for painted surfaces (never black).
    static let paperInk = Color(red: 0.36, green: 0.24, blue: 0.16)
}
#endif
