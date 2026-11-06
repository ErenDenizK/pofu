import PofuCore

/// The residents of the other islands, standing on their plates (vertical slice: the harbor's goat and
/// Simit at the bagel cart). Pure data and rules, so they are tested on any platform.
public struct IslandCastMember: Hashable, Sendable, Identifiable {
    public var id: String
    public var island: IslandID
    /// Feet, in world units from the island's centre.
    public var offset: WorldPoint
    /// The baked sprite (Simit's pose is chosen by `SimitPose`).
    public var art: String
}

/// Simit the kitten's poses (art on one canvas, so they swap in place).
public enum SimitPose: String, CaseIterable, Sendable {
    /// Waiting at the cart.
    case rest = "simit-kitten"
    /// Holding a bagel: the cart is open.
    case work = "simit-kitten-work"
    /// Hands over her ears, eyes shut, delighted: Pofu's calm ring is full.
    case ears = "simit-kitten-ears"
    /// Beaming: the cart is busy.
    case happy = "simit-happy"
    /// Eyes shut, ears folded down: it is bedtime.
    case sleepy = "simit-sleepy"
    /// Wide-eyed: the cart has just grown.
    case surprised = "simit-surprised"

    public var art: String { rawValue }

    /// The cart level from which Simit beams instead of holding a bagel.
    public static let happyCartLevel = 3

    /// A placeholder rule until the harbor has its own beats: a start (the cart growing) first, then joy,
    /// then sleep, then the cart's state.
    public static func pose(bagelCartLevel: Int, calmIsFull: Bool, isBedtime: Bool = false, isStartled: Bool = false) -> SimitPose {
        if isStartled { return .surprised }
        if calmIsFull { return .ears }
        if isBedtime { return .sleepy }
        if bagelCartLevel >= happyCartLevel { return .happy }
        return bagelCartLevel >= 1 ? .work : .rest
    }
}

/// The goat's poses (art on one canvas, so they swap in place).
public enum GoatPose: String, CaseIterable, Sendable {
    /// Standing on the dock.
    case rest = "harbor-goat"
    /// Holding a coil of coral rope: the pier is going up.
    case work = "goat-work"

    public var art: String { rawValue }

    /// The goat coils rope from the first pier level on.
    public static func pose(pierLevel: Int) -> GoatPose {
        pierLevel >= 1 ? .work : .rest
    }
}

extension IslandLayout {
    /// Standing on the harbor's lawn: the goat toward the left, Simit in front of the cart's slot.
    public static let islandCast: [IslandCastMember] = [
        IslandCastMember(id: "goat", island: .harbor, offset: WorldPoint(x: -52, y: -10), art: "harbor-goat"),
        IslandCastMember(id: "simit", island: .harbor, offset: WorldPoint(x: -10, y: -2), art: SimitPose.rest.art),
    ]

    public static func cast(on island: IslandID) -> [IslandCastMember] {
        islandCast.filter { $0.island == island }
    }
}

/// One baked sprite standing on an island that is not Home, in world units from the island's centre.
public struct IslandPiece: Hashable, Sendable, Identifiable {
    public var id: String
    public var art: String
    /// The footprint centre (a station's slot) or the feet (a prop).
    public var offset: WorldPoint
}

extension IslandLayout {
    /// The harbor's station slots: footprint centres from the island's centre. The cart stands on the lawn,
    /// the lighthouse at its left end, and the first pier carries on past the plate's own planks.
    public static let harborStationSlots: [StationID: WorldPoint] = [
        .bagelCart: WorldPoint(x: 12, y: -16),
        .lighthouse: WorldPoint(x: -98, y: -16),
        .pier: WorldPoint(x: 158, y: -8),
    ]

    /// Dressing that comes with a harbor station once it is built (each baked at a fraction of a
    /// station's size, `HARBOR_PROPS` in `preblur.py`): the crates and the bell on a post (home layout L4,
    /// at the bridge's harbor end) by the cart, the bench by the
    /// lighthouse, the lamp and the horn on the plate's pier, the little ferry alongside the new planks
    /// (it is the pier's level 3 sprite that will show it moored).
    public static let harborProps: [(station: StationID, piece: IslandPiece)] = [
        (.bagelCart, IslandPiece(id: "crates", art: "harbor-crates-1", offset: WorldPoint(x: -22, y: -32))),
        (.bagelCart, IslandPiece(id: "bell", art: "harbor-bell", offset: WorldPoint(x: -82, y: -5))),
        (.lighthouse, IslandPiece(id: "bench", art: "decor-bench", offset: WorldPoint(x: -66, y: -30))),
        (.pier, IslandPiece(id: "horn", art: "harbor-horn-1", offset: WorldPoint(x: 62, y: -4))),
        (.pier, IslandPiece(id: "lamp", art: "harbor-lamp-1", offset: WorldPoint(x: 98, y: -12))),
        (.pier, IslandPiece(id: "ferry", art: "harbor-ferry-1", offset: WorldPoint(x: 162, y: 24))),
    ]

    /// What stands on `island` besides its plate and cast, back to front: each built station at its level's
    /// art (the highest generated one below its level stands in) and the dressing of the built ones.
    /// `levels` is every station's built level.
    public static func scenery(on island: IslandID, levels: [StationID: Int]) -> [IslandPiece] {
        guard island == .harbor else { return [] }
        var pieces: [IslandPiece] = []
        for (station, slot) in harborStationSlots {
            guard let level = levels[station], level > 0, let art = stationArt(station, level: level)?.name else { continue }
            pieces.append(IslandPiece(id: "station-\(station)", art: art, offset: slot))
        }
        for (station, piece) in harborProps where (levels[station] ?? 0) > 0 {
            pieces.append(piece)
        }
        return pieces.sorted { ($0.offset.y, $0.id) < ($1.offset.y, $1.id) }
    }
}
