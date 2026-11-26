import Foundation
import PofuCore
import PofuDesignSystem

/// A point in a plate's pixels (the full 1536 x 1024 plate).
public struct PlatePoint: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// A rectangle in a plate's pixels.
public struct PlateRect: Hashable, Sendable {
    public var minX: Double
    public var minY: Double
    public var maxX: Double
    public var maxY: Double

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    public var width: Double { maxX - minX }
    public var height: Double { maxY - minY }

    public func overlaps(_ other: PlateRect) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }
}

/// A painted plate-first island as `tools/plate/ingest.py` writes it
/// (`Plates/plate-<island>.json`, ADR-0022, docs/design/plate-islands.md §0).
/// The painted plate is the final picture: the runtime draws it and puts
/// characters on it, and never grades, fogs or hazes it.
public struct PlateIsland: Hashable, Sendable {
    public struct Object: Hashable, Sendable, Identifiable {
        public var id: String
        /// Answers taps (`PlateMath.hit`).
        public var tap: Bool
        /// The string key of its VoiceOver label.
        public var label: String
        /// The station a tap routes to, if any.
        public var station: StationID?
        /// The outline, in plate pixels.
        public var polygon: [PlatePoint]
        /// Where it meets the ground: the outline's lowest y.
        public var footY: Double
        /// Drawn again over a character whose feet are behind it.
        public var occluder: Bool
        /// The occluder cut-out's box, in plate pixels.
        public var box: PlateRect?
        /// The stages that paint it, for every light (a night stage is the same island level as the
        /// day stage); `nil`: all. A lower level never has a tap polygon or an occluder on
        /// something that is not painted.
        public var stages: [Int]?

        public func isPresent(light: String, stage: Int) -> Bool {
            stages?.contains(stage) ?? true
        }
    }

    /// The character harmony rule's data for one painted state
    /// (docs/design/visual-system.md "Characters"): the multiply tint (sRGB) that puts a sprite
    /// in the plate's light and the strength of its contact shadow against the level-10 day's.
    ///
    /// The rest is the state's key light: its colour, the `rim` strength on the lit side and the
    /// `fill` that stays on the shaded side, the night lamp `pool`'s strength and the lawn-colour
    /// `bounce` on a sprite's lower third (`HomePlate.characterLight`).
    public struct Harmony: Hashable, Sendable {
        public var tint: PofuRGB
        public var contact: Double
        public var key: PofuRGB
        public var rim: Double
        public var fill: Double
        public var pool: Double
        public var bounce: Double
        /// A character's own share of the ambient `tint` where its lawn is darker (night), by id.
        public var scale: [String: Double]
        /// How much of its colour a sprite keeps (1 by default): a plate paler than the island's
        /// root (Çağlayan's dry stages) asks the character to be less colourful than its lawn,
        /// which a multiply cannot do.
        public var saturation: Double

        public init(
            tint: PofuRGB, contact: Double, key: PofuRGB = PofuRGB(red: 1, green: 1, blue: 1),
            rim: Double = 0, fill: Double = 0, pool: Double = 0, bounce: Double = 0, scale: [String: Double] = [:],
            saturation: Double = 1
        ) {
            self.saturation = saturation
            self.scale = scale
            self.tint = tint
            self.contact = contact
            self.key = key
            self.rim = rim
            self.fill = fill
            self.pool = pool
            self.bounce = bounce
        }

        public static let neutral = Harmony(tint: PofuRGB(red: 1, green: 1, blue: 1), contact: 1)
    }

    public struct Framing: Hashable, Sendable {
        /// The island's width at Home, in screen widths.
        public var homeWidths: Double
        /// The screen's centre at Home, as a fraction of the island's width.
        public var homeCenterX: Double
        /// The island's top at Home, in reference points from the screen's top.
        public var homeTopY: Double
        /// The island's width at the Island stop and in the establishing shot.
        public var islandWidths: Double
        public var wholeWidths: Double
    }

