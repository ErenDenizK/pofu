import Foundation
import PofuCore
import PofuDesignSystem

/// An island drawn from its painted plate (ADR-0022, the home first, then Çağlayan): one
/// painted state of it (`light`, `stage`) and everything the runtime derives from the plate's
/// data: where the plate sits in the world, where the characters stand on it and
/// how large they are, its tap polygons and occluders, its light, and the
/// camera's stops while it shows.
///
/// The plate is placed so that Pofu's painted spot lands on Pofu's world
/// feet (`IslandLayout.pofu`): everything that follows Pofu (his tap, the
/// bubble, the collect moment) works unchanged. Its scale makes the island
/// `framing.homeWidths` screen widths wide at Home's scale.
///
/// Home shows in clear weather: by day at island levels 2...10 (one painted
/// plate per level), at golden hour and by night at level 10. Çağlayan
/// (`CaglayanPlate.swift`) shows the states its data paints, by story stage. Every
/// other hour, level, stage and weather keeps the sprite island until its painted states
/// exist (ADR-0022 L1).
public struct HomePlate: Hashable, Sendable {
    /// Where the plate sits in the world.
    public enum Placement: Hashable, Sendable {
        /// Pofu's painted spot on Pofu's world feet, the island `framing.homeWidths` screen widths
        /// wide at Home's scale.
        case home
        /// The plate's island box centred on `centre`, `width` world units wide (an island with
        /// its own place on the map).
        case island(centre: WorldPoint, width: Double)
    }

    public let placement: Placement
    public let plate: PlateIsland
    public let light: String
    public let stage: Int
    /// World units per plate pixel.
    public let unitsPerPixel: Double
    /// The plate pixel at the world's origin.
    public let origin: PlatePoint
    /// The open lawn's light: a character standing there keeps its paint.
    public let referenceLight: PofuRGB
    /// The character harmony rule's data for this state: the multiply tint
    /// that puts a sprite in the plate's light and the contact shadow's
    /// strength (`tools/plate/ingest.py`, docs/design/visual-system.md).
    public let harmony: PlateIsland.Harmony

    /// Pofu's art is 64 units wide (`PofuLayer.artWidth`).
    public static let pofuArtWidth = 64.0

    public init(plate: PlateIsland, light: String = "day", stage: Int = 0, placement: Placement = .home) {
        self.plate = plate
        self.light = light
        self.stage = stage
        self.placement = placement
        let islandPixels = max(plate.islandBox.width, 1)
        let box = plate.islandBox
        let middle = PlatePoint(x: (box.minX + box.maxX) / 2, y: (box.minY + box.maxY) / 2)
        switch placement {
        case .home:
            let u = plate.framing.homeWidths * CameraRail.referenceWidth / IslandFraming.homeScale / islandPixels
            unitsPerPixel = u
            let pofu = plate.characters["pofu"] ?? middle
            origin = PlatePoint(x: pofu.x - IslandLayout.pofu.x / u, y: pofu.y - IslandLayout.pofu.y / u)
        case .island(let centre, let width):
            let u = width / islandPixels
            unitsPerPixel = u
            origin = PlatePoint(x: middle.x - centre.x / u, y: middle.y - centre.y / u)
        }
        referenceLight = Self.reference(plate: plate, light: light, stage: stage)
        harmony = plate.harmony(light: light, stage: stage)
    }

    /// The home plate shipped in the package, if any.
    public static let shipped: HomePlate? = PlateIsland.load("home").map { HomePlate(plate: $0) }

    // MARK: - When it shows

    /// The hour bands of the painted lights, local time, on the sky's own
    /// schedule (`SkyModel.keyframes`: day 07:45-17:15, golden hour
    /// 17:45-19:15, night from 20:45, each edge blending over 30 minutes):
    /// the band a plate paints runs to the middle of the blend. Dawn and
    /// dusk keep the sprite island until they are painted.
    public static let dayHours: Range<Double> = 7.75..<17.5
    public static let goldenHours: Range<Double> = 17.5..<19.5
    /// Night: from 20:00 to 05:45 (`hour` wraps), and the bedtime window.
    public static func isNightHour(_ hour: Double) -> Bool {
        hour >= 20 || hour < 5.75
    }

