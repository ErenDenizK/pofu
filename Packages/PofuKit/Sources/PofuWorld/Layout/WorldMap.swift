import Foundation
import PofuCore

/// What a slot on the Map holds, in order of the player's progress (v2 section 1.3): a
/// plain cloud tower (not yet announced), a veiled tower with the island's silhouette
/// inside (next to open), the island. The Map draws a tower only for the slot next to open and
/// nothing for one not yet announced (`MapSlots.Slot.showsTower`).
public enum SlotState: String, Codable, Hashable, Sendable {
    case cloud
    case veiled
    case island
}

/// The Map's composition as data (`world-map.json`; D5 of
/// docs/design/world-presentation-build-spec.md): where the islands sit, the tier pitch, the
/// frame fits and what each slot holds at each stage. World units, origin = Home's box
/// centre, +y down. Pure: no view reads this until the Map is rebuilt on it (WP6).
public struct WorldMap: Sendable {
    /// One place on the Map: Home, a tier-1 island or a tier-2 slot.
    public struct Slot: Sendable {
        public var id: String
        public var tier: Int
        public var center: WorldPoint
        /// The island's box in world units (`width`, `height`).
        public var width: Double
        public var height: Double
        /// The name chip's size in points; `nil` for a slot that has no island yet.
        public var chip: (width: Double, height: Double)?
    }

    /// A box with an id: a backdrop feature or a piece of chrome, in reference points.
    public struct Piece: Sendable {
        public var id: String
        public var box: ScreenBox
    }

    public let unitsPerPlatePoint: Double
    public let slots: [Slot]
    public let tierPitch: Double
    public let towerWidth: Double
    public let towerHeight: Double
    public let chipHeight: Double
    public let chipGap: Double
    public let footFraction: Double
    public let fitMinX: Double
    public let fitMaxX: Double
    public let fitMinY: Double
    public let minScale: Double
    /// The horizon as a share of the screen height.
    public let horizon: Double
    /// The widest sky band no slot owns at tier 1 (y, in points).
    public let backdropLane: ClosedRange<Double>
    public let lipTop: Double
    public let midLipTop: Double
    public let mapFeatures: [Piece]
    public let midFeatures: [Piece]
    public let midFitWidth: Double
    public let midCenterY: Double
    public let nearRestScale: Double
    public let nearLimitScale: Double
    public let nearFeetY: Double
    public let nearFeetX: Double
    public let midChrome: [Piece]
    public let mapCorner: Piece
    public let nearBack: Piece
    private let stages: [Int: [String: SlotState]]
    private let tier2States: [SlotState]

    // MARK: - Reading

    /// The slot ids in `Slot.id`: Home, the tier-1 islands, the tier-2 places.
    public func slot(_ id: String) -> Slot? {
        slots.first { $0.id == id }
    }

    public var home: Slot { slots[0] }

    /// What a slot holds at a stage of the tier-1 frame (1: Koke veiled, Çağlayan a tower;
    /// 2: Koke open, Çağlayan veiled; 3: both open). Home is always the island; tier-2 places
    /// hold their first state until their tier opens.
    public func state(of id: String, stage: Int) -> SlotState {
        guard let slot = slot(id) else { return .cloud }
        if slot.tier == 0 { return .island }
        if slot.tier == 1 {
            return stages[min(max(stage, 1), 3)]?[id] ?? .cloud
        }
        let tier2 = slots.filter { $0.tier == 2 }
        let index = tier2.firstIndex { $0.id == id } ?? 0
        return tier2States.indices.contains(index) ? tier2States[index] : .cloud
    }

    /// The centre of an island's slot, in world units; `nil` for an island that has no slot
    /// on the Map (the harbor is a stop of Home's, not a place of its own).
    public func center(of island: IslandID) -> WorldPoint? {
        slot(island.rawValue)?.center
    }

    // MARK: - Frames

    /// The tier's frame (v2 section 1.3), in the points of a screen `size`: Home's foot at
    /// 0.80 of the height, the constellation of every slot of the tier and the tiers below it
    /// between x 16 and 386 (scaled by width) and below y 84, scale the smaller of the two
    /// fits and at least 0.45 pt per unit (scaled by width). Tier 1 serves from day 1 until
    /// Çağlayan blooms; tier 2 is the next frame. The look point is on the constellation's
    /// horizontal middle and the anchor is the screen's middle row, so the stop reads like
    /// the rail's: `CameraPose(scale:look:anchorY:)` in `size`'s own points.
    public func tierFrame(tier: Int, size: CGSize) -> CameraRail.Stop {
        let width = Double(size.width), height = Double(size.height)
        let sc = width / ScreenBands.referenceWidth
        let members = slots.filter { $0.tier <= max(tier, 1) }
        let minWX = members.map { $0.center.x - $0.width / 2 }.min() ?? 0
        let maxWX = members.map { $0.center.x + $0.width / 2 }.max() ?? 0
        let topWY = members.map { $0.center.y - $0.height / 2 }.min() ?? 0
        let footWY = home.height / 2
        let foot = footFraction * height
        let fitX = (fitMaxX - fitMinX) * sc / max(maxWX - minWX, 1)
        let fitY = (foot - fitMinY) / max(footWY - topWY, 1)
        let scale = max(min(fitX, fitY), minScale * sc)
        let lookX = (minWX + maxWX) / 2
        let anchorY = height / 2
        let lookY = footWY - (foot - anchorY) / scale
        return CameraRail.Stop(scale: scale, look: WorldPoint(x: lookX, y: lookY), anchorY: anchorY)
    }

