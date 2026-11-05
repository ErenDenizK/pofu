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
/// The home plate is the large island (`island-main-l-v3`, batch 05, the
/// same lawn as batch 03's v2 over a deeper body; look round 3): a lawn oval 480 × 87 units, 0.18 as deep as it is wide, so
/// depth, not width, limits the layout. Its slots are authored for it:
/// tall stations (the windmill, the workshop) in the back row, the low
/// pond in front, the garden and the çay ocağı at the tips, Pofu front and
/// centre with Fındık and Mochi beside their stations. Every footprint, at
/// every level, stays inside the walkable lawn and off every other
/// (`IslandFootprintTests`).
public enum IslandLayout {
    /// Pofu's feet: front and centre, a little right of the middle so the
    /// pond and the windmill stay visible beside him at Home.
    public static let pofu = WorldPoint(x: 22, y: 27)

    /// The plate's lawn as an ellipse around the origin: half-width and
    /// half-depth, measured by the pipeline (`WorldArt.generatedPlate`).
    public static var lawnRadiusX: Double { WorldArt.generatedPlate.lawnRadiusX }
    public static var lawnRadiusY: Double { WorldArt.generatedPlate.lawnRadiusY }

    /// The flat plate's rows understate distance: the camera looks down
    /// at about 17°, so one unit of y is several units of depth. Depth is
    /// y times this factor (tunable; §12.7 proposes a depth map instead).
    public static let depthPerY = 2.0

    public static func depth(ofY y: Double) -> Double {
        y * depthPerY
    }

    /// The home island's station slots: their footprint centres. Every
    /// footprint stays inside the plate's walkable polygon
    /// (`IslandFootprint`, look round 2: round 1's garden and çay ocağı hung
    /// over the rim); the test fails before a slot can stick out again.
    public static let stationAnchors: [StationID: WorldPoint] = [
        .windmill: WorldPoint(x: -50, y: -25),
        .workshop: WorldPoint(x: 61, y: -9),
        .garden: WorldPoint(x: -173, y: 6),
        .teaStall: WorldPoint(x: 154, y: 6),
        .pond: WorldPoint(x: -65, y: 23),
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
        // In front of the çay ocağı's left end, where its stools are.
        Resident(id: .mochi, station: .teaStall, feet: WorldPoint(x: 108, y: 29), art: "mochi", isStandIn: false),
        // In front of the workshop's bench, not inside its wall.
        Resident(id: .findik, station: .workshop, feet: WorldPoint(x: 76, y: 20), art: "findik", isStandIn: false),
    ]

    public static func resident(_ id: ResidentID) -> Resident? {
        residents.first { $0.id == id }
    }

    /// Whether the art for a station's level is its own (not a lower
    /// level's): where it is not, the station wears a small level badge.
    public static func hasLevelArt(_ station: StationID, level: Int) -> Bool {
        guard let art = stationArt(station, level: level) else { return false }
        return !art.isStandIn
    }

    /// How many levels of each home station the art queue has generated
    /// (batches 01, 03 and 05); `preblur.py app` bakes every one.
    public static let generatedLevels: [StationID: Int] = [
        .teaStall: 5, .garden: 5, .pond: 5, .windmill: 5, .workshop: 1,
    ]

    /// The baked sprite for a station at a level: its own level's art, or
    /// the highest level below it (`isStandIn`); `nil` when there is no art
    /// at all (a labelled placeholder is drawn).
    public static func stationArt(_ station: StationID, level: Int) -> (name: String, isStandIn: Bool)? {
        guard let generated = generatedLevels[station], generated > 0 else { return nil }
        let shown = min(max(level, 1), generated)
        return ("\(station.artStem)-\(shown)", shown != max(level, 1))
    }

    /// One depth band of the home plate.
    public struct PlateBand: Hashable, Sendable {
        public var art: String
        /// The band's depth (world y × `depthPerY`).
        public var depth: Double
    }

    /// Back lawn, middle lawn, front lawn and lip, earth body; the pipeline
    /// cuts them at −0.32, 0.32 and 1.0 of the lawn's half-depth and
    /// records each band's centre.
    public static let plateBands: [PlateBand] = WorldArt.generatedPlate.bandDepthY.enumerated().map { k, y in
        PlateBand(art: "island-main-band\(k)", depth: IslandLayout.depth(ofY: y))
    }

    /// The other islands, at fixed world positions around the home one.
    /// Yıldız, Kaplıca and Kitap are retired (game plan §2); wonder islands
    /// join here when they are built.
    public struct Isle: Hashable, Sendable, Identifiable {
        public var id: IslandID
        public var center: WorldPoint
        public var art: String
    }

    /// Around the home island, clear of the large plate (488 units
    /// wide), so the Map shows the neighbours (game design §3: the archipelago is
    /// felt, never cluttering). At the Island framing the neighbours leave
    /// the frame to the far isles of the living sky.
    public static let isles: [Isle] = [
        Isle(id: .harbor, center: WorldPoint(x: 265, y: 320), art: "harbor-island-s"),
    ]

    /// The world canvas the scene lays objects out on: x −500…500,
    /// y −700…500, with the world origin at `canvasOrigin`.
    public static let canvasWidth = 1000.0
    public static let canvasHeight = 1200.0
    public static let canvasOrigin = WorldPoint(x: 500, y: 700)

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
        // Centre the vignette's art, not a fixed height above its footprint:
        // a flat pond would otherwise sit behind the sheet.
        let focus = IslandFraming.stationBox(station)
        let lookY = focus?.midY ?? anchor.y - 46
        let pose = CameraPose(scale: scale, look: WorldPoint(x: anchor.x, y: lookY), anchorY: (top + bottom) / 2 + 8)
        guard let focus else { return pose }
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

extension StationID {
    /// The stem of this station's sprite names (`<stem>-<level>`): its id in
    /// kebab case, so `teaStall` draws `tea-stall-1`.
    var artStem: String {
        var stem = ""
        for character in rawValue {
            if character.isUppercase, !stem.isEmpty { stem.append("-") }
            stem.append(contentsOf: character.lowercased())
        }
        return stem
    }
}