    /// The painted light of an hour: `day`, `golden` or `night` (the bedtime window is night), or
    /// `nil` at dawn and dusk, which keep the sprite island.
    public static func lightBand(hour: Double, isBedtime: Bool) -> String? {
        if isBedtime || isNightHour(hour) { return "night" }
        if dayHours.contains(hour) { return "day" }
        if goldenHours.contains(hour) { return "golden" }
        return nil
    }

    /// The painted state for this level, hour and weather: the light and
    /// the stage (day: one per island level; golden and night: level 10), or
    /// `nil` for the sprite island.
    public static func state(
        in plate: PlateIsland,
        islandLevel: Int,
        hour: Double,
        weather: WeatherConditions,
        isBedtime: Bool
    ) -> (light: String, stage: Int)? {
        guard weather.weather == .clear, !weather.rainbow, let light = lightBand(hour: hour, isBedtime: isBedtime) else { return nil }
        guard plate.lights.contains(light) else { return nil }
        if light == "day" {
            return plate.dayStage(islandLevel: islandLevel).map { (light, $0) }
        }
        // Golden and night are painted at the final level only.
        return islandLevel >= (plate.stageLevels.max() ?? plate.minLevel) ? (light, 0) : nil
    }

    /// The plate for this world and look now, or `nil` for the sprite
    /// island. The hour and the weather are the scene's own (a look's
    /// override, else the world's clock and its seeded weather).
    public static func resolve(
        _ plate: HomePlate? = shipped,
        world: WorldSnapshot,
        look: WorldLook,
        calendar: Calendar = .current
    ) -> HomePlate? {
        guard let plate, look.homePlates else { return nil }
        let minute = look.hourOverride.map { $0 * 60 } ?? world.clock.map { SkyModel.minuteOfDay($0, calendar: calendar) } ?? 12 * 60
        let weather = look.weatherOverride
            ?? WeatherForecast.conditions(clock: world.clock, firstDay: world.firstDay, hour: minute / 60, calendar: calendar)
        guard let state = state(in: plate.plate, islandLevel: world.islandLevel, hour: minute / 60, weather: weather, isBedtime: world.isBedtime) else { return nil }
        return HomePlate(plate: plate.plate, light: state.light, stage: state.stage)
    }

    // MARK: - Plate and world

    public func world(_ p: PlatePoint) -> WorldPoint {
        WorldPoint(x: (p.x - origin.x) * unitsPerPixel, y: (p.y - origin.y) * unitsPerPixel)
    }

    public func plate(_ w: WorldPoint) -> PlatePoint {
        PlatePoint(x: origin.x + w.x / unitsPerPixel, y: origin.y + w.y / unitsPerPixel)
    }

    public func worldBox(_ r: PlateRect) -> WorldBox {
        let a = world(PlatePoint(x: r.minX, y: r.minY)), b = world(PlatePoint(x: r.maxX, y: r.maxY))
        return WorldBox(minX: a.x, minY: a.y, maxX: b.x, maxY: b.y)
    }

    /// The whole plate, the island's art and the backdrop, in world units.
    public var plateBox: WorldBox { worldBox(plate.plateSize) }
    public var islandBox: WorldBox { worldBox(plate.islandBox) }
    public var backdropBox: WorldBox { worldBox(plate.backdropBox) }

    // MARK: - Characters

    /// Pofu's scale on the plate (his 64 units drawn `pofuWidth` pixels wide).
    public var characterScale: Double {
        plate.pofuWidth * unitsPerPixel / Self.pofuArtWidth
    }

    /// A resident's scale: Pofu's proportion, boosted so they still read.
    public var residentScale: Double {
        characterScale * plate.residentBoost
    }

