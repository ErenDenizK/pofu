#if os(iOS)
import PofuDesignSystem
import SwiftUI

/// The painted home plate (ADR-0022) at the camera's projection, back to
/// front: the plate's own sky and cloud sea extended (the backdrop), the
/// whole plate over it (its border feathered into the backdrop), and,
/// toward the Map where the backdrop fades, the island cut from its sky.
/// Nothing grades, fogs or hazes it: the plate is the final picture. It is
/// static, so a settled Home costs no frames.
struct PlateHomeLayer: View {
    let plate: HomePlate
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    /// 1 at the Island stop and closer, 0 toward the Map.
    let fade: Double

    /// The backdrop and the whole plate fade in from z 0.55 to 0.95: the
    /// Island stop and Home show the painting edge to edge, the Map the
    /// island among the others.
    static func fade(z: Double) -> Double {
        let t = min(max((z - 0.55) / 0.4, 0), 1)
        return t * t * (3 - 2 * t)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if fade < 0.999 {
                PlateImage(name: plate.plate.islandArt(light: plate.light, stage: plate.stage), box: plate.islandBox, pose: pose, size: size, offset: offset)
            }
            if fade > 0.001 {
                ZStack(alignment: .topLeading) {
                    PlateImage(name: plate.plate.backdropArt(light: plate.light, stage: plate.stage), box: plate.backdropBox, pose: pose, size: size, offset: offset)
                    PlateImage(name: plate.plate.plateArt(light: plate.light, stage: plate.stage), box: plate.plateBox, pose: pose, size: size, offset: offset)
                }
                .opacity(fade)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// One plate image over its box in world units, at the camera's projection
/// (the same transform as the world canvas, so plate, occluders and
/// characters register).
struct PlateImage: View {
    let name: String
    let box: WorldBox
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    var body: some View {
        let s = pose.scale
        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: Double(size.width))
        let w = box.width * s, h = box.height * s
        Image(name, bundle: .module)
            .resizable()
            .interpolation(.high)
            .frame(width: CGFloat(w), height: CGFloat(h))
            .position(x: CGFloat(a.x + w / 2) + offset.width, y: CGFloat(a.y + h / 2) + offset.height)
    }
}

/// Painted objects drawn again over a character standing behind them.
struct PlateOccluders: View {
    let plate: HomePlate
    let objects: [PlateIsland.Object]
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(objects) { object in
                PlateImage(
                    name: plate.plate.occluderArt(id: object.id, light: plate.light, stage: plate.stage),
                    box: plate.occluderBox(object),
                    pose: pose,
                    size: size,
                    offset: offset
                )
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A character standing on the plate: its sprite at the plate's scale, in
/// the plate's light (`HomePlate.gain`), on a contact pad of the grass's
/// own shadow tone. Drawn in the world canvas (world units).
struct PlateCharacter: View {
    let art: String
    let point: CGPoint
    let scale: Double
    /// World units off the ground (a hop), already scaled.
    var lift: Double = 0
    let gain: Double
    let contact: PofuRGB
    var pulse = 0

    var body: some View {
        let anchor = UnitPoint(x: point.x / IslandLayout.canvasWidth, y: point.y / IslandLayout.canvasHeight)
        ZStack(alignment: .topLeading) {
            if let sprite = WorldArt.sprite(art), let box = sprite.sharp {
                ContactPad(width: box.width * scale, tone: contact, strength: 1 - min(lift / max(box.height * scale, 1), 0.5))
                    .position(x: point.x, y: point.y - CGFloat(0.5 * scale))
                DepthImage(name: art, sprite: sprite, level: 0, anchor: CGPoint(x: point.x, y: point.y - CGFloat(lift)), scale: CGFloat(scale))
                    .colorMultiply(Color(white: gain))
            }
        }
        .modifier(TapSquish(trigger: pulse, anchor: anchor))
    }
}

/// The contact pad under a character on the plate (ADR-0022): an ellipse
/// 0.92 × 0.2 of its width in the grass's own shadow tone, multiplied, so
/// it darkens the painted lawn toward its painted shadow, never grey.
struct ContactPad: View {
    let width: Double
    let tone: PofuRGB
    var strength = 1.0

    var body: some View {
        let colour = Color(red: tone.red, green: tone.green, blue: tone.blue)
        ZStack {
            Ellipse()
                .fill(EllipticalGradient(colors: [colour, colour.opacity(0)]))
                .frame(width: CGFloat(width * 1.15), height: CGFloat(width * 0.28))
                .opacity(0.55 * strength)
            Ellipse()
                .fill(colour)
                .frame(width: CGFloat(width * 0.62), height: CGFloat(width * 0.13))
                .blur(radius: CGFloat(max(width * 0.035, 0.5)))
                .opacity(0.75 * strength)
        }
        .blendMode(.multiply)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