    public var island: String
    public var version: Int
    /// A concept standing in for the island's real plate.
    public var standIn: Bool
    /// The first island level the plate shows.
    public var minLevel: Int
    public var plateSize: PlateRect
    public var stages: Int
    public var lights: [String]
    /// How many stages each light's arrays hold (day: one per level, or one per story stage).
    public var lightStages: [String: Int]
    /// The stages each light paints. A light painted at some stages only (Çağlayan's night: 2 and 3)
    /// has arrays padded to its highest stage; every other state keeps the sprite island.
    public var painted: [String: [Int]]
    /// The island level each day stage paints, stage 0 first (`[10, 9, ... 2]`).
    public var stageLevels: [Int]
    /// Per light, per stage: the character harmony data.
    public var harmony: [String: [Harmony]]
    /// The island's art (the matte's box), in plate pixels.
    public var islandBox: PlateRect
    /// The backdrop image's box, in plate pixels (it runs past the plate).
    public var backdropBox: PlateRect
    public var objects: [Object]
    public var walkable: [PlatePoint]
    /// Where each character stands, by id (`pofu`, `mochi`, `findik`).
    public var characters: [String: PlatePoint]
    /// Where each character may stand and hop between (`PlateMoves`), by id: the first spot is the
    /// painted one (the same point as `characters`), the rest are on the lawn clear of every
    /// occluder taller than the character at every stage (`PlateMovesTests`).
    public var spots: [String: [PlatePoint]]
    /// Pofu's width on the plate, in plate pixels.
    public var pofuWidth: Double
    /// How much larger residents are drawn than Pofu's proportion gives.
    public var residentBoost: Double
    /// A resident's own boost by id (`mochi`, `findik`), over `residentBoost`.
    public var residentBoosts: [String: Double]
    /// The painted lamp posts' ground points, in plate pixels; the lantern's glow sits `lampHeight`
    /// above each.
    public var lamps: [PlatePoint]
    public var lampHeight: Double
    public var framing: Framing
    public var lightDirection: PlatePoint
    /// Per light, per stage: 20 rows of 32 lit colours (`#rrggbb`).
    public var lightMap: [String: [[[String]]]]
    /// Per light, per stage: 20 rows of 32 shadow colours.
    public var shadowMap: [String: [[[String]]]]
    public var textureBytes: Int
    /// The jar, the pots and the lantern the app places over the plate (WP5): their painted size and, per stage,
    /// where each stands. Empty for a plate with none.
    public var props: [PlateProp] = []
    /// Per stage: the island's contact shadow on the cloud below it, drawn by code from the matte (the plate has none of
    /// its own). Empty for a plate whose ingest wrote none.
    public var shadows: [PlateShadow]

    /// Per light, per stage: the box the shipped plate image covers (plate pixels) when the plate is matted to its island
    /// and cropped to it (`tools/plate/ingest.py` `plate_crop`), or `nil`: the image is the whole plate over its backdrop
    /// (a legacy matte, or an island whose plates are not matted).
    public var plateCrops: [String: [PlateRect?]] = [:]

    /// A station's painted looks, one per level, over an erased base (`tools/plate/station_looks.py`), by station id.
    /// Empty for a plate whose data has none: its stations stay painted into the plate.
    public var stations: [String: StationLooks] = [:]

    /// The painting's camera elevation in degrees (`camera.elevationDeg`, v2 §5.1), or `nil`: no lens.
    public var elevationDeg: Double?
    /// The near layers and the lens's shots (`near`, WP11), or `nil` for a plate with none.
    public var near: PlateNear?
    /// The bodies of water the region shaders move (`water`, WP13); empty for a plate with none.
    public var water: [PlateWater] = []

    /// The cropped plate's box for a state, or `nil` where the state ships the whole plate (see `plateCrops`).
    public func plateCrop(light: String, stage: Int) -> PlateRect? {
        guard let crops = plateCrops[light], crops.indices.contains(stage) else { return nil }
        return crops[stage]
    }

    /// The contact shadow of a stage, if the data has one.
    public func shadow(stage: Int) -> PlateShadow? {
        shadows.indices.contains(stage) ? shadows[stage] : nil
    }

    // MARK: Asset names (docs/design/plate-islands.md §0)

    /// The whole plate, its border feathered; a matted plate is its island alone, cropped (`plateCrop`).
    public func plateArt(light: String, stage: Int) -> String {
        "world-\(island)-plate-\(light)-\(stage)"
    }

    /// The island cut from its sky, at half size.
    public func islandArt(light: String, stage: Int) -> String {
        "world-\(island)-island-\(light)-\(stage)"
    }

    /// The islands whose island cut has a clean Map cut (`tools/plate/map_cut.py`): every Home state
    /// shares the level-10 matte, so below level 10 its island cut carries the lower level's sky where
    /// level 10 paints its windmill, lighthouse, hill and islet (a pale ghost behind the island).
    static let mapCuts: Set<String> = ["home"]