    /// A resident's own scale: its boost (`residentBoosts`: Mochi and Findik are drawn at least 60 %
    /// of Pofu's painted height) or the plate's.
    public func residentScale(_ id: ResidentID) -> Double {
        characterScale * (plate.residentBoosts[id.rawValue] ?? plate.residentBoost)
    }

    /// Where a resident stands on the plate, in world units; `nil` keeps
    /// them off it.
    public func residentFeet(_ id: ResidentID) -> WorldPoint? {
        plate.characters[id.rawValue].map(world)
    }

    /// A resident's sprite box (`sharp`) scaled and placed at its feet.
    public func residentBox(art box: WorldBox, at feet: WorldPoint, id: ResidentID? = nil) -> WorldBox {
        let s = id.map(residentScale) ?? residentScale
        return WorldBox(minX: feet.x + box.minX * s, minY: feet.y + box.minY * s, maxX: feet.x + box.maxX * s, maxY: feet.y + box.maxY * s)
    }

    /// Pofu's box on the plate (his soft art's box, scaled).
    public var pofuBox: WorldBox {
        let s = characterScale
        let f = IslandLayout.pofu
        return WorldBox(minX: f.x - 32 * s, minY: f.y - 64 * s, maxX: f.x + 32 * s, maxY: f.y + 2 * s)
    }

    // MARK: - Light

    private func map(_ maps: [String: [[[String]]]]) -> [[String]] {
        let stages = maps[light] ?? []
        return stage < stages.count ? stages[stage] : (stages.first ?? [])
    }

    /// The plate's lit colour at a world point.
    public func litColour(at w: WorldPoint) -> PofuRGB {
        PlateMath.light(at: plate(w), map: map(plate.lightMap), plateSize: plate.plateSize)
    }

    /// The plate's shadow colour at a world point.
    public func shadowColour(at w: WorldPoint) -> PofuRGB {
        PlateMath.light(at: plate(w), map: map(plate.shadowMap), plateSize: plate.plateSize)
    }

    /// A character's gain standing at `feet` (1 on the open lawn).
    public func gain(at feet: WorldPoint) -> Double {
        PlateMath.characterGain(light: litColour(at: feet), reference: referenceLight)
    }

    /// The contact pad's multiply colour at `feet`: the grass's own shadow
    /// tone over its lit tone.
    public func contactTone(at feet: WorldPoint) -> PofuRGB {
        PlateMath.contactRatio(lit: litColour(at: feet), shadow: shadowColour(at: feet))
    }

