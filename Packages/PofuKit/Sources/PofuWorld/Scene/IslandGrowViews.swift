#if os(iOS)
import SwiftUI

/// "Ada büyüdü" over the island (`IslandGrowMoment`): a warm bloom rising
/// from the island's centre, and the "Ada n" card above the island with
/// Pofu's line under it. Nothing here keeps time: it draws the moment at
/// `time`.
struct IslandGrowOverlay: View {
    let grow: ActiveIslandGrow
    let time: Double
    /// The island's centre on screen.
    let centre: CGPoint
    let size: CGSize
    let safeTop: Double
    /// A tap while the card shows sends it away.
    let onTap: () -> Void

    private var moment: IslandGrowMoment {
        grow.moment
    }

    var body: some View {
        let card = moment.card(at: time, leavesAt: grow.leavesAt)
        ZStack(alignment: .top) {
            IslandBloom(strength: moment.bloom(at: time) * moment.bloomOpacity, centre: centre, size: size)
            if let card {
                // A tap anywhere sends the card away; the world waits.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTap)
                CelebrationCard(
                    kicker: WorldStrings.islandGrewKicker,
                    title: WorldStrings.islandTitle(moment.toLevel),
                    detail: WorldStrings.islandGrowLine(moment.toLevel)
                )
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, safeTop + 56)
                .opacity(card.opacity)
                .offset(y: CGFloat(-20 * card.rise))
                .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .top)
    }
}

/// The warm light of the island's growth: one radial bloom, drawn additively
/// like the station's level-up light (`LevelUpBloom`), island-wide.
private struct IslandBloom: View {
    let strength: Double
    let centre: CGPoint
    let size: CGSize

    /// The same warm tone the station's ceremony uses.
    private let tint = Color(red: 1.0, green: 0.80, blue: 0.48)

    var body: some View {
        if strength > 0.001 {
            Canvas(rendersAsynchronously: false) { context, canvas in
                var glow = context
                glow.blendMode = .plusLighter
                let radius = max(canvas.width, canvas.height) * 0.62
                let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
                glow.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [tint.opacity(strength * 0.9), tint.opacity(strength * 0.35), tint.opacity(0)]),
                        center: centre, startRadius: 0, endRadius: radius
                    )
                )
            }
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
#endif