    /// The island cut drawn on the Map and in a flight: Home's from its own painting without that ghost
    /// (`world-home-mapisle-<light>-<stage>`), another island's its island cut.
    public func mapIslandArt(light: String, stage: Int) -> String {
        Self.mapCuts.contains(island) ? "world-\(island)-mapisle-\(light)-\(stage)" : islandArt(light: light, stage: stage)
    }

    /// The plate's sky and cloud sea, extended.
    public func backdropArt(light: String, stage: Int) -> String {
        "world-\(island)-backdrop-\(light)-\(stage)"
    }

    /// What the plate draws as its picture in a state: the base (the plate with its stations erased) where a station's
    /// looks stand over one, else the plate. The painted plate itself (`plateArt`) stays the painting other surfaces show.
    public func drawnPlateArt(light: String, stage: Int) -> String {
        stationLooks(light: light, stage: stage).isEmpty ? plateArt(light: light, stage: stage) : "world-\(island)-base-\(light)-\(stage)"
    }

    /// The looks that stand over this state's base: empty where the state keeps its painted stations.
    public func stationLooks(light: String, stage: Int) -> [String: StationLooks] {
        stations.filter { $0.value.hasBase(light: light, stage: stage) }
    }

    /// A station's look asset for its level (`StationLooks.lookLevel`), or `nil`: unbuilt, or no base in this state.
    public func lookArt(station: String, level: Int, light: String, stage: Int) -> String? {
        guard let looks = stations[station], looks.hasBase(light: light, stage: stage), let n = looks.lookLevel(stationLevel: level, light: light) else { return nil }
        return "world-\(island)-look-\(station)-\(n)-\(StationLooks.lookLight(for: light))"
    }

    public func occluderArt(id: String, light: String, stage: Int) -> String {
        "world-\(island)-occ-\(id)-\(light)-\(stage)"
    }

    public func diffArt(light: String, from stage: Int) -> String {
        "world-\(island)-diff-\(light)-\(stage)"
    }

    public func emissiveArt(light: String, stage: Int) -> String {
        "world-\(island)-emit-\(light)-\(stage)"
    }

    public func upgradeArt(id: String, light: String) -> String {
        "world-\(island)-up-\(id)-\(light)"
    }

    public func lutArt(light: String) -> String {
        "world-lut-plate-\(island)-\(light)"
    }

    /// Whether the island paints this light at this stage.
    public func paints(light: String, stage: Int) -> Bool {
        painted[light]?.contains(stage) ?? false
    }

    public func object(_ id: String) -> Object? {
        objects.first { $0.id == id }
    }

    /// The day stage that paints an island level: the plate's own level or the nearest below it,
    /// `nil` under the lowest painted level.
    public func dayStage(islandLevel: Int) -> Int? {
        guard let lowest = stageLevels.min(), islandLevel >= lowest else { return nil }
        return stageLevels.firstIndex { $0 <= islandLevel }
    }

    public func harmony(light: String, stage: Int) -> Harmony {
        let states = harmony[light] ?? []
        return stage < states.count ? states[stage] : .neutral
    }

    // MARK: Loading

    /// The island's metadata from the package's resources, or `nil`
    /// without it (the legacy sprite path then draws the island).
    public static func load(_ island: String) -> PlateIsland? {
        let name = "plate-\(island)"
        let url = Bundle.module.url(forResource: name, withExtension: "json")
            ?? Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Plates")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }

    /// Decodes the JSON `ingest.py` writes.
    public static func decode(_ data: Data) throws -> PlateIsland {
        try JSONDecoder().decode(PlateIsland.self, from: data)
    }
}

/// One station's looks (`tools/plate/station_looks.py`): level 1 to `levels`, one asset each, every look on one canvas
/// (`box`, plate points) with one foot anchor, over the erased base each light has at its stages (`lights`).
public struct StationLooks: Hashable, Sendable {
    public var levels: Int
    /// The look canvas, in plate points; the same for every look and every base stage.
    public var box: PlateRect
    /// The point of the plate the look's foot stands on (the canvas is placed by it).
    public var foot: PlatePoint
    /// Per light, the stages whose plate has this station erased (the others keep it painted). Golden has no looks of
    /// its own: it draws the day look under its grade, over a golden base listed here.
    public var lights: [String: [Int]]
    /// Per light, the levels whose look is painted, where a light lacks some (a level whose cut failed is left out and
    /// draws the nearest lower one). A light not listed has every level 1 to `levels`.
    public var lookLevels: [String: [Int]] = [:]
    /// Where the look stands in a stage whose plate paints the stall elsewhere or at another size: that stage's canvas
    /// box and foot (the same canvas scaled about the foot). A stage without an entry uses `box` and `foot`.
    public var places: [Int: StationPlace] = [:]

