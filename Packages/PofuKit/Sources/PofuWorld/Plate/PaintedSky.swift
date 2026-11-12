import Foundation
import PofuCore
import PofuDesignSystem

/// Home's painted sky at the wonder stops (D7 of docs/design/demo-one-world-v1.md): Koke's stop and the
/// harbor's draw the home plate's sky set (ADR-0025) of the hour's light, its island layer left out,
/// placed around the stop, instead of the code sky, the cloud sea and the height fog, so a Koke day
/// reads as the same painted world as Home. Pure: where the sky sits, how much of it shows at a camera,
/// and which light it has; `PaintedSkyLayer` draws it.
///
/// The sky is the home plate's stage 0 (the level-10 sky set: its day, golden and night all exist), so a
/// player at any level sees the one sky. Weather does not change it (D2): rain falls over it as code
/// streaks, overcast and mist draw nothing over a painting.
public enum PaintedSky {
    /// Where the home plate sits for each stop, as `HomePlate.Placement.island`: the plate's island box
    /// is `width` world units wide and its middle lands on `centre`, so the sky set's cloud sea lies
    /// behind and below the island of the stop, as it does behind Home's. The numbers are tuned so the
    /// sky set covers the screen at every phone size (`PaintedSkyTests`) and the whale and the distant
    /// isles clear the island's crown at rest.
    public static let stops: [IslandID: (centre: WorldPoint, width: Double)] = [
        .koke: (centre: WorldPoint(x: KokeLayout.center.x + 25, y: KokeLayout.center.y + 74), width: 290),
        .harbor: (centre: WorldPoint(x: harborCentre.x + 45, y: harborCentre.y + 106), width: 520),
    ]

    /// The harbor isle's centre on the world canvas (`IslandLayout.isles`).
    private static var harborCentre: WorldPoint {
        IslandLayout.isles.first { $0.id == .harbor }?.center ?? WorldPoint(x: 395, y: 14)
    }

    /// One painted sky showing: the stop's island, the plate state (always the home's stage 0, the
    /// hour's light) placed around the stop, and how much of it shows (0...1).
    public struct Sky: Hashable, Sendable {
        public var island: IslandID
        public var plate: HomePlate
        public var fade: Double
    }

    /// The minute of the day the scene shows: a look's override, else the world's clock, else noon.
    static func hour(world: WorldSnapshot, look: WorldLook, calendar: Calendar) -> Double {
        let minute = look.hourOverride.map { $0 * 60 } ?? world.clock.map { SkyModel.minuteOfDay($0, calendar: calendar) } ?? 12 * 60
        return minute / 60
    }

    /// The painted sky behind `island`'s stop, or `nil`: the island has no stop here, the look has no
    /// plates, or the plate has no sky set for the hour's light.
    public static func sky(
        for island: IslandID,
        world: WorldSnapshot,
        look: WorldLook,
        calendar: Calendar = .current
    ) -> HomePlate? {
        guard look.homePlates, let stop = stops[island], let home = HomePlate.shipped?.plate else { return nil }
        let light = HomePlate.light(hour: hour(world: world, look: look, calendar: calendar), isBedtime: world.isBedtime)
        let plate = HomePlate(plate: home, light: light, stage: 0, placement: .island(centre: stop.centre, width: stop.width))
        return plate.skySet == nil ? nil : plate
    }

    // MARK: - An island in the hour's light

    /// How much lighter, against its sky, an island stands at an hour than by day: the night and the golden
    /// hour lift it a little off the darker sky (ADR-0021: night is a hue change, not only a value drop;
    /// Home's own paintings stand 5 to 18 % lighter against their night sky than against their day sky; at
    /// night the cool lift in the shadows gives that), rain not at all. Kept within the ±10 % of the day's
    /// island-to-sky ratio that every stop must hold.
    static let ratioShift: [String: Double] = ["day": 1, "golden": 1.05, "night": 1, "rain": 1]
    /// The darkest the grade takes an island, as a share of its linear light: a painting never goes black.
    static let floorGain = 0.25
    /// The cool lift in the island's shadows at night: its soil and moss go lavender in the dark
    /// instead of staying warm, as Home's painted night does.
    static let nightLift = GradeRGB(0.02, 0.04, 0.14)
    static let nightSaturation = 0.9

