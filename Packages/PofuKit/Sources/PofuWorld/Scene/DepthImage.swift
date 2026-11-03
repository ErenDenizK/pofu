#if os(iOS)
import SwiftUI

/// One world image drawn at a continuous blur level by cross-fading its
/// baked sharp, soft and deep variants (interaction spec §5.4, §12.1).
/// Invisible layers leave the render tree, so a sharp object at rest is
/// one image and costs nothing extra.
///
/// Every layer is positioned in the parent's coordinate space: `anchor`
/// is where the sprite's anchor lands, `scale` converts world units to the
/// parent's points (1 inside the camera's world canvas).
struct DepthImage: View {
    let name: String
    let sprite: WorldSprite
    let level: Double
    let anchor: CGPoint
    var scale: CGFloat = 1
    var opacity: Double = 1
    /// Leave out the sharp layer (something else draws it).
    var skipsSharp = false
    /// A grade of this image's own (a character's light), applied to each
    /// layer's rect only, so it costs the sprite's pixels, not the screen's.
    var grade: WorldGrade = .neutral

    @Environment(\.worldLook.art) private var art

    var body: some View {
        let weights = DepthWeights(level: level)
        // The look's art set: the soft-lock bake where one exists.
        let key = WorldArt.key(name, art: art)
        let sprite = WorldArt.sprite(key) ?? self.sprite
        ZStack {
            layer(.deep, weight: weights.deep, key: key, sprite: sprite)
            layer(.soft, weight: weights.soft, key: key, sprite: sprite)
            if !skipsSharp {
                layer(.sharp, weight: weights.sharp, key: key, sprite: sprite)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func layer(_ variant: DepthVariant, weight: Double, key: String, sprite: WorldSprite) -> some View {
        if weight * opacity > DepthWeights.visibleThreshold, let box = sprite.box(for: variant) {
            Image(WorldArt.assetName(key, variant: variant), bundle: .module)
                .resizable()
                .frame(width: CGFloat(box.width) * scale, height: CGFloat(box.height) * scale)
                .modifier(GradeEffect(grade: grade, isEnabled: !grade.isNeutral))
                .opacity(weight * opacity)
                .position(
                    x: anchor.x + CGFloat(box.midX) * scale,
                    y: anchor.y + CGFloat(box.midY) * scale
                )
        }
    }
}

/// A soft contact shadow where an object meets the ground (§12.3 d): a
/// wide falloff and a darker, tighter core.
struct ContactShadow: View {
    let width: CGFloat
    let height: CGFloat
    var strength: Double = 1

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.shadowInk.opacity(0.20 * strength), Color.shadowInk.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: width / 2
                    )
                )
                .frame(width: width, height: height)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.shadowInk.opacity(0.16 * strength), Color.shadowInk.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: width * 0.27
                    )
                )
                .frame(width: width * 0.54, height: height * 0.44)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension Color {
    /// A warm mid-brown: the art bible's darkest shadow is never near black.
    static let shadowInk = Color(red: 0.36, green: 0.27, blue: 0.20)
}
#endif
