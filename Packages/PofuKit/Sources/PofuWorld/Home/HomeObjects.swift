import Foundation
import PofuCore

// The Living Diorama's state, as pure functions (UI direction B; UI system
// v2 §5.2). Every world object on Home (the seed jar, the calm lantern, the
// skip pots, Pofu's cheeks) shows one number through a shape; the shapes
// are drawn from the values below, so the rules are tested on any platform.

// MARK: - Cheeks

/// How full Pofu's cheek pouches look, from the seeds waiting to be
/// collected (Scale A, UI system v2 §5.2.1): 0, 1–7, 8–19 and 20 or more.
public enum CheekStep: Int, CaseIterable, Comparable, Hashable, Sendable {
    case empty
    case round
    case full
    case huge

    public init(uncollected seeds: Int) {
        switch seeds {
        case ..<1: self = .empty
        case 1..<8: self = .round
        case 8..<20: self = .full
        default: self = .huge
        }
    }

    public static func < (lhs: CheekStep, rhs: CheekStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The cheek fill the companion's pouch shader takes (`0...1`).
    public var companionEnergy: Double {
        switch self {
        case .empty: 0
        case .round: 0.3
        case .full: 0.65
        case .huge: 1
        }
    }

    /// The step below this one.
    public var lowered: CheekStep {
        CheekStep(rawValue: max(rawValue - 1, 0)) ?? .empty
    }
}

/// "Yanaklarım kocaman oldu!": at most once a day, only at the top step.
/// Home alone asks; the shield, notifications and widgets never do.
public struct CheekLineGate: Sendable {
    public var lastSpoken: Date?

    public init(lastSpoken: Date? = nil) {
        self.lastSpoken = lastSpoken
    }

    public func allows(step: CheekStep, now: Date, calendar: Calendar) -> Bool {
        guard step == .huge else { return false }
        guard let lastSpoken else { return true }
        return !calendar.isDate(lastSpoken, inSameDayAs: now)
    }

    public mutating func markSpoken(at now: Date) {
        lastSpoken = now
    }
}

/// Which of the huge-cheeks lines Pofu says on a day (`WorldStrings.cheeksHuge(variant:)`):
/// five, turned by the day like `HomeDailyLine`'s, so two days in a row never
/// share one.
public enum CheekLine {
    public static let variants = 5

    /// - Parameter dayIndex: Any day count; consecutive days differ.
    public static func variant(dayIndex: Int) -> Int {
        ((dayIndex % variants) + variants) % variants
    }
}

// MARK: - Jar

/// The seed jar's fill: a code mask over the painted jar's window.
public enum SeedJarFill {
    /// The seeds a full jar holds on screen. Seeds arrive in tens a day
    /// (founder: small numbers), so a week's savings read as a full jar.
    public static let defaultCapacity = 120
    /// A jar with any seed shows at least this much.
    public static let minimumVisible = 0.08

    /// The fill, `0...1`.
    public static func fraction(seeds: Int, capacity: Int = defaultCapacity) -> Double {
        guard seeds > 0, capacity > 0 else { return 0 }
        return min(max(Double(seeds) / Double(capacity), minimumVisible), 1)
    }
}

// MARK: - Lantern

/// The calm lantern's glow: 15 % at ×1.0 to 100 % at ×2.0.
public enum CalmLantern {
    public static let floorGlow = 0.15
    public static let lowCalm = 1.0
    public static let highCalm = 2.0

    public static func glow(calm: Double) -> Double {
        guard calm.isFinite else { return floorGlow }
        let t = min(max((calm - lowCalm) / (highCalm - lowCalm), 0), 1)
        return floorGlow + (1 - floorGlow) * t
    }
}

// MARK: - Pots

/// Today's skips as clay pots on the island's lip: one pot per reach, a
/// sunflower bloom for a skip and a closed bud for an open (shape, not only
/// colour). Past eight pots they cluster: each pot carries several reaches
/// and the count shows as a badge.
public struct SkipPots: Hashable, Sendable {
    public struct Pot: Hashable, Sendable {
        public var blooms: Int
        public var buds: Int
        /// The pot's reaches.
        public var reaches: Int { blooms + buds }
    }

    public static let maxVisible = 8

    public let pots: [Pot]
    public let reaches: Int
    public let skips: Int
    /// The bed folds at night; a fresh bed starts at dawn.
    public let isAsleep: Bool