    /// The one grade for an island drawn under a painted sky, so it sits in the hour (the Map and the
    /// flights, Koke's and the harbor's stops under Home's sky, Çağlayan's stop under its own): its light
    /// falls as its sky's falls (`skyDrop`, the sky's mean linear luminance at this hour over its day's)
    /// times `ratioShift`, less what its own art already fell (`artDrop`, 1 for a picture that has one
    /// light for every hour, as Koke's). The gain is linear light taken to gamma; at night it takes the
    /// cool hue of Home's night (`tint`, its luma kept) and a cool lift in the shadows. Never brighter
    /// than the art; neutral by day.
    public static func islandGrade(light: String, skyDrop: Double, artDrop: Double = 1, tint: PofuRGB? = nil) -> WorldGrade {
        let shift: Double = ratioShift[light] ?? 1.0
        let target: Double = skyDrop * shift / max(artDrop, 1e-6)
        let linear: Double = min(max(target, floorGain), 1.0)
        guard linear < 0.995 || light == "night" else { return .neutral }
        let g = pow(linear, 1 / 2.2)
        var hue = GradeRGB(1, 1, 1)
        if light == "night", let tint {
            let r: Double = 0.2126 * tint.red
            let gr: Double = 0.7152 * tint.green
            let b: Double = 0.0722 * tint.blue
            let luma: Double = r + gr + b
            if luma > 1e-6 {
                hue = GradeRGB(tint.red / luma, tint.green / luma, tint.blue / luma)
            }
        }
        let night = light == "night"
        return WorldGrade(
            lift: night ? nightLift : GradeRGB(0, 0, 0),
            gain: GradeRGB(g * hue.r, g * hue.g, g * hue.b),
            saturation: night ? nightSaturation : 1
        )
    }

    /// The grade of an island's sprites (Koke's, Çağlayan's sprite) under Home's sky set `plate`: Home's
    /// sky's fall at its light, the art's one light for every hour, Home's night hue.
    public static func islandGrade(_ plate: HomePlate) -> WorldGrade {
        islandGrade(light: plate.light, skyDrop: PaintedLight.shipped.skyDrop(island: "home", light: plate.light, stage: 0), tint: plate.harmony.tint)
    }

    /// The grade of Çağlayan's painted island `isle` under a sky: its own at its stop (`sky` nil), or Home's
    /// sky set on the Map and in a flight. Its own art's fall at its light is taken out.
    public static func islandGrade(painted isle: HomePlate, under sky: HomePlate?) -> WorldGrade {
        let light = PaintedLight.shipped
        let art = light.islandDrop(island: isle.plate.island, light: isle.light, stage: isle.stage)
        let skyLight = sky?.light ?? isle.light
        let drop = sky.map { light.skyDrop(island: "home", light: $0.light, stage: 0) }
            ?? light.skyDrop(island: isle.plate.island, light: isle.light, stage: isle.stage)
        return islandGrade(light: skyLight, skyDrop: drop, artDrop: art, tint: (sky ?? isle).harmony.tint)
    }

    /// The island's box the camera frames at its stop, and the stop's scale at the reference width.
    static func frame(of island: IslandID) -> (box: WorldBox, closeScale: Double)? {
        switch island {
        case .koke:
            return (KokeLayout.islandBox, KokeLayout.closeScale)
        case .harbor:
            guard
                let isle = IslandLayout.isles.first(where: { $0.id == .harbor }),
                let sprite = WorldArt.sprite(isle.art)?.sharp
            else { return nil }
            return (IslandFraming.placed(sprite, at: isle.center), IslandFraming.islandScale)
        default:
            return nil
        }
    }

    /// How much of the stop's sky shows at a camera: 0 on the Map, at Home and in a flight across the sea
    /// (the code sky is drawn there), 1 at the stop (`HomePlate.isleFade`).
    public static func fade(for island: IslandID, pose: CameraPose, viewportWidth: Double) -> Double {
        guard let frame = frame(of: island) else { return 0 }
        return HomePlate.isleFade(pose: pose, box: frame.box, closeScale: frame.closeScale, viewportWidth: viewportWidth)
    }

    /// The painted skies to draw at this camera: those of the stops it is on or near, in the world's hour.
    public static func skies(
        world: WorldSnapshot,
        look: WorldLook,
        pose: CameraPose,
        viewportWidth: Double,
        calendar: Calendar = .current
    ) -> [Sky] {
        guard look.homePlates else { return [] }
        return stops.keys.sorted { $0.rawValue < $1.rawValue }.compactMap { island in
            let fade = fade(for: island, pose: pose, viewportWidth: viewportWidth)
            guard fade > 0.001, let plate = sky(for: island, world: world, look: look, calendar: calendar) else { return nil }
            return Sky(island: island, plate: plate, fade: fade)
        }
    }