    /// The median lit luminance over the walkable lawn's cells.
    private static func reference(plate: PlateIsland, light: String, stage: Int) -> PofuRGB {
        let stages = plate.lightMap[light] ?? []
        let map = stage < stages.count ? stages[stage] : (stages.first ?? [])
        let rows = map.count, cols = map.first?.count ?? 0
        var colours: [PofuRGB] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let centre = PlatePoint(
                    x: (Double(c) + 0.5) * plate.plateSize.width / Double(cols),
                    y: (Double(r) + 0.5) * plate.plateSize.height / Double(rows)
                )
                if plate.walkable.isEmpty || PlateMath.contains(plate.walkable, centre) {
                    colours.append(PlateMath.rgb(map[r][c]))
                }
            }
        }
        guard !colours.isEmpty else { return PofuRGB(red: 1, green: 1, blue: 1) }
        return colours.sorted { PlateMath.luminance($0) < PlateMath.luminance($1) }[colours.count / 2]
    }

    // MARK: - Objects

    /// The objects painted in this state: a level that does not paint one
    /// (no windmill at level 5) has no tap polygon or occluder for it.
    public var objects: [PlateIsland.Object] {
        plate.objects.filter { $0.isPresent(light: light, stage: stage) }
    }

    // MARK: - Characters in the plate's light

    /// The paint multiply for a character standing at `feet`: this state's
    /// harmony tint (the plate's lawn light against the level-10 day's) times
    /// the gain for a lee on the plate (`gain(at:)`).
    public func paint(at feet: WorldPoint) -> PofuRGB {
        let g = gain(at: feet), t = harmony.tint
        return PofuRGB(red: t.red * g, green: t.green * g, blue: t.blue * g)
    }

    /// The light on one character (docs/design/visual-system.md "Characters"): the ambient multiply,
    /// the key light's rim on its lit side, the lawn's bounce on its lower third, the lamp pool at
    /// night and the two-layer contact shadow, all read from the state's `harmony` and the plate's
    /// light maps. `width` and `height` are the sprite's size in world units, `id` the character's
    /// (`pofu`, `mochi`, `findik`).
    public struct CharacterLight: Hashable, Sendable {
        /// The ambient multiply.
        public var paint: PofuRGB
        /// The key light's colour, its rim strength on the lit side and the fill left on the other.
        public var key: PofuRGB
        public var rim: Double
        public var fill: Double
        /// The unit vector toward the key light, in screen axes (y grows down).
        public var toward: PlatePoint
        /// The lawn's colour and how much of it bounces onto the lower third.
        public var bounce: PofuRGB
        public var bounceAmount: Double
        /// The lamp pool's strength under the character (0 away from a lamp, and in daylight).
        public var pool: Double
        /// The soft pad's and the core's multiply colours, in the lawn's own shadow hue.
        public var pad: PofuRGB
        public var core: PofuRGB
        /// The state's contact strength.
        public var contact: Double
        /// How much of its colour the sprite keeps (`Harmony.saturation`).
        public var saturation: Double
    }

    /// How deep the occlusion core is against the lawn's own shadow (linear light).
    public static let coreDepth = 0.55

    public func characterLight(at feet: WorldPoint, width: Double, height: Double, id: String) -> CharacterLight {
        let h = harmony
        let g = gain(at: feet) * (h.scale[id] ?? 1)
        let at = plate(feet)
        let widthPlate = width / unitsPerPixel
        let centre = PlatePoint(x: at.x, y: at.y - 0.45 * height / unitsPerPixel)
        // By day and at golden hour the key is the sun, up on the side the plate is lit from; at
        // night the nearest lamp's lantern, and the pool and the rim grow as one steps toward it.
        var toward = PlatePoint(x: plate.lightDirection.x, y: -abs(plate.lightDirection.y))
        var closeness = 1.0
        if h.pool > 0, let lamp = plate.lamps.min(by: { hypot($0.x - at.x, $0.y - at.y) < hypot($1.x - at.x, $1.y - at.y) }) {
            let t = max(0, 1 - hypot(lamp.x - at.x, lamp.y - at.y) / (2 * widthPlate))
            closeness = t * t * (3 - 2 * t)
            toward = PlatePoint(x: lamp.x - centre.x, y: lamp.y - plate.lampHeight - centre.y)
        }
        let length = hypot(toward.x, toward.y)
        toward = length > 1e-6 ? PlatePoint(x: toward.x / length, y: toward.y / length) : PlatePoint(x: 0, y: -1)
        let lit = litColour(at: feet), shadow = shadowColour(at: feet)
        return CharacterLight(
            paint: PofuRGB(red: h.tint.red * g, green: h.tint.green * g, blue: h.tint.blue * g),
            key: h.key,
            rim: h.pool > 0 ? h.rim * (0.4 + 0.6 * closeness) : h.rim,
            fill: h.fill,
            toward: toward,
            bounce: lit,
            bounceAmount: h.bounce,
            pool: h.pool * closeness,
            pad: PlateMath.contactRatio(lit: lit, shadow: shadow),
            core: PlateMath.contactRatio(lit: lit, shadow: shadow, depth: Self.coreDepth),
            contact: h.contact,
            saturation: h.saturation
        )
    }

    // MARK: - Occlusion

    /// The occluders that draw over a character standing at `feet` with
    /// `box` (world units): those it stands behind and overlaps.
    public func occluders(over feet: WorldPoint, box: WorldBox) -> [PlateIsland.Object] {
        let a = plate(WorldPoint(x: box.minX, y: box.minY)), b = plate(WorldPoint(x: box.maxX, y: box.maxY))
        return PlateMath.occluders(
            over: (footY: plate(feet).y, box: PlateRect(minX: a.x, minY: a.y, maxX: b.x, maxY: b.y)),
            in: plate, light: light, stage: stage
        )
    }

    /// An occluder's cut-out box, in world units.
    public func occluderBox(_ object: PlateIsland.Object) -> WorldBox {
        worldBox(object.box ?? PlateMath.bounds(object.polygon))
    }

    /// The depth an object sorts at among the characters (the scene's
    /// depth of its foot line).
    public func depth(of object: PlateIsland.Object) -> Double {
        IslandLayout.depth(ofY: world(PlatePoint(x: 0, y: object.footY)).y)
    }

    // MARK: - Taps

    /// The tap object under a world point (`PlateMath.hit`).
    public func tapObject(at w: WorldPoint) -> PlateIsland.Object? {
        PlateMath.hit(plate, at: plate(w), light: light, stage: stage)
    }

    public func worldPolygon(_ object: PlateIsland.Object) -> [WorldPoint] {
        object.polygon.map(world)
    }

    /// A station's polygon's box, in world units: what a focus frames.
    public func stationBox(_ station: StationID) -> WorldBox? {
        objects.first { $0.station == station }.map { worldBox(PlateMath.bounds($0.polygon)) }
    }

    /// Where the seeds leave from at Collect: the built stations' objects
    /// on the plate, and Pofu.
    public func seedSources(builtStations: Set<StationID>) -> [WorldPoint] {
        let sources = objects.filter { $0.station.map(builtStations.contains) ?? false }
        return sources.map { o in
            let b = PlateMath.bounds(o.polygon)
            return world(PlatePoint(x: (b.minX + b.maxX) / 2, y: b.minY + b.height * 0.35))
        } + [WorldPoint(x: IslandLayout.pofu.x, y: IslandLayout.pofu.y - 64 * characterScale * 0.5)]
    }

    // MARK: - Framing (reference points, as `CameraRail.Stop`)

    private var islandWidthUnits: Double {
        plate.islandBox.width * unitsPerPixel
    }

    /// Home: the island `homeWidths` wide at Home's scale, its top at
    /// `homeTopY`, the screen's centre at `homeCenterX` of it.
    public var homeStop: CameraRail.Stop {
        let box = plate.islandBox
        let look = world(PlatePoint(x: box.minX + plate.framing.homeCenterX * box.width, y: box.minY))
        return CameraRail.Stop(scale: IslandFraming.homeScale, look: look, anchorY: plate.framing.homeTopY)
    }

    /// The island whole, `widths` wide, centred in the band between the
    /// chrome.
    public func centredStop(widths: Double) -> CameraRail.Stop {
        let box = islandBox
        return CameraRail.Stop(
            scale: PlateMath.framing(islandWidthUnits: islandWidthUnits, widths: widths, screenWidthPoints: CameraRail.referenceWidth),
            look: WorldPoint(x: box.midX, y: box.midY),
            anchorY: IslandFraming.bandMid(height: CameraRail.referenceHeight)
        )
    }

    /// The Island stop and the establishing shot.
    public var islandStop: CameraRail.Stop { centredStop(widths: plate.framing.islandWidths) }
    public var wholeStop: CameraRail.Stop { centredStop(widths: plate.framing.wholeWidths) }

    /// The rail's stops while the plate shows: the Map as ever, the plate's
    /// Island and Home.
    public var stops: [CameraRail.Stop] {
        [CameraRail.referenceStops[0], islandStop, homeStop]
    }
}
