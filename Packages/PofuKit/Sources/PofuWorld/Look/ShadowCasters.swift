import Foundation
import PofuCore

/// One thing on the home lawn that grounds itself with a shadow: where it
/// stands, what silhouette it casts (if its art has one) and the ambient
/// pad under it (light and shadow v2, §2). Pure; `ShadowBake` draws it.
public struct ShadowCaster: Hashable, Sendable {
    /// How the cast shadow is drawn.
    public enum Cast: Hashable, Sendable {
        /// The baked silhouette `<art>-shadow`, over the sprite's box; the
        /// shadow is skipped when the art has none yet. `box` overrides the
        /// catalog box for art that is not a world sprite (the home props).
        case silhouette(art: String, box: WorldBox?)
        /// A soft blob of this width and height, for what has no
        /// silhouette (Pofu is the live companion view).
        case blob(width: Double, height: Double)
        /// Pad only (dressing stand-ins, the pots, water).
        case none
    }

    public var id: String
    /// The feet, or the footprint centre, in world units.
    public var anchor: WorldPoint
    public var cast: Cast
    /// The ambient pad: its centre relative to the anchor and its size.
    public var pad: WorldBox
}

public enum ShadowCasters {
    /// What the shadow layout depends on: the home stations' levels and
    /// the island level (which dresses the lawn). Cheap to compare each
    /// frame; the casters are rebuilt only when it changes.
    public struct Signature: Hashable, Sendable {
        public var levels: [StationLevel]
        public var islandLevel: Int

        public struct StationLevel: Hashable, Sendable {
            public var station: StationID
            public var level: Int
        }

        public init(stations: [StationStatus], islandLevel: Int) {
            levels = stations
                .filter { $0.island == .home && $0.isOpen && $0.level > 0 }
                .map { StationLevel(station: $0.id, level: $0.level) }
                .sorted { $0.station.rawValue < $1.station.rawValue }
            self.islandLevel = islandLevel
        }
    }

    /// Every static caster on the home lawn, back to front.
    public static func casters(for signature: Signature) -> [ShadowCaster] {
        var result: [ShadowCaster] = []
        let built = Set(signature.levels.map(\.station))
        for entry in signature.levels {
            guard let slot = IslandLayout.stationAnchors[entry.station],
                  let art = IslandLayout.stationArt(entry.station, level: entry.level)?.name else { continue }
            let footprint = IslandFootprint.footprint(of: art)
            let anchor = IslandFootprint.clamped(slot, footprint: footprint)
            let isWater = entry.station == .pond
            result.append(ShadowCaster(
                id: "station-\(entry.station.rawValue)",
                anchor: anchor,
                // Water takes no shadow and gives no pad.
                cast: isWater ? .none : .silhouette(art: art, box: nil),
                pad: isWater ? .empty : padBox(of: footprint)
            ))
        }
        for resident in IslandLayout.residents where built.contains(resident.station) {
            let footprint = IslandFootprint.footprint(of: resident.art)
            result.append(ShadowCaster(
                id: "resident-\(resident.id.rawValue)",
                anchor: IslandFootprint.clamped(resident.feet, footprint: footprint),
                cast: .silhouette(art: resident.art, box: nil),
                pad: padBox(of: footprint, minimumWidth: 20)
            ))
        }
        result.append(ShadowCaster(
            id: "pofu",
            anchor: IslandLayout.pofu,
            cast: .blob(width: ShadowTuning.pofuWidth, height: ShadowTuning.pofuHeight),
            pad: WorldBox(minX: -22, minY: -5, maxX: 22, maxY: 7)
        ))
        for piece in IslandDressing.pieces(atLevel: signature.islandLevel) {
            let size = padSize(of: piece.kind)
            result.append(ShadowCaster(
                id: "dressing-\(piece.id)",
                anchor: piece.point,
                cast: .silhouette(art: piece.kind.art, box: nil),
                pad: WorldBox(minX: -size.width / 2, minY: -size.height / 2, maxX: size.width / 2, maxY: size.height / 2)
            ))
        }
        result.append(contentsOf: props())
        return result
    }

    /// The jar, the calm lantern and the pots.
    static func props() -> [ShadowCaster] {
        let scale = IslandFraming.homeScale
        var result: [ShadowCaster] = []
        for prop in HomeSlots.Prop.allCases {
            let w = prop.homeSize.width / scale, h = prop.homeSize.height / scale
            let feet = WorldPoint(x: prop.slot.x, y: prop.slot.y + h / 2)
            let pad = WorldBox(minX: -w * 0.42, minY: -2.5, maxX: w * 0.42, maxY: 3)
            switch prop {
            case .jar:
                result.append(ShadowCaster(id: "prop-jar", anchor: feet, cast: .silhouette(art: "ui-jar-empty", box: WorldBox(minX: -w / 2, minY: -h, maxX: w / 2, maxY: 0)), pad: pad))
            case .lantern:
                result.append(ShadowCaster(id: "prop-lantern", anchor: feet, cast: .silhouette(art: "ui-lantern-off", box: WorldBox(minX: -w / 2, minY: -h, maxX: w / 2, maxY: 0)), pad: pad))
            case .pots:
                result.append(ShadowCaster(id: "prop-pots", anchor: feet, cast: .none, pad: pad))
            }
        }
        return result
    }

    /// The ambient pad of a footprint: its width, a little deeper than the
    /// footprint, centred on it.
    static func padBox(of footprint: WorldPolygon, minimumWidth: Double = 0) -> WorldBox {
        guard let b = footprint.bounds else { return WorldBox(minX: -16, minY: -4, maxX: 16, maxY: 4) }
        let w = max((b.maxX - b.minX) * 1.08, minimumWidth), d = (b.maxY - b.minY) * 1.1 + 3
        return WorldBox(minX: b.midX - w / 2, minY: b.midY - d / 2, maxX: b.midX + w / 2, maxY: b.midY + d / 2)
    }

    static func padSize(of kind: DressingKind) -> (width: Double, height: Double) {
        switch kind {
        case .grassTuft: (14, 4)
        case .wildflowers: (16, 4)
        case .pebbles: (12, 3)
        case .mushroomRing: (22, 6)
        case .wateringCan, .seedSack, .barrel: (14, 5)
        case .twine, .trowel: (10, 3)
        case .crate: (18, 6)
        case .rope: (14, 4)
        }
    }
}

extension WorldBox {
    /// A box with no extent: nothing is drawn.
    public static let empty = WorldBox(minX: 0, minY: 0, maxX: 0, maxY: 0)

    public var isEmpty: Bool { width <= 0 || height <= 0 }
}