    // MARK: - The Map and the flights (R4 of docs/research/route-2026-11-12-codex-pause.md)

    /// How far the Map's sky follows the camera: a far backdrop, it slides a sixteenth as far as the world.
    static let mapParallax = 0.06
    /// The rows of Home's sky set (master px) the Map's screen shows at rest, top to foot: the sky set at
    /// about Home's own scale (its textures at their resolution, as crisp as at Home), the distant isles
    /// and the whale in the screen's top third, above Home, and the cloud sea under the islands down to
    /// the foot, above the painting's hazy last rows.
    static let mapTop = -255.0
    static let mapFoot = 3080.0
    /// The distant isles and the whale on the Map, as a share of their painted size: far behind Home,
    /// smaller than it, so they read as the sky's and not as places to go.
    static let mapIsleScale = 0.5
    /// The master row the isles' and the whale's lowest foot is raised to on the Map (the screen's top
    /// sixth): they keep their places among themselves and clear Home's island box, at every level.
    static let mapIsleFloor = 300.0
    /// The mid clouds' rows kept (master px, fading over `mapFade`): below them the tile carries the cut
    /// residue of Home's island, hidden at Home and drifting into view on the Map.
    static let mapMidBottom = 1100.0
    static let mapFade = 60.0
    /// The cloud sea's clean band (master px): above it the sea tile holds what Home's island hid (fill
    /// and cut residue, the hard cloud edges at night), below it the painting's hazy foot.
    static let mapSeaBand = (top: 2480.0, bottom: 3000.0)
    /// Where the painted sea starts to show on the Map (master px), fading in over `mapFade`.
    static let mapSeaTop = 2440.0
    /// The receding cloud sea above it: copies of the clean band, each smaller (`scale`) and slid along the
    /// tile (`slide`, a share of its width) so no two rows repeat, each overlapping the one below by
    /// `mapSeaOverlap` of its own rows; the farthest fades into the sky over `mapHorizonFade`.
    static let mapSeaStack: [(scale: Double, slide: Double)] = [
        (0.9, 0.37), (0.72, 0.71), (0.57, 0.13), (0.45, 0.55), (0.35, 0.29), (0.27, 0.83), (0.21, 0.47),
    ]
    static let mapSeaOverlap = 60.0
    static let mapHorizonFade = 450.0

    /// Home's painted sky behind the Map and every flight, in place of the code sky: the same sky set as
    /// the stops' (the home plate's stage 0 of the hour's light, its island layer left out), placed as at
    /// Home. `nil`: the look has no plates, or the plate has no sky set for the hour's light.
    public static func mapSky(world: WorldSnapshot, look: WorldLook, calendar: Calendar = .current) -> HomePlate? {
        guard look.homePlates, let home = HomePlate.shipped?.plate else { return nil }
        let light = HomePlate.light(hour: hour(world: world, look: look, calendar: calendar), isBedtime: world.isBedtime)
        let plate = HomePlate(plate: home, light: light, stage: 0)
        return plate.skySet == nil ? nil : plate
    }

    /// The sky set as the Map draws it (`mapPose` frames it), from the set's own layers and pixels: the
    /// island left out; the distant isles and the whale at `mapIsleScale` about their middles, their
    /// painted detail with them; the mid clouds above their residue; and the cloud sea as its painted
    /// rows from its clean band down, under a receding stack of that band (`mapSeaStack`) up to a soft
    /// horizon just under Home. Pure.
    public static func mapSet(_ set: SkySet) -> SkySet {
        var out = set
        out.layers = []
        var isles: [Int] = []
        for layer in set.layers {
            switch layer.role {
            case .island:
                continue
            case .sprite where layer.asset.contains("-isle-"), .whale:
                out.layers.append(scaled(layer, by: mapIsleScale))
                isles.append(out.layers.count - 1)
            case .tile where SkySet.isMidClouds(layer):
                var mid = layer
                mid.window = window(layer, from: nil, to: mapMidBottom, topFade: 0, bottomFade: mapFade)
                out.layers.append(mid)
            case .tile where layer.asset.contains("-sky-sea-"):
                out.layers += seaStack(layer)
            default:
                out.layers.append(layer)
            }
        }
        let foot = isles.map { out.layers[$0].pos.y + out.layers[$0].size.y }.max() ?? mapIsleFloor
        let lift = min(mapIsleFloor - foot, 0)
        for i in isles {
            out.layers[i] = moved(out.layers[i], by: lift)
        }
        return out
    }

