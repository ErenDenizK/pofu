#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// A small clay pot, drawn in code until the batch-61 `ui-pip-pot` art
/// lands (UI v3 section 5, Progress). Three states: empty (a bare pot),
/// bud (the level the player is working toward, a sprout) and bloom (a
/// built level, a small flower).
struct PotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rim = rect.height * 0.28
        path.addRoundedRect(
            in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rim),
            cornerSize: CGSize(width: rim * 0.4, height: rim * 0.4)
        )
        let inset = rect.width * 0.14
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + rim - 0.5))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rim - 0.5))
        path.addLine(to: CGPoint(x: rect.maxX - inset * 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset * 2, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct PotPip: View {
    enum Stage { case empty, bud, bloom }
    let state: Stage
    let size: CGFloat
    let palette: PofuKitPalette

    private static let moss = PofuKitPalette.rgb(0x7FA36B)
    private static let clay = PofuKitPalette.rgb(0xC9805A)

    var body: some View {
        ZStack(alignment: .bottom) {
            // The plant, behind the pot.
            switch state {
            case .empty:
                EmptyView()
            case .bud:
                Capsule().fill(Self.moss)
                    .frame(width: size * 0.12, height: size * 0.34)
                    .offset(y: -size * 0.64)
            case .bloom:
                ZStack {
                    Capsule().fill(Self.moss).frame(width: size * 0.1, height: size * 0.4).offset(y: size * 0.18)
                    Circle().fill(palette.honey).frame(width: size * 0.42, height: size * 0.42)
                    Circle().fill(palette.ink.opacity(0.8)).frame(width: size * 0.16, height: size * 0.16)
                }
                .offset(y: -size * 0.62)
            }
            PotShape()
                .fill(state == .empty ? palette.felt : Self.clay)
                .overlay { PotShape().stroke(palette.edge.opacity(palette.isNight ? 0.7 : 0.35), lineWidth: 1.2) }
                .frame(width: size * 0.74, height: size * 0.62)
        }
        .frame(width: size, height: size * 1.25, alignment: .bottom)
    }
}

/// The station's level as a row of painted pots: built levels bloom, the
/// next one buds, the rest are bare. Live text for VoiceOver comes from
/// the caller (the row itself is hidden from it).
struct PotPips: View {
    let level: Int
    let maxLevel: Int
    let palette: PofuKitPalette
    @ScaledMetric(relativeTo: .title2) private var size: CGFloat = 30

    var body: some View {
        HStack(alignment: .bottom, spacing: PofuSpacing.s) {
            ForEach(1...max(maxLevel, 1), id: \.self) { index in
                PotPip(
                    state: index <= level ? .bloom : (index == level + 1 ? .bud : .empty),
                    size: size,
                    palette: palette
                )
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
