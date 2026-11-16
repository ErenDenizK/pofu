#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit

/// The painted home plate (ADR-0022) at the camera's projection, back to
/// front: the plate's own sky and cloud sea extended (the backdrop), the
/// whole plate over it (its border feathered into the backdrop), and,
/// toward the Map where the backdrop fades, the island cut from its sky.
/// Nothing grades, fogs or hazes it: the plate is the final picture. Where a
/// state has a sky set (ADR-0025: every matted Home state, one sky per light
/// at every level, and every painted Çağlayan state) the sky, the far and mid
/// clouds, the distant isles and the cloud sea are its layers (`SkySetLayers`:
/// they drift, bob and glide, the island never moves) and no backdrop is
/// drawn: a matted Home plate stands on them, cropped to its island. The
/// states that keep their old matte are static, so they cost no frames.
struct PlateHomeLayer: View {
    let plate: HomePlate
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    /// 1 at the Island stop and closer, 0 toward the Map.
    let fade: Double
    /// The island's grade in the hour (`PaintedSky.islandGrade(painted:under:)`): the island cut takes it
    /// toward the Map, and over the whole painting the cut is drawn again in it, so the island darkens with
    /// its sky and the sky keeps its own pixels. Neutral for Home, whose painting is the reference.
    var islandGrade: WorldGrade = .neutral
    /// The Home stations' levels: the looks drawn over a base (`StationLooksLayer`). Not part of the painting's identity,
    /// so a station's upgrade is its own swap and never a crossfade of the whole painting.
    var stationLevels: [StationID: Int] = [:]

    /// A stage, a level or an hour change is a crossfade between two whole
    /// paintings (the plain form of the spec's diff-mask reveal: every pixel
    /// still comes from a painting).
    static let crossfade = IslandGrowMoment.crossFadeLength

    /// The painting on screen, and the one fading in over it.
    @State private var shown: HomePlate
    @State private var incoming: HomePlate?
    @State private var incomingOpacity = 0.0
    /// When each painting appeared: the sky set's time zero (`SkySetLayers`).
    @State private var shownStart = Date()
    @State private var incomingStart = Date()

    init(plate: HomePlate, pose: CameraPose, size: CGSize, offset: CGSize, fade: Double, islandGrade: WorldGrade = .neutral, stationLevels: [StationID: Int] = [:]) {
        self.plate = plate
        self.pose = pose
        self.size = size
        self.offset = offset
        self.fade = fade
        self.islandGrade = islandGrade
        self.stationLevels = stationLevels
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
                    .islandGraded(islandGrade)
            }
            if fade > 0.001 {
                ZStack(alignment: .topLeading) {
                    if let sky = plate.skySet {
                        // A matted plate stands on the sky set in place of the set's own island layer.
                        SkySetLayers(sky: sky, plate: plate, pose: pose, reference: plate.skyReference(width: Double(size.width), height: Double(size.height)), size: size, offset: offset, start: start, drawsIsland: !plate.isMatted)
                        if plate.isMatted {
                            PlateImage(name: plate.plate.drawnPlateArt(light: plate.light, stage: plate.stage), box: plate.plateImageBox, pose: pose, size: size, offset: offset)
                        }
                    } else {
                        PlateImage(name: plate.plate.backdropArt(light: plate.light, stage: plate.stage), box: plate.backdropBox, pose: pose, size: size, offset: offset)
                        PlateImage(name: plate.plate.drawnPlateArt(light: plate.light, stage: plate.stage), box: plate.plateImageBox, pose: pose, size: size, offset: offset)
                    }
                    if !islandGrade.isNeutral {
                        PlateImage(name: plate.plate.islandArt(light: plate.light, stage: plate.stage), box: plate.islandBox, pose: pose, size: size, offset: offset)
                            .islandGraded(islandGrade)
                    }
                }
                .fading(fade)
            }
            // The stations' looks stand over the base at every distance: the Map's island cut is erased too.
            StationLooksLayer(plate: plate, levels: stationLevels, pose: pose, size: size, offset: offset)
        }
    }
}

/// The looks of the stations a state has an erased base for, one per station at its level (level to look 1 to 1,
/// nothing while unbuilt), on the plate's own transform. A level change swaps the look with a short crossfade and a
/// pop on the station's foot; with Reduce Motion it swaps at once.
struct StationLooksLayer: View {
    let plate: HomePlate
    let levels: [StationID: Int]
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    var body: some View {
        let ids = plate.plate.stationLooks(light: plate.light, stage: plate.stage).keys.sorted()
        ZStack(alignment: .topLeading) {
            ForEach(ids, id: \.self) { id in
                if let frame = plate.lookFrame(id) {
                    StationLookView(
                        art: plate.plate.lookArt(station: id, level: levels[StationID(rawValue: id)] ?? 0, light: plate.light, stage: plate.stage),
                        box: frame.box, foot: frame.foot, pose: pose, size: size, offset: offset
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// One station's look, swapping as its asset changes.
struct StationLookView: View {
    let art: String?
    let box: WorldBox
    let foot: WorldPoint
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = 1.0

    var body: some View {
        let anchor = pose.project(foot, width: Double(size.width))
        ZStack(alignment: .topLeading) {
            if let art {
                PlateImage(name: art, box: box, pose: pose, size: size, offset: offset)
                    .id(art)
                    .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: art)
        .scaleEffect(pop, anchor: UnitPoint(x: (anchor.x + offset.width) / max(size.width, 1), y: (anchor.y + offset.height) / max(size.height, 1)))
        .onChange(of: art) { old, new in
            guard !reduceMotion, old != nil, new != nil else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) {
                pop = 1.05
            } completion: {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.6)) {
                    pop = 1
                }
            }
        }
    }
}

extension View {
    /// An island picture in its grade under a painted sky (`PaintedSky.islandGrade`): the grade shader, or
    /// without it the gain as a multiply.
    @ViewBuilder
    func islandGraded(_ grade: WorldGrade) -> some View {
        if grade.isNeutral {
            self
        } else if WorldShaders.isAvailable {
            modifier(GradeEffect(grade: grade, isEnabled: true))
        } else {
            colorMultiply(Color(red: min(grade.gain.r, 1), green: min(grade.gain.g, 1), blue: min(grade.gain.b, 1)))
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
    /// The Home stations' levels: a station standing over a base is drawn again as its look (nothing while unbuilt),
    /// not as the painted stall the base no longer has.
    var stationLevels: [StationID: Int] = [:]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(objects) { object in
                if let station = object.station?.rawValue, plate.plate.stationLooks(light: plate.light, stage: plate.stage)[station] != nil {
                    if let art = plate.plate.lookArt(station: station, level: object.station.flatMap { stationLevels[$0] } ?? 0, light: plate.light, stage: plate.stage),
                       let frame = plate.lookFrame(station) {
                        PlateImage(name: art, box: frame.box, pose: pose, size: size, offset: offset)
                    }
                } else {
                    PlateImage(
                        name: plate.plate.occluderArt(id: object.id, light: plate.light, stage: plate.stage),
                        box: plate.occluderBox(object),
                        pose: pose,
                        size: size,
                        offset: offset
                    )
                }
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