    /// A sprite (and its detail) `dy` master rows lower.
    private static func moved(_ layer: SkySet.Layer, by dy: Double) -> SkySet.Layer {
        var out = layer
        out.pos.y += dy
        out.details = layer.details.map { d in
            var d = d
            d.pos.y += dy
            d.mist = d.mist.map { m in
                var m = m
                m.centre.y += dy
                return m
            }
            return d
        }
        return out
    }

    /// A layer's band from master row `top` to `bottom` (nil: its own edge), fades in master rows.
    private static func window(_ layer: SkySet.Layer, from top: Double?, to bottom: Double?, topFade: Double, bottomFade: Double) -> SkySet.Window {
        let h = max(layer.size.y, 1e-6)
        return SkySet.Window(
            top: top.map { ($0 - layer.pos.y) / h } ?? 0,
            bottom: bottom.map { ($0 - layer.pos.y) / h } ?? 1,
            topFade: topFade / h,
            bottomFade: bottomFade / h
        )
    }

    /// A sprite (and its detail) at `f` of its size about its middle.
    private static func scaled(_ layer: SkySet.Layer, by f: Double) -> SkySet.Layer {
        let c = PlatePoint(x: layer.pos.x + layer.size.x / 2, y: layer.pos.y + layer.size.y / 2)
        func p(_ q: PlatePoint) -> PlatePoint { PlatePoint(x: c.x + (q.x - c.x) * f, y: c.y + (q.y - c.y) * f) }
        func s(_ q: PlatePoint) -> PlatePoint { PlatePoint(x: q.x * f, y: q.y * f) }
        var out = layer
        out.pos = p(layer.pos)
        out.size = s(layer.size)
        out.details = layer.details.map { d in
            var d = d
            d.pos = p(d.pos)
            d.size = s(d.size)
            d.flowHeight *= f
            d.mist = d.mist.map { m in
                var m = m
                m.centre = p(m.centre)
                m.radius = s(m.radius)
                return m
            }
            return d
        }
        return out
    }

    /// The cloud sea: its painted rows from `mapSeaTop` down, and above them the stack of its clean band,
    /// farthest first (drawn first, so a nearer row lies over a farther one's foot).
    private static func seaStack(_ sea: SkySet.Layer) -> [SkySet.Layer] {
        var near = sea
        near.window = window(sea, from: mapSeaTop, to: nil, topFade: mapFade, bottomFade: 0)
        var rows = [near]
        var bottom = mapSeaTop + mapFade + mapSeaOverlap
        let band = mapSeaBand
        for (n, step) in mapSeaStack.enumerated() {
            let f = step.scale
            var copy = sea
            copy.id = "\(sea.id)-map\(n)"
            // Band row `r` of the painting lands at `pos.y + (r - sea.pos.y) * f`; its foot overlaps the row below.
            let y = bottom - (band.bottom - sea.pos.y) * f
            copy.pos = PlatePoint(x: sea.pos.x - step.slide * sea.size.x * f, y: y)
            copy.size = PlatePoint(x: sea.size.x * f, y: sea.size.y * f)
            copy.tileWidth = sea.tileWidth.map { $0 * f }
            copy.drift = sea.drift * f
            copy.bob = nil
            let last = n == mapSeaStack.count - 1
            copy.window = SkySet.Window(
                top: (band.top - sea.pos.y) / sea.size.y,
                bottom: (band.bottom - sea.pos.y) / sea.size.y,
                topFade: (last ? mapHorizonFade : mapFade) / sea.size.y,
                bottomFade: mapFade / sea.size.y
            )
            rows.insert(copy, at: 0)
            bottom = y + (band.top - sea.pos.y) * f + (mapFade + mapSeaOverlap) * f
        }
        return rows
    }

