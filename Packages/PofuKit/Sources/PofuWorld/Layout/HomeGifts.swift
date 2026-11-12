import Foundation
import PofuCore

/// The wonder islands' gifts at home, and the small paper tag that names a
/// gift on the day it arrives (rehearsal feedback: receiving a gift answers
/// visibly). Pure, so the rule is tested on any platform; the scene draws
/// the tag in screen space so it stays readable at Home's framing.
public enum HomeGifts {
    public enum Gift: String, CaseIterable, Hashable, Sendable {
        /// Koke's moss on the home lawn.
        case kokeMoss
        /// Çağlayan's fountain at the pond.
        case caglayanFountain
    }

    /// The gifts that stand at home: Koke's moss once Koke is healed,
    /// Çağlayan's fountain once Çağlayan is healed and the pond is built.
    public static func shown(in world: WorldSnapshot) -> [Gift] {
        var gifts: [Gift] = []
        if world.koke.giftUnlocked { gifts.append(.kokeMoss) }
        if world.caglayan.giftUnlocked, (world.stations.first { $0.id == .pond }?.level ?? 0) > 0 {
            gifts.append(.caglayanFountain)
        }
        return gifts
    }

    /// The gifts home labels today: those that arrived today (the island
    /// healed today). From tomorrow they stand unlabelled.
    public static func tagged(in world: WorldSnapshot) -> [Gift] {
        shown(in: world).filter { gift in
            switch gift {
            case .kokeMoss: world.koke.giftIsNew
            case .caglayanFountain: world.caglayan.giftIsNew
            }
        }
    }

    /// How far over the gift's foot its tag stands, in the gift's own
    /// units: the moss is about 34 tall, the fountain's jet about 50.
    public static func tagLift(_ gift: Gift) -> Double {
        switch gift {
        case .kokeMoss: 44
        case .caglayanFountain: 62
        }
    }
}
