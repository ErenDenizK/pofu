#if os(iOS)
import PofuDesignSystem
import SwiftUI
import UIKit

/// The painted home plate (ADR-0022) at the camera's projection, back to
/// front: the plate's own sky and cloud sea extended (the backdrop), the
/// whole plate over it (its border feathered into the backdrop), and,
/// toward the Map where the backdrop fades, the island cut from its sky.
/// Nothing grades, fogs or hazes it: the plate is the final picture. Where a
/// state has a sky set (ADR-0025: home's level-10 day, golden hour and night)
/// the sky, the far and mid clouds, the distant isles and the cloud sea are
/// its layers (`SkySetLayers`: they drift, bob and glide, the island never
/// moves) and the plate and backdrop are not drawn; every other state is
/// static, so a settled Home costs no frames.
struct PlateHomeLayer: View {
    let plate: HomePlate
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    /// 1 at the Island stop and closer, 0 toward the Map.
    let fade: Double

    /// A stage, a level or an hour change is a crossfade between two whole
    /// paintings (the plain form of the spec's diff-mask reveal: every pixel
    /// still comes from a painting).
    static let crossfade = 1.4

    /// The painting on screen, and the one fading in over it.
    @State private var shown: HomePlate
    @State private var incoming: HomePlate?
    @State private var incomingOpacity = 0.0
    /// When each painting appeared: the sky set's time zero (`SkySetLayers`).
    @State private var shownStart = Date()
    @State private var incomingStart = Date()

    init(plate: HomePlate, pose: CameraPose, size: CGSize, offset: CGSize, fade: Double) {
        self.plate = plate
        self.pose = pose
        self.size = size
        self.offset = offset
        self.fade = fade
        _shown = State(initialValue: plate)
    }

    /// The backdrop and the whole plate fade in from z 0.55 to 0.95: the
    /// Island stop and Home show the painting edge to edge, the Map the
    /// island among the others.
    static func opacity(z: Double) -> Double {
        let t = min(max((z - 0.55) / 0.4, 0), 1)
        return t * t * (3 - 2 * t)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            painting(shown, start: shownStart)
            if let incoming {
                // A crossfade is two whole paintings: the incoming one's layers fade as a group.
                painting(incoming, start: incomingStart).compositingGroup().opacity(incomingOpacity)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: plate) { _, new in
            if let incoming {
                shown = incoming
                shownStart = incomingStart
            }
            guard new != shown else {
                incoming = nil
                return
            }
            incoming = new
            incomingStart = Date()
            incomingOpacity = 0
            withAnimation(.easeInOut(duration: Self.crossfade)) {
                incomingOpacity = 1
            } completion: {
                if incoming == new {
                    shown = new
                    shownStart = incomingStart
                    incoming = nil
                }
            }
        }
    }

    private func painting(_ plate: HomePlate, start: Date) -> some View {
        ZStack(alignment: .topLeading) {
            if fade < 0.999 {
                PlateImage(name: plate.plate.mapIslandArt(light: plate.light, stage: plate.stage), box: plate.islandBox, pose: pose, size: size, offset: offset)
            }
            if fade > 0.001 {
                ZStack(alignment: .topLeading) {
                    if let sky = plate.skySet {
                        SkySetLayers(sky: sky, plate: plate, pose: pose, size: size, offset: offset, start: start)
                    } else {
                        PlateImage(name: plate.plate.backdropArt(light: plate.light, stage: plate.stage), box: plate.backdropBox, pose: pose, size: size, offset: offset)
                        PlateImage(name: plate.plate.plateArt(light: plate.light, stage: plate.stage), box: plate.plateBox, pose: pose, size: size, offset: offset)
                    }
                }
                .fading(fade)
            }
        }
    }
}