    /// The tier frame on the 402 x 874 reference.
    public func tierFrame(tier: Int) -> CameraRail.Stop {
        tierFrame(tier: tier, size: CGSize(width: ScreenBands.referenceWidth, height: ScreenBands.referenceHeight))
    }
}

// MARK: - Loading

extension WorldMap {
    /// The map shipped in the package.
    public static let shipped: WorldMap? = {
        let url = Bundle.module.url(forResource: "world-map", withExtension: "json")
            ?? Bundle.module.url(forResource: "world-map", withExtension: "json", subdirectory: "Plates")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }()

    private struct File: Decodable {
        struct Home: Decodable { var box: [Double]; var chip: [Double] }
        struct Island: Decodable { var tier: Int; var center: [Double]; var box: [Double]; var chip: [Double] }
        struct Tier2: Decodable { var id: String; var center: [Double]; var box: [Double] }
        struct SlotArt: Decodable { var towerWidth: Double; var towerHeight: Double }
        struct Chip: Decodable { var height: Double; var gap: Double }
        struct Frame: Decodable { var footFraction: Double; var minX: Double; var maxX: Double; var minY: Double; var minScale: Double }
        struct PieceFile: Decodable { var id: String; var box: [Double] }
        struct Backdrop: Decodable { var lane: [Double]; var lipTop: Double; var map: [PieceFile]; var mid: [PieceFile]; var midLipTop: Double }
        struct Mid: Decodable { var fitWidth: Double; var centerY: Double }
        struct Near: Decodable { var restScale: Double; var limitScale: Double; var feetY: Double; var feetX: Double }
        struct Chrome: Decodable { var mid: [PieceFile]; var mapCorner: PieceFile; var nearBack: PieceFile }
        var unitsPerPlatePoint: Double
        var home: Home
        var islands: [String: Island]
        var tier2: [Tier2]
        var tierPitch: Double
        var slotArt: SlotArt
        var stages: [String: [String: SlotState]]
        var tier2States: [SlotState]
        var chip: Chip
        var frame: Frame
        var horizon: Double
        var backdrop: Backdrop
        var mid: Mid
        var near: Near
        var chrome: Chrome
    }

    /// Decodes the JSON `world-map.json` holds.
    static func decode(_ data: Data) throws -> WorldMap {
        let f = try JSONDecoder().decode(File.self, from: data)
        func piece(_ p: File.PieceFile) -> Piece { Piece(id: p.id, box: ScreenBox(p.box)) }
        var slots = [Slot(
            id: IslandID.home.rawValue, tier: 0, center: WorldPoint(x: 0, y: 0),
            width: f.home.box[0], height: f.home.box[1], chip: (f.home.chip[0], f.home.chip[1])
        )]
        for (id, island) in f.islands.sorted(by: { $0.value.center[1] > $1.value.center[1] }) {
            slots.append(Slot(
                id: id, tier: island.tier, center: WorldPoint(x: island.center[0], y: island.center[1]),
                width: island.box[0], height: island.box[1], chip: (island.chip[0], island.chip[1])
            ))
        }
        for place in f.tier2 {
            slots.append(Slot(
                id: place.id, tier: 2, center: WorldPoint(x: place.center[0], y: place.center[1]),
                width: place.box[0], height: place.box[1], chip: nil
            ))
        }
        let stages = Dictionary(uniqueKeysWithValues: f.stages.compactMap { key, value in Int(key).map { ($0, value) } })
        return WorldMap(
            unitsPerPlatePoint: f.unitsPerPlatePoint, slots: slots, tierPitch: f.tierPitch,
            towerWidth: f.slotArt.towerWidth, towerHeight: f.slotArt.towerHeight,
            chipHeight: f.chip.height, chipGap: f.chip.gap,
            footFraction: f.frame.footFraction, fitMinX: f.frame.minX, fitMaxX: f.frame.maxX, fitMinY: f.frame.minY,
            minScale: f.frame.minScale, horizon: f.horizon,
            backdropLane: f.backdrop.lane[0] ... f.backdrop.lane[1], lipTop: f.backdrop.lipTop, midLipTop: f.backdrop.midLipTop,
            mapFeatures: f.backdrop.map.map(piece), midFeatures: f.backdrop.mid.map(piece),
            midFitWidth: f.mid.fitWidth, midCenterY: f.mid.centerY,
            nearRestScale: f.near.restScale, nearLimitScale: f.near.limitScale, nearFeetY: f.near.feetY, nearFeetX: f.near.feetX,
            midChrome: f.chrome.mid.map(piece), mapCorner: piece(f.chrome.mapCorner), nearBack: piece(f.chrome.nearBack),
            stages: stages, tier2States: f.tier2States
        )
    }
}