    /// The stages of the day light that have a base (the first light that was painted).
    public var baseStages: [Int] { lights["day"] ?? [] }

    public init(
        levels: Int, box: PlateRect, foot: PlatePoint, lights: [String: [Int]],
        lookLevels: [String: [Int]] = [:], places: [Int: StationPlace] = [:]
    ) {
        self.levels = levels
        self.box = box
        self.foot = foot
        self.lights = lights
        self.lookLevels = lookLevels
        self.places = places
    }

    /// The canvas box and foot for a stage.
    public func place(stage: Int) -> StationPlace {
        places[stage] ?? StationPlace(box: box, foot: foot)
    }

    public func hasBase(light: String, stage: Int) -> Bool {
        lights[light]?.contains(stage) ?? false
    }

    /// The light whose looks a state in `light` draws: golden draws the day look (under its grade), the others their own.
    public static func lookLight(for light: String) -> String {
        light == "golden" ? "day" : light
    }

    /// The look a station level draws: level to look 1 to 1, `nil` while unbuilt (level 0), a level above the
    /// last look keeps the last.
    public func lookLevel(stationLevel: Int) -> Int? {
        stationLevel >= 1 && levels >= 1 ? min(stationLevel, levels) : nil
    }

    /// The look drawn for a station level in a state's light: the level's own look, else the nearest lower one that
    /// is painted in that light's looks, or `nil` while unbuilt or when none below it exists.
    public func lookLevel(stationLevel: Int, light: String) -> Int? {
        guard let wanted = lookLevel(stationLevel: stationLevel) else { return nil }
        guard let have = lookLevels[Self.lookLight(for: light)] else { return wanted }
        return have.filter { $0 <= wanted }.max()
    }
}

/// One stage's placement of a station's look: its canvas box and foot anchor, in plate points.
public struct StationPlace: Hashable, Sendable {
    public var box: PlateRect
    public var foot: PlatePoint
}

/// An island's contact shadow: an ellipse (`centre`, `radii`, plate pixels) softened by `blur` and drawn at `opacity`
/// in a dark sky tone (`island_shadow` in tools/proof/island_matte.py).
/// One home prop's painted size and its slots (`tools/plate/props_slice.py`). `height` and `width` are plate pts of
/// the art; a slot is the foot's centre, `[x, y]` in plate pts, with the row's width as a third number for the pots.
public struct PlateProp: Decodable, Hashable, Sendable {
    public var id: String
    public var height: Double
    public var width: Double
    /// The image's states, in the asset names `world-home-prop-<prop>-<state>`.
    public var states: [String]
    /// The art's bytes over every state (one byte a pixel), for the texture budget.
    public var bytes: Int
    public var slots: [[Double]]

    /// The foot's centre at `stage`, or `nil` when the plate has no slot for it.
    public func slot(stage: Int) -> PlatePoint? {
        guard slots.indices.contains(stage), slots[stage].count >= 2 else { return nil }
        return PlatePoint(x: slots[stage][0], y: slots[stage][1])
    }

    /// The pots' row width at `stage`, plate pts (the prop's own width for the others).
    public func span(stage: Int) -> Double {
        guard slots.indices.contains(stage), slots[stage].count >= 3 else { return width }
        return slots[stage][2]
    }
}

public struct PlateShadow: Decodable, Hashable, Sendable {
    public var centre: PlatePoint
    public var radii: PlatePoint
    public var blur: Double
    public var opacity: Double

    private enum Keys: String, CodingKey { case centre, radii, blur, opacity }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let centre = try c.decode([Double].self, forKey: .centre)
        let radii = try c.decode([Double].self, forKey: .radii)
        guard centre.count == 2, radii.count == 2 else {
            throw DecodingError.dataCorruptedError(forKey: .centre, in: c, debugDescription: "centre and radii take two numbers")
        }
        self.centre = PlatePoint(x: centre[0], y: centre[1])
        self.radii = PlatePoint(x: radii[0], y: radii[1])
        blur = try c.decodeIfPresent(Double.self, forKey: .blur) ?? 0
        opacity = try c.decode(Double.self, forKey: .opacity)
    }
}

