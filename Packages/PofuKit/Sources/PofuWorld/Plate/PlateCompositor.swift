import Foundation
import PofuCore
import PofuDesignSystem

/// The plate compositor (WP10; world presentation v2 §6.2): what one painted Home state draws, and in which order.
///
/// 1. The base: the plate with its stations erased where the state has one (`PlateIsland.drawnPlateArt`), else the
///    painted plate.
/// 2. The stations' looks, back to front by `footY`, each carrying its contact shade (`tools/plate/station_looks.py`
///    bakes the shade under the look).
/// 3. Props and characters, sorted with the looks by `footY`: a look stands over whatever has its feet behind the
///    look's foot and overlaps it (`looks(over:box:)`), the painted decor occluders cut as before, and a station's
///    painted occluder retires wherever its look draws (D7).
/// 4. Effects.
///
/// It is data-driven over the plate's `stations`: a station with looks and an erased base in a state draws by its
/// built level there (nothing while unbuilt, the base's empty plot), and a station without them keeps the painted
/// plate. A new station's looks and more bases are data only.
public struct PlateCompositor: Hashable, Sendable {
    /// One station's look as it stands in this state.
    public struct Look: Hashable, Sendable, Identifiable {
        public var station: String
        /// The look's number (`StationLooks.lookLevel`), 1 to the station's `levels`.
        public var look: Int
        public var art: String
        /// The look's canvas and its foot, in world units.
        public var box: WorldBox
        public var foot: WorldPoint
        /// The foot's plate y: what the look sorts by.
        public var footY: Double
        /// The state's grade where the look is painted in another light (golden's day look): the harmony tint it
        /// multiplies by. `nil` where the look is painted in the state's own light.
        public var grade: PofuRGB?

        public var id: String { station }
        public var stationID: StationID { StationID(rawValue: station) }
    }

    /// One thing in the draw list.
    public enum Piece: Hashable, Sendable {
        case base
        case look(String)
        /// A character, a prop or a decor occluder, by the caller's id.
        case item(String)
    }

    public let plate: HomePlate
    /// The Home stations' levels (`HomePlate.stationLevels`).
    public let levels: [StationID: Int]

    public init(plate: HomePlate, levels: [StationID: Int]) {
        self.plate = plate
        self.levels = levels
    }

    /// The stations this state has an erased base for, by id, sorted.
    public var stationsOnBase: [String] {
        plate.plate.stationLooks(light: plate.light, stage: plate.stage).keys.sorted()
    }

    /// The stations on this state's base, back to front by their foot (the order the composite draws them in, built or
    /// not, so a station's piece keeps its place as it is built).
    public var stationsBackToFront: [String] {
        stationsOnBase.compactMap { id in plate.plate.stations[id].map { (id, $0.place(stage: plate.stage).foot.y) } }
            .sorted { ($0.1, $0.0) < ($1.1, $1.0) }.map(\.0)
    }

    /// The looks over Pofu at `feet` (his `box`) and over every prop with a slot, once each, back to front.
    public func looks(overPofuAndProps feet: WorldPoint, box: WorldBox) -> [Look] {
        var seen = Set<String>(), result: [Look] = []
        func add(_ looks: [Look]) {
            for look in looks where seen.insert(look.station).inserted {
                result.append(look)
            }
        }
        add(looks(over: feet, box: box))
        for prop in HomeSlots.Prop.allCases {
            if let foot = plate.propSlot(prop), let propBox = plate.propBox(prop) {
                add(looks(over: foot, box: propBox))
            }
        }
        return result.sorted { ($0.footY, $0.station) < ($1.footY, $1.station) }
    }

    /// The look a station at `level` draws in this state, or `nil`: no base here, or unbuilt.
    public func look(_ station: String, level: Int) -> Look? {
        guard let art = plate.plate.lookArt(station: station, level: level, light: plate.light, stage: plate.stage),
              let looks = plate.plate.stations[station], let n = looks.lookLevel(stationLevel: level, light: plate.light),
              let frame = plate.lookFrame(station) else { return nil }
        return Look(station: station, look: n, art: art, box: frame.box, foot: frame.foot, footY: looks.place(stage: plate.stage).foot.y,
                    grade: StationLooks.lookLight(for: plate.light) == plate.light ? nil : plate.harmony.tint)
    }

    /// The looks standing on this state's base, back to front by `footY` (ties by station id).
    public var looks: [Look] {
        stationsOnBase.compactMap { id in look(id, level: levels[StationID(rawValue: id)] ?? 0) }
            .sorted { ($0.footY, $0.station) < ($1.footY, $1.station) }
    }

    /// Whether a station stands on the island in this state: `true` built over a base (its look), `false` unbuilt over
    /// a base (the base's empty plot), `nil` where the state keeps the painted station (the plate decides).
    public func presence(_ station: StationID) -> Bool? {
        guard stationsOnBase.contains(station.rawValue) else { return nil }
        return look(station.rawValue, level: levels[station] ?? 0) != nil
    }

    /// The looks that stand over a character or prop with its feet at `feet` and `box` (world units): those whose foot
    /// is in front of its feet and whose canvas overlaps it, back to front.
    public func looks(over feet: WorldPoint, box: WorldBox) -> [Look] {
        let y = plate.plate(feet).y
        return looks.filter { y < $0.footY && $0.box.overlaps(box) }
    }

    /// The draw list for this state with `items` standing on it (an id and its feet, in world units): the base, then
    /// the looks and the items back to front by their feet's plate y. At a tie the item stands in front (the occluder
    /// rule: a look covers only what is strictly behind its foot).
    public func order(items: [(id: String, feet: WorldPoint)]) -> [Piece] {
        let entries: [(y: Double, rank: Int, piece: Piece)] =
            looks.map { ($0.footY, 0, Piece.look($0.station)) } + items.map { (plate.plate($0.feet).y, 1, Piece.item($0.id)) }
        return [.base] + entries.sorted { ($0.y, $0.rank) < ($1.y, $1.rank) }.map(\.piece)
    }

    /// Whether building `station` from `from` to `to` changes the look it stands as in this state (a reveal plays).
    public func reveals(_ station: StationID, from: Int, to: Int) -> Bool {
        guard let new = look(station.rawValue, level: to) else { return false }
        return look(station.rawValue, level: from)?.art != new.art
    }

    /// The far picture's key (`FarSnapshot`): the state and the looks it draws. A build that changes no look (a
    /// station without a base here, or a level past the last look) keeps the picture.
    public var snapshotKey: SnapshotKey {
        SnapshotKey(light: plate.light, stage: plate.stage, looks: looks.map { "\($0.station):\($0.look)" })
    }

    /// The far picture's identity: stage, light and the built looks.
    public struct SnapshotKey: Hashable, Sendable, CustomStringConvertible {
        public var light: String
        public var stage: Int
        public var looks: [String]

        public var description: String {
            "\(light)-\(stage)[\(looks.joined(separator: ","))]"
        }
    }
}

extension WorldBox {
    /// Whether two boxes share any area.
    func overlaps(_ other: WorldBox) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }
}