private extension View {
    /// Opacity applied to the layers as one picture (a group), only while it is below 1: a settled
    /// sky set is never flattened into an offscreen pass.
    @ViewBuilder
    func fading(_ opacity: Double) -> some View {
        if opacity < 0.999 {
            compositingGroup().opacity(opacity)
        } else {
            self
        }
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
        Image(name, bundle: .module).resizable().interpolation(.high)
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
/// the plate's light (`HomePlate.characterLight`): the state's ambient
/// multiply, the key light's rim, the lawn's bounce and, at night, a lamp's
/// pool under it, on a two-layer contact shadow in the grass's own shadow
/// hue. Drawn in the world canvas (world units).
struct PlateCharacter: View {
    let art: String
    let point: CGPoint
    let scale: Double
    /// World units off the ground (a hop), already scaled.
    var lift: Double = 0
    let light: HomePlate.CharacterLight
    /// Whether it stands on the lawn: a contact shadow and, at night, a lamp's pool under it.
    /// A painted fountain carries its own ripple and sets this to `false`.
    var onLawn = true
    var pulse = 0

    @Environment(\.worldLook.art) private var lookArt

    var body: some View {
        let anchor = UnitPoint(x: point.x / IslandLayout.canvasWidth, y: point.y / IslandLayout.canvasHeight)
        ZStack(alignment: .topLeading) {
            if let sprite = WorldArt.sprite(art), let box = sprite.sharp {
                let width = box.width * scale
                if onLawn {
                    LampPool(width: width, light: light)
                        .position(x: point.x, y: point.y - CGFloat(0.5 * scale))
                    ContactPad(width: width, light: light, strength: 1 - min(lift / max(box.height * scale, 1), 0.5))
                        .position(x: point.x, y: point.y - CGFloat(0.5 * scale))
                }
                let grounded = CGPoint(x: point.x, y: point.y - CGFloat(lift))
                DepthImage(name: art, sprite: sprite, level: 0, anchor: grounded, scale: CGFloat(scale))
                    .saturation(light.saturation)
                    .colorMultiply(Color(red: light.paint.red, green: light.paint.green, blue: light.paint.blue))
                CharacterLightLayers(
                    image: Image(WorldArt.assetName(WorldArt.key(art, art: lookArt), variant: .sharp), bundle: .module),
                    size: CGSize(width: box.width * scale, height: box.height * scale),
                    light: light
                )
                .position(x: grounded.x + CGFloat(box.midX * scale), y: grounded.y + CGFloat(box.midY * scale))
            }
        }
        .modifier(TapSquish(trigger: pulse, anchor: anchor))
    }
}

/// The key light's rim and the lawn's bounce over a sprite, as two flat
/// silhouettes of its own alpha: the key colour over a gradient across the
/// sprite from the lit side (full at the edge, `fill` on the far side), and
/// the lawn's colour over its lower third. Drawn over the ambient multiply,
/// in normal blending, so they mix toward a colour and never go past it.
struct CharacterLightLayers: View {
    let image: Image
    let size: CGSize
    let light: HomePlate.CharacterLight

    var body: some View {
        let u = light.toward
        let lit = UnitPoint(x: 0.5 + 0.5 * u.x, y: 0.5 + 0.5 * u.y)
        let shaded = UnitPoint(x: 0.5 - 0.5 * u.x, y: 0.5 - 0.5 * u.y)
        ZStack {
            if light.rim > 0 {
                silhouette(Color(red: light.key.red, green: light.key.green, blue: light.key.blue))
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black.opacity(0.5), location: 0.4),
                                .init(color: .black.opacity(light.fill), location: 0.8),
                                .init(color: .black.opacity(light.fill), location: 1),
                            ],
                            startPoint: lit,
                            endPoint: shaded
                        )
                    }
                    .opacity(min(light.rim, 1))
            }
            if light.bounceAmount > 0 {
                silhouette(Color(red: light.bounce.red, green: light.bounce.green, blue: light.bounce.blue))
                    .mask {
                        LinearGradient(
                            stops: [.init(color: .clear, location: 0.62), .init(color: .black, location: 1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .opacity(min(light.bounceAmount, 1))
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func silhouette(_ colour: Color) -> some View {
        image.resizable().renderingMode(.template).foregroundStyle(colour)
            .frame(width: size.width, height: size.height)
    }
}

/// A lamp's warm pool on the lawn under a character standing near it (night):
/// the key colour screened over the grass in an ellipse on the ground plane,
/// fading to nothing, so the painted lawn is never edited past the character.
struct LampPool: View {
    let width: Double
    let light: HomePlate.CharacterLight

    var body: some View {
        if light.pool > 0.005 {
            let key = Color(red: light.key.red, green: light.key.green, blue: light.key.blue)
            Ellipse()
                .fill(EllipticalGradient(colors: [key.opacity(min(light.pool, 1)), key.opacity(0)]))
                .frame(width: CGFloat(width * 1.9), height: CGFloat(width * 0.68))
                .blendMode(.screen)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// The contact shadow under a character on the plate (ADR-0022), in two
/// layers, each multiplied so it darkens the painted lawn toward its own
/// painted shadow, in its hue, never grey: a soft pad (1.15 x 0.28 of the
/// width) and, right under the body, a tight dark occlusion core (0.6 x 0.11,
/// the lawn's shadow at `HomePlate.coreDepth`). `light.contact` is the
/// state's strength (the harmony rule).
struct ContactPad: View {
    let width: Double
    let light: HomePlate.CharacterLight
    var strength = 1.0

    var body: some View {
        let pad = Color(red: light.pad.red, green: light.pad.green, blue: light.pad.blue)
        let core = Color(red: light.core.red, green: light.core.green, blue: light.core.blue)
        ZStack {
            Ellipse()
                .fill(EllipticalGradient(colors: [pad, pad.opacity(0)]))
                .frame(width: CGFloat(width * 1.15), height: CGFloat(width * 0.28))
                .opacity(min(0.55 * strength * light.contact, 1))
                .blendMode(.multiply)
            Ellipse()
                .fill(core)
                .frame(width: CGFloat(width * 0.6), height: CGFloat(width * 0.11))
                .blur(radius: CGFloat(max(width * 0.02, 0.5)))
                .opacity(min(0.9 * strength * light.contact, 1))
                .offset(y: CGFloat(-width * 0.045))
                .blendMode(.multiply)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