// MARK: - Decoding

extension PlateIsland: Decodable {
    private enum Keys: String, CodingKey {
        case island, version, standIn, minLevel, plateSize, stages, lights, lightStages, painted, stageLevels, harmony, islandBox, backdropBox, objects
        case walkable, characters, spots, pofuWidth, residentBoost, residentBoosts, lamps, lampHeight, framing, lightDirection, lightMap, shadowMap, textureBytes, shadow, plateCrop, props, stations, camera, near, water
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        island = try c.decode(String.self, forKey: .island)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        standIn = try c.decodeIfPresent(Bool.self, forKey: .standIn) ?? false
        minLevel = try c.decodeIfPresent(Int.self, forKey: .minLevel) ?? 1
        let size = try c.decode([Double].self, forKey: .plateSize)
        plateSize = PlateRect(minX: 0, minY: 0, maxX: size.first ?? 1536, maxY: size.last ?? 1024)
        let stageCount = try c.decodeIfPresent(Int.self, forKey: .stages) ?? 1
        stages = stageCount
        let lightNames = try c.decode([String].self, forKey: .lights)
        lights = lightNames
        lightStages = try c.decodeIfPresent([String: Int].self, forKey: .lightStages) ?? Dictionary(uniqueKeysWithValues: lightNames.map { ($0, stageCount) })
        if let stagesPainted = try c.decodeIfPresent([String: [Int]].self, forKey: .painted) {
            painted = stagesPainted
        } else {
            var everyStage: [String: [Int]] = [:]
            for (light, count) in lightStages {
                everyStage[light] = Array(0..<count)
            }
            painted = everyStage
        }
        stageLevels = try c.decodeIfPresent([Int].self, forKey: .stageLevels) ?? [minLevel]
        harmony = try (c.decodeIfPresent([String: [RawHarmony]].self, forKey: .harmony) ?? [:]).mapValues { $0.map(\.harmony) }
        islandBox = try Self.rect(c.decode([Double].self, forKey: .islandBox))
        backdropBox = try c.decodeIfPresent([Double].self, forKey: .backdropBox).map(Self.rect) ?? plateSize
        objects = try c.decode([RawObject].self, forKey: .objects).map(\.object)
        walkable = try (c.decodeIfPresent([[Double]].self, forKey: .walkable) ?? []).map(Self.point)
        characters = try (c.decodeIfPresent([String: [Double]].self, forKey: .characters) ?? [:]).mapValues(Self.point)
        spots = try (c.decodeIfPresent([String: [[Double]]].self, forKey: .spots) ?? [:]).mapValues { try $0.map(Self.point) }
        pofuWidth = try c.decodeIfPresent(Double.self, forKey: .pofuWidth) ?? 100
        residentBoost = try c.decodeIfPresent(Double.self, forKey: .residentBoost) ?? 1
        residentBoosts = try c.decodeIfPresent([String: Double].self, forKey: .residentBoosts) ?? [:]
        lamps = try (c.decodeIfPresent([[Double]].self, forKey: .lamps) ?? []).map(Self.point)
        lampHeight = try c.decodeIfPresent(Double.self, forKey: .lampHeight) ?? 30
        let f = try c.decodeIfPresent(RawFraming.self, forKey: .framing) ?? RawFraming()
        framing = Framing(
            homeWidths: f.homeWidths ?? 1.15,
            homeCenterX: f.homeCenterX ?? 0.5,
            homeTopY: f.homeTopY ?? 190,
            islandWidths: f.islandWidths ?? 0.84,
            wholeWidths: f.wholeWidths ?? 0.92
        )
        lightDirection = try Self.point(c.decodeIfPresent([Double].self, forKey: .lightDirection) ?? [0.5, 0.3])
        lightMap = try c.decodeIfPresent([String: [[[String]]]].self, forKey: .lightMap) ?? [:]
        shadowMap = try c.decodeIfPresent([String: [[[String]]]].self, forKey: .shadowMap) ?? [:]
        textureBytes = try c.decodeIfPresent(Int.self, forKey: .textureBytes) ?? 0
        shadows = try c.decodeIfPresent([PlateShadow].self, forKey: .shadow) ?? []
        props = try c.decodeIfPresent([PlateProp].self, forKey: .props) ?? []
        elevationDeg = try c.decodeIfPresent(PlateCamera.self, forKey: .camera)?.elevationDeg
        near = try c.decodeIfPresent(PlateNear.self, forKey: .near)
        water = try c.decodeIfPresent([PlateWater].self, forKey: .water) ?? []
        stations = try (c.decodeIfPresent([String: RawStation].self, forKey: .stations) ?? [:]).compactMapValues(\.looks)
        plateCrops = try (c.decodeIfPresent([String: [[Double]?]].self, forKey: .plateCrop) ?? [:]).mapValues { boxes in
            try boxes.map { try $0.map(Self.rect) }
        }
    }