    /// The camera the Map's sky is drawn with, for the world camera `pose` on a `width` x `height`
    /// screen: rows `mapTop` to `mapFoot` of the sky set fill the screen's height when the camera is on
    /// the Map, centred across; its look point follows the world camera's by `mapParallax`, so the sky
    /// slides slowly under a flight and never zooms.
    public static func mapPose(_ pose: CameraPose, sky: HomePlate, width: Double, height: Double) -> CameraPose {
        guard let set = sky.skySet else { return pose }
        let band = sky.worldBox(master: PlateRect(minX: 0, minY: mapTop, maxX: set.master.x, maxY: mapFoot), of: set)
        let map = CameraRail(width: width, height: height, stops: sky.stops, whole: sky.wholeStop).pose(of: .map)
        return CameraPose(
            logScale: log(height / max(band.height, 1e-6)),
            lookX: band.midX + (pose.lookX - map.lookX) * mapParallax,
            lookY: band.minY + (pose.lookY - map.lookY) * mapParallax,
            anchorY: 0
        )
    }
}

/// How light each painted sky and island is (`tools/plate/painted_light.py`, `Plates/painted-light.json`):
/// mean linear luminances per state, the data of `PaintedSky.islandGrade`.
public struct PaintedLight: Sendable {
    public struct State: Decodable, Sendable {
        public var sky: Double?
        public var island: Double
        public var rgb: [Double]
    }

    public var states: [String: [String: State]]

    public static let shipped: PaintedLight = {
        guard
            let url = Bundle.module.url(forResource: "painted-light", withExtension: "json")
                ?? Bundle.module.url(forResource: "painted-light", withExtension: "json", subdirectory: "Plates"),
            let data = try? Data(contentsOf: url),
            let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return PaintedLight(states: [:]) }
        var states: [String: [String: State]] = [:]
        for (island, value) in raw {
            guard let entries = value as? [String: Any], let json = try? JSONSerialization.data(withJSONObject: entries),
                  let decoded = try? JSONDecoder().decode([String: State].self, from: json) else { continue }
            states[island] = decoded
        }
        return PaintedLight(states: states)
    }()

    /// A state's measure; a light without its own stage falls back to its stage 0, then to day.
    public func state(island: String, light: String, stage: Int) -> State? {
        let s = states[island]
        return s?["\(light)-\(stage)"] ?? s?["\(light)-0"]
    }

    /// The sky's mean light at this state over its day's (1: no measure).
    public func skyDrop(island: String, light: String, stage: Int) -> Double {
        guard let a = state(island: island, light: light, stage: stage)?.sky,
              let d = state(island: island, light: "day", stage: stage)?.sky, d > 0 else { return 1 }
        return a / d
    }

    /// The island art's mean light at this state over its day's (1: no measure).
    public func islandDrop(island: String, light: String, stage: Int) -> Double {
        guard let a = state(island: island, light: light, stage: stage)?.island,
              let d = state(island: island, light: "day", stage: stage)?.island, d > 0 else { return 1 }
        return a / d
    }
}

#if os(iOS)
import SwiftUI

/// A painted sky at the camera's projection: the home plate's sky set of the hour's light without its
/// island layer, never graded. An hour change is a crossfade between two whole skies
/// (`PlateHomeLayer.crossfade`), the same as at Home; `fade` brings it in as the camera lands on the
/// stop and out as it leaves.
struct PaintedSkyLayer: View {
    let plate: HomePlate
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    let fade: Double
    /// The Map's and the flights' sky (`PaintedSky.mapPose`), drawn as `PaintedSky.mapSet`.
    var isMap = false

    @State private var shown: HomePlate
    @State private var incoming: HomePlate?
    @State private var incomingOpacity = 0.0
    @State private var shownStart = Date()
    @State private var incomingStart = Date()

    init(plate: HomePlate, pose: CameraPose, size: CGSize, offset: CGSize, fade: Double, isMap: Bool = false) {
        self.plate = plate
        self.pose = pose
        self.size = size
        self.offset = offset
        self.fade = fade
        self.isMap = isMap
        _shown = State(initialValue: plate)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            sky(shown, start: shownStart)
            if let incoming {
                sky(incoming, start: incomingStart).compositingGroup().opacity(incomingOpacity)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(fade)
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
            withAnimation(.easeInOut(duration: PlateHomeLayer.crossfade)) {
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

    @ViewBuilder
    private func sky(_ plate: HomePlate, start: Date) -> some View {
        if let set = plate.skySet {
            SkySetLayers(sky: isMap ? PaintedSky.mapSet(set) : set, plate: plate, pose: pose, size: size, offset: offset, start: start, drawsIsland: false)
        }
    }
}
#endif
