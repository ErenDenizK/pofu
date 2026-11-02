import Foundation

/// The collect moment (design review 01 timing; interaction spec §6.1):
/// seeds leave the stations on arcs and land in the seed pill, whose
/// counter rolls up to the new total and pops.
///
/// The model has already committed (`WorldClock.collect`); this is only
/// presentation, a pure function of time since the tap.
///
/// | t | What happens |
/// |---|---|
/// | 0 | Tap: soft impact 0.5. Seed *i* launches at 35 ms × *i* (at most 24 seeds) |
/// | launch + 0.62 s | Seed *i* lands; at most ten landings tick (`.selection`) |
/// | first landing → last (≤ 1.0 s) | The counter rolls, monospaced |
/// | last landing | The pill pops; `.success` |
/// | + 1.2 s | The moment ends; the visit moves on |
///
/// With Reduce Motion there are no flights: the counter cross-fades to the
/// new total in 200 ms and `.success` plays.
public struct CollectMoment: Hashable, Sendable {
    public enum Cue: Int, Hashable, Sendable, Comparable {
        case tick
        case success
        case end

        public static func < (lhs: Cue, rhs: Cue) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public static let flight = 0.62
    public static let stagger = 0.035
    public static let maxSeeds = 24
    public static let maxCounterRoll = 1.0
    /// The counter rolls for at least this long, even for a few seeds.
    public static let minCounterRoll = 0.3
    public static let maxTicks = 10
    /// How long the pill stays after the pop.
    public static let hold = 1.2
    public static let reducedFade = 0.2

    /// Seeds collected.
    public let total: Int
    /// The jar before the collect.
    public let jarBefore: Int
    /// Where seeds leave from: the stations' and Pofu's screen points.
    public let sources: [MomentPoint]
    /// The pill's centre.
    public let target: MomentPoint
    public let reduceMotion: Bool

    public init(total: Int, jarBefore: Int, sources: [MomentPoint], target: MomentPoint, reduceMotion: Bool) {
        self.total = max(total, 0)
        self.jarBefore = max(jarBefore, 0)
        self.sources = sources.isEmpty ? [target] : sources
        self.target = target
        self.reduceMotion = reduceMotion
    }

    public var jarAfter: Int {
        jarBefore + total
    }

    /// Seeds drawn in flight: one per seed collected, at most 24.
    public var seedCount: Int {
        reduceMotion ? 0 : min(Self.maxSeeds, total)
    }

    public func launch(of index: Int) -> Double {
        Double(index) * Self.stagger
    }

    public func landing(of index: Int) -> Double {
        launch(of: index) + Self.flight
    }

    /// When the counter starts rolling: the first landing.
    public var counterStart: Double {
        reduceMotion || seedCount == 0 ? 0 : Self.flight
    }

    /// When the counter lands on the new total and the pill pops.
    public var counterEnd: Double {
        if reduceMotion || seedCount == 0 {
            return Self.reducedFade
        }
        let roll = Double(seedCount - 1) * Self.stagger
        return counterStart + min(Self.maxCounterRoll, max(Self.minCounterRoll, roll))
    }

    public var duration: Double {
        counterEnd + Self.hold
    }

    /// The pill's count at `t`.
    public func counter(at t: Double) -> Int {
        if reduceMotion || seedCount == 0 {
            return t >= Self.reducedFade / 2 ? jarAfter : jarBefore
        }
        let p = MomentCurves.progress(t, from: counterStart, length: counterEnd - counterStart)
        if p >= 1 {
            return jarAfter
        }
        // Ease out: most of the count arrives with the first seeds.
        return jarBefore + Int((Double(total) * MomentCurves.easeOut(p)).rounded(.down))
    }

    /// The pill's pop at `t`: its scale (1 at rest), a `pop` spring from
    /// ×1.18 when the counter lands.
    public func pillScale(at t: Double) -> Double {
        guard !reduceMotion, t >= counterEnd else { return 1 }
        return 1 + 0.18 * MomentCurves.springRemaining(t - counterEnd, duration: 0.55, bounce: 0.5)
    }

    /// Seed `index` in flight at `t`, in screen points; `nil` before it
    /// launches and after it lands.
    public func seed(_ index: Int, at t: Double) -> MomentParticle? {
        guard index >= 0, index < seedCount else { return nil }
        let u = (t - launch(of: index)) / Self.flight
        guard u >= 0, u < 1 else { return nil }
        let from = sources[index % sources.count]
        // A toss: up first, then down into the pill. Alternate seeds arc a
        // little higher so the stream reads as many seeds, not one line.
        let lift = 90 + Double(index % 3) * 26
        let control = MomentPoint(
            x: (from.x + target.x) / 2 + Double(index % 2 == 0 ? -18 : 18),
            y: min(from.y, target.y) - lift
        )
        let e = MomentCurves.smoothstep(u)
        let a = 1 - e
        let x = a * a * from.x + 2 * a * e * control.x + e * e * target.x
        let y = a * a * from.y + 2 * a * e * control.y + e * e * target.y
        let scale = (1 + 0.25 * sin(Double.pi * u)) * (1 - 0.35 * u)
        let opacity = u < 0.9 ? 1 : (1 - u) / 0.1
        let spin = (index % 2 == 0 ? 1.0 : -1.0) * 200 * u
        return MomentParticle(x: x, y: y, scale: scale, opacity: opacity, rotation: spin)
    }

    /// The landings that tick: at most ten, spread over the stream.
    public var tickTimes: [Double] {
        let n = seedCount
        guard n > 0 else { return [] }
        let count = min(n, Self.maxTicks)
        if count == 1 {
            return [landing(of: 0)]
        }
        var indices: [Int] = []
        for k in 0..<count {
            let index = Int((Double(k) * Double(n - 1) / Double(count - 1)).rounded())
            if indices.last != index {
                indices.append(index)
            }
        }
        return indices.map(landing(of:))
    }

    /// The cues in `(after, through]`, in time order.
    public func cues(after start: Double, through end: Double) -> [Cue] {
        var timed: [(Double, Cue)] = tickTimes.map { ($0, .tick) }
        timed.append((counterEnd, .success))
        timed.append((duration, .end))
        return timed
            .filter { $0.0 > start && $0.0 <= end }
            .sorted { ($0.0, $0.1) < ($1.0, $1.1) }
            .map { $0.1 }
    }

    /// Every cue time, for scheduling.
    public var cueTimes: [Double] {
        (tickTimes + [counterEnd, duration]).sorted()
    }
}