    private struct RawHarmony: Decodable {
        var tint: [Double]
        var contact: Double
        var key: [Double]?
        var rim: Double?
        var fill: Double?
        var pool: Double?
        var bounce: Double?
        var scale: [String: Double]?
        var saturation: Double?

        var harmony: Harmony {
            func rgb(_ v: [Double]?) -> PofuRGB {
                guard let v, v.count == 3 else { return PofuRGB(red: 1, green: 1, blue: 1) }
                return PofuRGB(red: v[0], green: v[1], blue: v[2])
            }
            return Harmony(tint: rgb(tint), contact: contact, key: rgb(key), rim: rim ?? 0, fill: fill ?? 0, pool: pool ?? 0, bounce: bounce ?? 0, scale: scale ?? [:], saturation: saturation ?? 1)
        }
    }

    private struct RawStation: Decodable {
        /// The old keys: one light and its base stages. `lights` wins where both are present.
        var light: String?
        var baseStages: [Int]?
        var lights: [String: [Int]]?
        var lookLevels: [String: [Int]]?
        var levels: Int
        var box: [Double]
        var foot: [Double]
        var stages: [String: RawPlace]?

        struct RawPlace: Decodable {
            var box: [Double]
            var foot: [Double]
        }

        var looks: StationLooks? {
            guard box.count == 4, foot.count == 2 else { return nil }
            var places: [Int: StationPlace] = [:]
            for (key, p) in stages ?? [:] where p.box.count == 4 && p.foot.count == 2 {
                if let stage = Int(key) {
                    places[stage] = StationPlace(
                        box: PlateRect(minX: p.box[0], minY: p.box[1], maxX: p.box[2], maxY: p.box[3]),
                        foot: PlatePoint(x: p.foot[0], y: p.foot[1])
                    )
                }
            }
            let perLight = lights ?? [light ?? "day": baseStages ?? []]
            return StationLooks(
                levels: levels,
                box: PlateRect(minX: box[0], minY: box[1], maxX: box[2], maxY: box[3]),
                foot: PlatePoint(x: foot[0], y: foot[1]), lights: perLight,
                lookLevels: lookLevels ?? [:], places: places
            )
        }
    }

    private struct RawFraming: Decodable {
        var homeWidths: Double?
        var homeCenterX: Double?
        var homeTopY: Double?
        var islandWidths: Double?
        var wholeWidths: Double?
    }

    private struct RawObject: Decodable {
        var id: String
        var tap: Bool?
        var label: String?
        var station: String?
        var polygon: [[Double]]
        var footY: Double?
        var occluder: Bool?
        var box: [Double]?
        var stages: [Int]?

        var object: Object {
            let points = polygon.compactMap { p in p.count == 2 ? PlatePoint(x: p[0], y: p[1]) : nil }
            return Object(
                id: id,
                tap: tap ?? false,
                label: label ?? "",
                station: station.map(StationID.init(rawValue:)),
                polygon: points,
                footY: footY ?? points.map(\.y).max() ?? 0,
                occluder: occluder ?? false,
                box: box.flatMap { $0.count == 4 ? PlateRect(minX: $0[0], minY: $0[1], maxX: $0[2], maxY: $0[3]) : nil },
                stages: stages
            )
        }
    }

    private static func rect(_ v: [Double]) throws -> PlateRect {
        guard v.count == 4 else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "a box has four numbers")) }
        return PlateRect(minX: v[0], minY: v[1], maxX: v[2], maxY: v[3])
    }

    private static func point(_ v: [Double]) throws -> PlatePoint {
        guard v.count == 2 else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "a point has two numbers")) }
        return PlatePoint(x: v[0], y: v[1])
    }
}
