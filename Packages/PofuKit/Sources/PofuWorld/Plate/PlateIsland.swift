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
        /// The day stages that paint it; `nil`: all (golden and night are level 10, where
        /// everything is painted). A lower level never has a tap polygon or an occluder on
        /// something that is not painted.
        public var stages: [Int]?

        public func isPresent(light: String, stage: Int) -> Bool {
            light != "day" || stages?.contains(stage) ?? true
        }
    }

    /// The character harmony rule's data for one painted state
    /// (docs/design/visual-system.md "Characters"): the multiply tint (sRGB) that puts a sprite
    /// in the plate's light and the strength of its contact shadow against the level-10 day's.
    public struct Harmony: Hashable, Sendable {
        public var tint: PofuRGB
        public var contact: Double

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
    /// How many painted states each light has (day: one per level).
    public var lightStages: [String: Int]
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
    /// Pofu's width on the plate, in plate pixels.
    public var pofuWidth: Double
    /// How much larger residents are drawn than Pofu's proportion gives.
    public var residentBoost: Double
    public var framing: Framing
    public var lightDirection: PlatePoint
    /// Per light, per stage: 20 rows of 32 lit colours (`#rrggbb`).
    public var lightMap: [String: [[[String]]]]
    /// Per light, per stage: 20 rows of 32 shadow colours.
    public var shadowMap: [String: [[[String]]]]
    public var textureBytes: Int

    // MARK: Asset names (docs/design/plate-islands.md §0)

    /// The whole plate, its border feathered.
    public func plateArt(light: String, stage: Int) -> String {
        "world-\(island)-plate-\(light)-\(stage)"
    }

    /// The island cut from its sky, at half size.
    public func islandArt(light: String, stage: Int) -> String {
        "world-\(island)-island-\(light)-\(stage)"
    }

    /// The plate's sky and cloud sea, extended.
    public func backdropArt(light: String, stage: Int) -> String {
        "world-\(island)-backdrop-\(light)-\(stage)"
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

// MARK: - Decoding

extension PlateIsland: Decodable {
    private enum Keys: String, CodingKey {
        case island, version, standIn, minLevel, plateSize, stages, lights, lightStages, stageLevels, harmony, islandBox, backdropBox, objects
        case walkable, characters, pofuWidth, residentBoost, framing, lightDirection, lightMap, shadowMap, textureBytes
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
        stageLevels = try c.decodeIfPresent([Int].self, forKey: .stageLevels) ?? [minLevel]
        harmony = try (c.decodeIfPresent([String: [RawHarmony]].self, forKey: .harmony) ?? [:]).mapValues { $0.map(\.harmony) }
        islandBox = try Self.rect(c.decode([Double].self, forKey: .islandBox))
        backdropBox = try c.decodeIfPresent([Double].self, forKey: .backdropBox).map(Self.rect) ?? plateSize
        objects = try c.decode([RawObject].self, forKey: .objects).map(\.object)
        walkable = try (c.decodeIfPresent([[Double]].self, forKey: .walkable) ?? []).map(Self.point)
        characters = try (c.decodeIfPresent([String: [Double]].self, forKey: .characters) ?? [:]).mapValues(Self.point)
        pofuWidth = try c.decodeIfPresent(Double.self, forKey: .pofuWidth) ?? 100
        residentBoost = try c.decodeIfPresent(Double.self, forKey: .residentBoost) ?? 1
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
    }

    private struct RawHarmony: Decodable {
        var tint: [Double]
        var contact: Double

        var harmony: Harmony {
            Harmony(
                tint: tint.count == 3 ? PofuRGB(red: tint[0], green: tint[1], blue: tint[2]) : PofuRGB(red: 1, green: 1, blue: 1),
                contact: contact
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
