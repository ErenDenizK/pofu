import Foundation
import PofuCore
import PofuDesignSystem

/// The home island drawn from its painted plate (ADR-0022, the home first):
/// where the plate sits in the world, where the characters stand on it and
/// how large they are, its tap polygons and occluders, its light, and the
/// camera's stops while it shows.
///
/// The plate is placed so that Pofu's painted spot lands on Pofu's world
/// feet (`IslandLayout.pofu`): everything that follows Pofu (his tap, the
/// bubble, the collect moment) works unchanged. Its scale makes the island
/// `framing.homeWidths` screen widths wide at Home's scale.
///
/// It shows at the plate's island level and above, by day, in clear
/// weather; every other hour and weather keeps the sprite island until its
/// painted states exist (night is painted per ADR-0022 L1).
public struct HomePlate: Hashable, Sendable {
    public let plate: PlateIsland
    public let light: String
    public let stage: Int
    /// World units per plate pixel.
    public let unitsPerPixel: Double
    /// The plate pixel at the world's origin.
    public let origin: PlatePoint
    /// The open lawn's light: a character standing there keeps its paint.
    public let referenceLight: PofuRGB

    /// Pofu's art is 64 units wide (`PofuLayer.artWidth`).
    public static let pofuArtWidth = 64.0

    public init(plate: PlateIsland, light: String = "day", stage: Int = 0) {
        self.plate = plate
        self.light = light
        self.stage = stage
        let islandPixels = max(plate.islandBox.width, 1)
        let u = plate.framing.homeWidths * CameraRail.referenceWidth / IslandFraming.homeScale / islandPixels
        unitsPerPixel = u
        let pofu = plate.characters["pofu"]
            ?? PlatePoint(x: (plate.islandBox.minX + plate.islandBox.maxX) / 2, y: (plate.islandBox.minY + plate.islandBox.maxY) / 2)
        origin = PlatePoint(x: pofu.x - IslandLayout.pofu.x / u, y: pofu.y - IslandLayout.pofu.y / u)
        referenceLight = Self.reference(plate: plate, light: light, stage: stage)
    }

    /// The home plate shipped in the package, if any.
    public static let shipped: HomePlate? = PlateIsland.load("home").map { HomePlate(plate: $0) }

    // MARK: - When it shows

    /// The hours of the painted day plate, local time.
    public static let dayHours: Range<Double> = 9..<17

    /// Whether the plate shows: at its island level or above, by day, in
    /// clear weather, awake.
    public func shows(islandLevel: Int, hour: Double, weather: WeatherConditions, isBedtime: Bool) -> Bool {
        islandLevel >= plate.minLevel
            && Self.dayHours.contains(hour)
            && weather.weather == .clear && !weather.rainbow
            && !isBedtime
            && plate.lights.contains(light)
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
        guard let plate else { return nil }
        let minute = look.hourOverride.map { $0 * 60 } ?? world.clock.map { SkyModel.minuteOfDay($0, calendar: calendar) } ?? 12 * 60
        let weather = look.weatherOverride
            ?? WeatherForecast.conditions(clock: world.clock, firstDay: world.firstDay, hour: minute / 60, calendar: calendar)
        return plate.shows(islandLevel: world.islandLevel, hour: minute / 60, weather: weather, isBedtime: world.isBedtime) ? plate : nil
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

    /// Where a resident stands on the plate, in world units; `nil` keeps
    /// them off it.
    public func residentFeet(_ id: ResidentID) -> WorldPoint? {
        plate.characters[id.rawValue].map(world)
    }

    /// A resident's sprite box (`sharp`) scaled and placed at its feet.
    public func residentBox(art box: WorldBox, at feet: WorldPoint) -> WorldBox {
        let s = residentScale
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

    // MARK: - Occlusion

    /// The occluders that draw over a character standing at `feet` with
    /// `box` (world units): those it stands behind and overlaps.
    public func occluders(over feet: WorldPoint, box: WorldBox) -> [PlateIsland.Object] {
        let a = plate(WorldPoint(x: box.minX, y: box.minY)), b = plate(WorldPoint(x: box.maxX, y: box.maxY))
        return PlateMath.occluders(
            over: (footY: plate(feet).y, box: PlateRect(minX: a.x, minY: a.y, maxX: b.x, maxY: b.y)),
            in: plate
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
        PlateMath.hit(plate, at: plate(w))
    }

    public func worldPolygon(_ object: PlateIsland.Object) -> [WorldPoint] {
        object.polygon.map(world)
    }

    /// A station's polygon's box, in world units: what a focus frames.
    public func stationBox(_ station: StationID) -> WorldBox? {
        plate.objects.first { $0.station == station }.map { worldBox(PlateMath.bounds($0.polygon)) }
    }

    /// Where the seeds leave from at Collect: the built stations' objects
    /// on the plate, and Pofu.
    public func seedSources(builtStations: Set<StationID>) -> [WorldPoint] {
        let objects = plate.objects.filter { $0.station.map(builtStations.contains) ?? false }
        return objects.map { o in
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
