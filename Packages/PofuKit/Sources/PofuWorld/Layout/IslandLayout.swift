import Foundation
import PofuCore

/// A resident of the archipelago (interaction spec §12.2).
public struct ResidentID: RawRepresentable, Hashable, Sendable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }

    public static func < (lhs: ResidentID, rhs: ResidentID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Mochi, the bunny who keeps the çay ocağı.
    public static let mochi = ResidentID(rawValue: "mochi")
    /// Fındık, the hedgehog of the workshop.
    public static let findik = ResidentID(rawValue: "findik")
}

/// Where everything sits: the fixed slot anchors of the home island, the
/// residents, Pofu, the plate's depth bands, and the other islands on the
/// map. World units are points at camera scale 1 (game design §15).
///
/// The batch 01 plate (`island-main-s`) is a flat lawn oval about
/// 350 × 82 units, so the slots are laid out for it rather than copied
/// from the prototype's taller stand-in plate.
public enum IslandLayout {
    /// Pofu's feet.
    public static let pofu = WorldPoint(x: 6, y: 20)

    /// The plate's lawn as an ellipse: centre, half-width, half-height.
    public static let lawnRadiusX = 175.0
    public static let lawnRadiusY = 40.0

    /// The flat plate's rows understate distance: the camera looks down
    /// at about 17°, so one unit of y is several units of depth. Depth is
    /// y times this factor (tunable; §12.7 proposes a depth map instead).
    public static let depthPerY = 2.0

    public static func depth(ofY y: Double) -> Double {
        y * depthPerY
    }

    /// The home island's station slots: their footprint centres.
    public static let stationAnchors: [StationID: WorldPoint] = [
        .windmill: WorldPoint(x: -62, y: -28),
        .workshop: WorldPoint(x: 78, y: -26),
        .garden: WorldPoint(x: -118, y: 2),
        .cay: WorldPoint(x: 104, y: 6),
        // On the lawn, clear of the front lip (y 28 sat on the lip).
        .pond: WorldPoint(x: -72, y: 20),
    ]

    /// A station's tap target over its footprint (§2.7): x ± 46, y − 84
    /// to + 10.
    public static let stationHitBox = WorldBox(minX: -46, minY: -84, maxX: 46, maxY: 10)
    /// A resident's tap target, padded toward 44 pt on screen.
    public static let residentHitBox = WorldBox(minX: -16, minY: -30, maxX: 16, maxY: 4)

    public struct Resident: Hashable, Sendable, Identifiable {
        public var id: ResidentID
        public var station: StationID
        public var feet: WorldPoint
        /// The baked sprite.
        public var art: String
        /// Whether the art is a stand-in until batch 01 covers it.
        public var isStandIn: Bool
    }

    public static let residents: [Resident] = [
        Resident(id: .mochi, station: .cay, feet: WorldPoint(x: 62, y: 24), art: "mochi", isStandIn: false),
        Resident(id: .findik, station: .workshop, feet: WorldPoint(x: 34, y: -14), art: "findik-standin", isStandIn: true),
    ]

    public static func resident(_ id: ResidentID) -> Resident? {
        residents.first { $0.id == id }
    }

    /// Whether the art for a station's level is its own (not a shared
    /// stand-in): where it is not, the station wears a small level badge
    /// from level 2.
    public static func hasLevelArt(_ station: StationID, level: Int) -> Bool {
        guard let art = stationArt(station, level: level) else { return false }
        return !art.isStandIn && level == 1
    }

    /// The baked sprite for a station at a level; `nil` when there is no
    /// art at all (a labelled placeholder is drawn).
    public static func stationArt(_ station: StationID, level: Int) -> (name: String, isStandIn: Bool)? {
        switch station {
        // Only level 1 exists from batch 01; higher levels show it until
        // their edits are generated.
        case .cay: ("cay-1", level > 1)
        case .garden: ("garden-standin", true)
        case .pond: ("pond-standin", true)
        case .workshop: ("workshop-standin", true)
        case .windmill: ("windmill-standin", true)
        default: nil
        }
    }

    /// One depth band of the home plate.
    public struct PlateBand: Hashable, Sendable {
        public var art: String
        /// The band's depth (world y × `depthPerY`).
        public var depth: Double
    }