    /// - Parameter beads: one per reach today, in order; `true` for a skip.
    public init(beads: [Bool], isAsleep: Bool = false) {
        reaches = beads.count
        skips = beads.filter { $0 }.count
        self.isAsleep = isAsleep
        let perPot = max(1, (beads.count + Self.maxVisible - 1) / Self.maxVisible)
        pots = stride(from: 0, to: beads.count, by: perPot).map { start in
            let group = beads[start..<min(start + perPot, beads.count)]
            let blooms = group.filter { $0 }.count
            return Pot(blooms: blooms, buds: group.count - blooms)
        }
    }

    /// Whether pots carry more than one reach each (the badge shows).
    public var isClustered: Bool {
        reaches > Self.maxVisible
    }
}

// MARK: - Collect beat

/// The Home objects' presentation timing, in seconds. The defaults match
/// `home.*` in `tuning.json`; the app may pass live values.
public struct HomeTiming: Hashable, Sendable {
    /// Pofu turns and presses his paws to his cheeks.
    public var pawsPress = 0.30
    /// The cheeks step down once the seeds are in flight.
    public var cheekRelease = 0.45
    /// The jar's fill rises to the new level.
    public var jarFill = 0.60
    /// The lantern's glow follows calm.
    public var lanternGlow = 1.2
    /// A pot's bloom or bud grows in.
    public var potBloom = 0.5
    /// Seeds a full jar holds.
    public var jarCapacity = Double(SeedJarFill.defaultCapacity)

    public init() {}
}

/// The cheeks during a collect: held at the pre-collect step while Pofu
/// presses his paws, then released to empty as seeds land.
public struct CheekCollectBeat: Hashable, Sendable {
    public let from: CheekStep
    public let timing: HomeTiming

    public init(from: CheekStep, timing: HomeTiming) {
        self.from = from
        self.timing = timing
    }

    /// Whether the paws are pressed to the cheeks at `t` (seconds since the
    /// tap): from the tap until the cheeks have released.
    public func pawsPressed(at t: Double) -> Bool {
        from > .empty && t >= 0 && t < timing.pawsPress + timing.cheekRelease
    }

    /// The cheek fill at `t` for the companion (`0...1`): held until the
    /// paws have pressed, then down to empty over `cheekRelease`.
    public func energy(at t: Double) -> Double {
        let start = from.companionEnergy
        guard t > timing.pawsPress else { return start }
        let p = min((t - timing.pawsPress) / max(timing.cheekRelease, 0.001), 1)
        return start * (1 - p)
    }
}

// MARK: - Layout

/// Where the objects stand, relative to Pofu's feet on screen. Pure, so the
/// collect flight lands where the jar is drawn.
public enum HomeObjectsLayout {
    public static let jarSize = (width: 62.0, height: 72.0)
    public static let lanternHeight = 96.0
    public static let potWidth = 36.0

    /// The screen gutter the Home chrome keeps (`PofuSpacing.screen`), which
    /// the collect action keeps from the edges on top of the safe area.
    public static let gutter = 16.0

    /// The jar's centre: left of Pofu, its base on the lawn, never inside
    /// the left safe area.
    public static func jarCenter(feet: MomentPoint, screenWidth: Double, leadingInset: Double = 0) -> MomentPoint {
        let margin = jarSize.width / 2 + 12 + max(0, leadingInset)
        return MomentPoint(x: max(feet.x - 100, margin), y: feet.y - 30)
    }

    /// How far the "Topla · N" action slides from under the jar so it keeps
    /// the gutter plus the safe area from both screen edges (it is wider
    /// than the jar). Zero when it already fits; on a screen too narrow for
    /// both edges, the left one wins.
    public static func collectShift(
        jarX: Double,
        actionWidth: Double = 140,
        screenWidth: Double = .infinity,
        leadingInset: Double = 0,
        trailingInset: Double = 0
    ) -> Double {
        let half = actionWidth / 2
        let lowest = gutter + max(0, leadingInset) + half
        let highest = screenWidth - gutter - max(0, trailingInset) - half
        let centre = min(max(jarX, lowest), max(highest, lowest))
        return centre - jarX
    }

    /// The lantern's centre: right of Pofu.
    public static func lanternCenter(feet: MomentPoint, screenWidth: Double) -> MomentPoint {
        let margin = 30.0
        return MomentPoint(x: min(feet.x + 102, screenWidth - margin), y: feet.y - lanternHeight / 2 + 2)
    }

    /// The centre of the pot row on the island's lip.
    public static func potsCenter(feet: MomentPoint) -> MomentPoint {
        MomentPoint(x: feet.x, y: feet.y + 55)
    }
}
