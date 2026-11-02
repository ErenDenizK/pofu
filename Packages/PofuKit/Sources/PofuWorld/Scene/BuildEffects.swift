#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// The build moment's dust puffs and sparkles, around a station's footprint
/// on the world canvas (interaction spec §2.4). Positions come from
/// `BuildMoment`; nothing here keeps time.
struct BuildParticles: View {
    let moment: BuildMoment
    let time: Double
    /// The footprint on the canvas.
    let point: CGPoint

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(moment.puffs(at: time).enumerated()), id: \.offset) { item in
                let puff = item.element
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.95), Color(red: 0.98, green: 0.94, blue: 0.86).opacity(0.7), Color.white.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 30, height: 30)
                    .scaleEffect(CGFloat(puff.scale))
                    .opacity(puff.opacity)
                    .position(x: point.x + CGFloat(puff.x), y: point.y + CGFloat(puff.y))
            }
            ForEach(Array(moment.sparkles(at: time).enumerated()), id: \.offset) { item in
                let sparkle = item.element
                SparkleShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, PofuPrimitive.honey300.rgb.color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 14)
                    .shadow(color: PofuPrimitive.honey400.rgb.color.opacity(0.7), radius: 2.5)
                    .scaleEffect(CGFloat(sparkle.scale))
                    .rotationEffect(.degrees(sparkle.rotation))
                    .opacity(sparkle.opacity)
                    .position(x: point.x + CGFloat(sparkle.x), y: point.y + CGFloat(sparkle.y))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A four-pointed sparkle.
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let waist = r * 0.28
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - r))
        path.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + waist, y: c.y - waist))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + waist, y: c.y + waist))
        path.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - waist, y: c.y + waist))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - waist, y: c.y - waist))
        path.closeSubpath()
        return path
    }
}

/// A station's level, where its art is a stand-in shared by every level
/// (the build's swap still flips it inside the squash): a small cream disc
/// with the numeral, on the vignette's upper right.
struct LevelBadge: View {
    let level: Int

    var body: some View {
        Text(verbatim: "\(level)")
            .font(.system(size: 7.5, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(PofuPrimitive.ink700.rgb.color)
            .frame(width: 12, height: 12)
            .background(Circle().fill(PofuPrimitive.cream50.rgb.color))
            .overlay(Circle().strokeBorder(PofuPrimitive.honey400.rgb.color, lineWidth: 1))
            .shadow(color: Color.shadowInk.opacity(0.25), radius: 1, y: 0.5)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// "Seviye n!": the build's one exclamation (§6.3), crisp in screen space
/// above the station.
struct BuildTag: View {
    let level: Int

    var body: some View {
        Text(WorldStrings.levelUp(level))
            .font(PofuFont.headline)
            .foregroundStyle(Color.paperInk)
            .padding(.horizontal, PofuSpacing.m + 4)
            .frame(minHeight: 36)
            // Celebration is painted, system UI is glass (look-dev C).
            .paintedPaper(cornerSeed: 5)
            .fixedSize()
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(Text(WorldStrings.levelUp(level)))
            .accessibilityAddTraits(.updatesFrequently)
    }
}
#endif