    /// Back lawn, middle lawn, front lawn and lip, earth body; the pipeline
    /// cuts them at y −14, 14 and 44.
    public static let plateBands: [PlateBand] = [
        PlateBand(art: "island-main-band0", depth: depth(ofY: -28)),
        PlateBand(art: "island-main-band1", depth: depth(ofY: 0)),
        PlateBand(art: "island-main-band2", depth: depth(ofY: 29)),
        PlateBand(art: "island-main-band3", depth: depth(ofY: 60)),
    ]

    /// The other islands, at fixed world positions around the home one.
    public struct Isle: Hashable, Sendable, Identifiable {
        public var id: IslandID
        public var center: WorldPoint
        public var art: String
    }

    /// An X around the home island, close enough that at the Island
    /// framing each neighbour's rim peeks into a corner (game design §3: the
    /// archipelago is felt, never cluttering) and the Map shows all five
    /// large.
    public static let isles: [Isle] = [
        Isle(id: .yildiz, center: WorldPoint(x: -185, y: -265), art: "isle-stars-standin"),
        Isle(id: .kaplica, center: WorldPoint(x: 200, y: -250), art: "isle-hamam-standin"),
        Isle(id: .iskele, center: WorldPoint(x: 195, y: 265), art: "isle-harbor-standin"),
        Isle(id: .kitap, center: WorldPoint(x: -205, y: 270), art: "isle-library-standin"),
    ]

    /// The world canvas the scene lays objects out on: x −400…400,
    /// y −700…500, with the world origin at `canvasOrigin`.
    public static let canvasWidth = 800.0
    public static let canvasHeight = 1200.0
    public static let canvasOrigin = WorldPoint(x: 400, y: 700)

    /// The camera framing that focuses a station with a sheet at
    /// `sheetFraction` of the height (§1.2): the station centred between
    /// the top band and the sheet's edge, at most `maxScale` (× W/402),
    /// then nudged sideways so Pofu and the residents are either whole or
    /// out of frame, never cut by an edge.
    public static func stationFocusPose(
        _ station: StationID,
        width: Double,
        height: Double,
        safeTop: Double,
        sheetFraction: Double = 0.42,
        maxScale: Double = 1.70
    ) -> CameraPose? {
        guard let anchor = stationAnchors[station] else { return nil }
        let k = width / CameraRail.referenceWidth
        let top = safeTop + 100
        let bottom = height * (1 - sheetFraction)
        let scale = min(maxScale * k, max(bottom - top, 1) * 0.62 / 112)
        let pose = CameraPose(scale: scale, look: WorldPoint(x: anchor.x, y: anchor.y - 46), anchorY: (top + bottom) / 2 + 8)
        guard let focus = IslandFraming.stationBox(station) else { return pose }
        return IslandFraming.keepingCharactersWhole(
            pose,
            focus: focus,
            subjects: IslandFraming.characterBoxes,
            width: width,
            maxDrift: width * 0.22
        )
    }

    /// The build moment's push-in (interaction spec §2.4): the sheet drops
    /// to its 132 pt compact detent and the camera comes in to ×1.95.
    public static func buildFocusPose(_ station: StationID, width: Double, height: Double, safeTop: Double) -> CameraPose? {
        stationFocusPose(
            station,
            width: width,
            height: height,
            safeTop: safeTop,
            sheetFraction: compactSheetHeight / max(height, 1),
            maxScale: 1.95
        )
    }

    /// The station sheet's compact detent, used only while building.
    public static let compactSheetHeight = 132.0

    /// The resident focus (§12.2): ×1.3 scale, 35 % of the way toward the
    /// resident from where the camera is.
    public static func residentFocusPose(_ resident: ResidentID, from pose: CameraPose) -> CameraPose? {
        guard let feet = self.resident(resident)?.feet else { return nil }
        let look = WorldPoint(
            x: pose.lookX + (feet.x - pose.lookX) * 0.35,
            y: pose.lookY + (feet.y - 12 - pose.lookY) * 0.35
        )
        // Keep the resident's screen row where it was, scaled.
        return CameraPose(logScale: pose.logScale + log(1.3), lookX: look.x, lookY: look.y, anchorY: pose.anchorY)
    }
}
