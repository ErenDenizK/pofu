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

/// Simit the kitten's three poses (art on one canvas, so they swap in place).
public enum SimitPose: String, CaseIterable, Sendable {
    /// Waiting at the cart.
    case rest = "simit-kitten"
    /// Holding a bagel: the cart is open.
    case work = "simit-kitten-work"
    /// Hands over her ears, eyes shut, delighted: Pofu's calm ring is full.
    case ears = "simit-kitten-ears"

    public var art: String { rawValue }

    /// A placeholder rule until the harbor has its own beats: joy first, then the cart's state.
    public static func pose(bagelCartLevel: Int, calmIsFull: Bool) -> SimitPose {
        if calmIsFull { return .ears }
        return bagelCartLevel >= 1 ? .work : .rest
    }
}

extension IslandLayout {
    /// Standing on the harbor's lawn: the goat toward the left, Simit by the pier where the cart goes.
    public static let islandCast: [IslandCastMember] = [
        IslandCastMember(id: "goat", island: .harbor, offset: WorldPoint(x: -52, y: -22), art: "harbor-goat"),
        IslandCastMember(id: "simit", island: .harbor, offset: WorldPoint(x: 40, y: -15), art: SimitPose.rest.art),
    ]

    public static func cast(on island: IslandID) -> [IslandCastMember] {
        islandCast.filter { $0.island == island }
    }
}
