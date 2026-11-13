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

/// Where a small tailed bubble (the greeting's heart, a gift's tag) sits
/// on screen: centred over the thing it points at, kept inside the side
/// gutter, its tail moved along its bottom edge to keep pointing at it.
public enum TailedBubblePlacement {
    /// - Returns: the bubble's centre x and its tail's offset from that
    ///   centre, in points.
    public static func place(
        tipX: Double, width: Double, screenWidth: Double,
        gutter: Double = 16, corner: Double = 13, tailWidth: Double = 10
    ) -> (centreX: Double, tailOffset: Double) {
        let half = width / 2
        let low = gutter + half, high = screenWidth - gutter - half
        let centre = low <= high ? min(max(tipX, low), high) : screenWidth / 2
        let limit = max(half - corner - tailWidth / 2, 0)
        return (centre, min(max(tipX - centre, -limit), limit))
    }
}

/// Where Home's small bubbles stand (the greeting's heart, the gift tags),
/// so they never cover one another and cover as little of the stations'
/// art as they can (critics, d10 at 23:00: the moss tag sat on the heart
/// and over the tea stall). The heart keeps its spot over the visitor; each
/// tag then takes the first of its spots that clears what is already
/// placed and the stations: over its gift, over it on a longer stem, or
/// under it with the tail pointing up. Pure, in screen points.
public enum HomeBubbleLayout {
    public struct Rect: Hashable, Sendable {
        public var minX: Double
        public var minY: Double
        public var maxX: Double
        public var maxY: Double

        public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
            self.minX = min(minX, maxX)
            self.minY = min(minY, maxY)
            self.maxX = max(minX, maxX)
            self.maxY = max(minY, maxY)
        }

        /// The area the two share, in square points.
        public func overlap(_ other: Rect) -> Double {
            let w = min(maxX, other.maxX) - max(minX, other.minX)
            let h = min(maxY, other.maxY) - max(minY, other.minY)
            return w > 0 && h > 0 ? w * h : 0
        }
    }

    public struct Placement: Hashable, Sendable {
        /// The bubble's body (without its tail).
        public var body: Rect
        /// The tail's offset from the body's centre, along its edge.
        public var tailOffset: Double
        /// The bubble hangs under what it names, its tail pointing up.
        public var isBelow: Bool
        /// The tail's length, from the body's edge to its tip.
        public var tail: Double

        public var centreX: Double { (body.minX + body.maxX) / 2 }
        public var centreY: Double { (body.minY + body.maxY) / 2 }
        /// The whole bubble with its tail, for a view that draws both.
        public var frame: Rect {
            isBelow
                ? Rect(minX: body.minX, minY: body.minY - tail, maxX: body.maxX, maxY: body.maxY)
                : Rect(minX: body.minX, minY: body.minY, maxX: body.maxX, maxY: body.maxY + tail)
        }
    }

    /// A bubble over (or under) `tip`, kept inside the side gutter.
    public static func bubble(
        tipX: Double, tipY: Double, width: Double, height: Double, tail: Double,
        screenWidth: Double, below: Bool = false, shift: Double = 0, corner: Double = 13, tailWidth: Double = 10
    ) -> Placement {
        // The body moves by `shift`; the tail keeps pointing at the tip.
        let place = TailedBubblePlacement.place(tipX: tipX + shift, width: width, screenWidth: screenWidth, corner: corner, tailWidth: tailWidth)
        let limit = max(width / 2 - corner - tailWidth / 2, 0)
        let top = below ? tipY + tail : tipY - tail - height
        return Placement(
            body: Rect(minX: place.centreX - width / 2, minY: top, maxX: place.centreX + width / 2, maxY: top + height),
            tailOffset: min(max(tipX - place.centreX, -limit), limit),
            isBelow: below,
            tail: tail
        )
    }

    /// Longer stems a tag may stand on to clear what is under it.
    public static let stems: [Double] = [0, 22, 44]
    /// Covering another bubble costs this many times covering art.
    static let bubbleWeight = 12.0
    /// What a longer stem and a hanging tag cost, in square points of art.
    static let stemCost = 14.0
    static let belowCost = 260.0
    /// A tag may slide sideways by this share of its width, its tail still
    /// on the gift, at this cost per point.
    static let shiftFractions: [Double] = [0, 0.15, 0.3, 0.45]
    static let shiftCost = 4.0
    /// A hanging tag may also sit lower, on a longer stem, to clear art.
    static let belowStems: [Double] = [0, 12, 24]
    /// Clear air kept around painted art: a tag that only touches a rim
    /// still reads as sitting on it.
    static let artMargin = 4.0

    /// A gift tag's spot: `over` is just above the gift, `under` just below
    /// its foot; `placed` are the bubbles already standing (the heart, the
    /// other tags) and `stations` the built stations' art.
    public static func tag(
        over: (x: Double, y: Double), under: (x: Double, y: Double),
        width: Double, height: Double, tail: Double, screenWidth: Double,
        placed: [Rect], stations: [Rect], topLimit: Double = 120
    ) -> Placement {
        var candidates: [(Placement, Double)] = []
        let shifts = shiftFractions.flatMap { $0 == 0 ? [0.0] : [$0 * width, -$0 * width] }
        let art = stations.map { Rect(minX: $0.minX - artMargin, minY: $0.minY - artMargin, maxX: $0.maxX + artMargin, maxY: $0.maxY + artMargin) }
        for shift in shifts {
            let moved = abs(shift) * shiftCost
            for stem in stems {
                let p = bubble(tipX: over.x, tipY: over.y, width: width, height: height, tail: tail + stem, screenWidth: screenWidth, shift: shift)
                candidates.append((p, stem * stemCost + moved))
            }
            for stem in belowStems {
                let hanging = bubble(tipX: under.x, tipY: under.y, width: width, height: height, tail: tail + stem, screenWidth: screenWidth, below: true, shift: shift)
                candidates.append((hanging, belowCost + stem * stemCost + moved))
            }
        }
        var best: (Placement, Double)?
        for (p, base) in candidates {
            let frame = p.frame
            var cost = base
            cost += placed.reduce(0) { $0 + bubbleWeight * frame.overlap($1) }
            cost += art.reduce(0) { $0 + frame.overlap($1) }
            // Under the top bar a bubble is lost.
            if p.body.minY < topLimit { cost += (topLimit - p.body.minY) * width * bubbleWeight }
            if best == nil || cost < best!.1 { best = (p, cost) }
        }
        return best!.0
    }

    /// A rough width for a gift tag of `characters` letters (icon, gaps
    /// and padding included), before the view measures itself.
    public static func tagWidth(characters: Int) -> Double {
        10 + 12 + 5 + Double(characters) * 7.6 + 10
    }
}
