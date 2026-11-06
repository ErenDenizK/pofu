import Foundation
import PofuCore

/// The residents' small life while the island is awake: a deterministic
/// loop per resident, seeded by the day, so the same day always plays the
/// same way and the tests can pin it.
///
/// One *cycle* is `cycleSeconds` long (the length of a look visit). Each
/// resident, each cycle, either works a beat at the station (two poses
/// alternating, plus a tiny bob), or takes a short walk out to a point on
/// the lawn and back (at most `walkSeconds` each way, ease in and out, a
/// soft hop at each end). Everyone breathes and glances about in between.
/// The loop always ends where it began, so when the frames stop (Settled,
/// 0 Hz) the residents are at their rest spot in their rest pose.
///
/// Pure value maths: the scene feeds it a time and reads a `Step`.
public enum ResidentLife {
    /// A cycle, in seconds. Walks out and back always finish inside it.
    public static let cycleSeconds = 8.0
    /// The longest one-way walk, seconds.
    public static let walkSeconds = 2.6
    /// At most this many residents walk at the same moment.
    public static let maxMovers = 2
    /// A reaction (tap, greeting) lasts this long, with a tiny hop.
    public static let reactionSeconds = 1.2

    /// Who the loop runs for: an id and where they stand.
    public struct Spec: Hashable, Sendable {
        public var id: String
        public var home: WorldPoint

        public init(id: String, home: WorldPoint) {
            self.id = id
            self.home = home
        }
    }

    /// What a resident does this cycle.
    public enum Activity: Hashable, Sendable {
        /// Breathes, glances about.
        case idle
        /// Works at the station from `start` for `seconds`.
        case work(start: Double, seconds: Double)
        /// Walks to `target` and back: out at `start`, lingers, returns.
        case walk(target: WorldPoint, start: Double, seconds: Double, linger: Double)
    }

    public struct Plan: Hashable, Sendable {
        public var spec: Spec
        public var activity: Activity
        /// Where a glance (idle) happens, seconds into the cycle.
        public var glanceAt: Double
        /// Whether the walk ends near Pofu: a greeting at the far point.
        public var greetsPofu: Bool
    }

    /// One frame of a resident: an offset from the rest spot in world
    /// units, a hop height, a lean in degrees, the pose and the breath.
    public struct Step: Hashable, Sendable {
        public var dx = 0.0
        public var dy = 0.0
        /// World units off the ground.
        public var hop = 0.0
        /// Degrees, positive leaning right.
        public var lean = 0.0
        /// 1.0 at rest; breathes up to 1.012.
        public var breath = 1.0
        public var pose: ResidentPose = .rest
        /// Walking toward the left of the screen.
        public var facesLeft = false
        public var isWalking = false

        public static let rest = Step()
        public var isRest: Bool { self == .rest }
    }

    // MARK: - Seeding

    /// A small, platform-independent generator (SplitMix64).
    struct Generator {
        var state: UInt64

        init(seed: UInt64) { state = seed }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        /// A value in `0..<1`.
        mutating func unit() -> Double {
            Double(next() >> 11) / Double(1 << 53)
        }

        mutating func value(in range: ClosedRange<Double>) -> Double {
            range.lowerBound + unit() * (range.upperBound - range.lowerBound)
        }
    }

    /// The seed of one resident's one cycle.
    static func seed(day: Int, cycle: Int, id: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for scalar in id.unicodeScalars {
            hash = (hash ^ UInt64(scalar.value)) &* 1_099_511_628_211
        }
        hash = (hash ^ UInt64(bitPattern: Int64(day))) &* 1_099_511_628_211
        hash = (hash ^ UInt64(bitPattern: Int64(cycle))) &* 1_099_511_628_211
        return hash
    }

    /// The day number the seed uses: whole days since the reference date.
    public static func day(of date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        return Int((start.timeIntervalSinceReferenceDate / 86_400).rounded())
    }

    // MARK: - Planning

    /// The plans of one cycle for everyone. A resident walks with a seeded
    /// chance; when more than `maxMovers` would, the ones with the lowest
    /// draws keep walking and the rest work instead.
    /// - Parameters:
    ///   - walkable: the lawn's polygon; `nil` means no walks.
    ///   - avoid: points a walk keeps clear of (Pofu, stations' fronts).
    public static func plans(
        for specs: [Spec],
        day: Int,
        cycle: Int,
        walkable: WorldPolygon?,
        avoid: [WorldPoint] = []
    ) -> [Plan] {
        var drafts: [(plan: Plan, draw: Double)] = []
        for spec in specs {
            var rng = Generator(seed: seed(day: day, cycle: cycle, id: spec.id))
            let draw = rng.unit()
            let glance = rng.value(in: 1.0...6.0)
            var activity = Activity.idle
            var greets = false
            if draw < 0.55, let walkable {
                let others = avoid + specs.filter { $0.id != spec.id }.map(\.home)
                if let target = walkTarget(from: spec.home, walkable: walkable, avoid: others, rng: &rng) {
                    let start = rng.value(in: 0.4...1.0)
                    let linger = rng.value(in: 0.5...1.0)
                    activity = .walk(target: target, start: start, seconds: walkSeconds, linger: linger)
                    greets = avoid.contains { distance($0, target) < 36 }
                }
            }
            // Most of the rest work a beat; a few simply stand and breathe.
            if case .idle = activity, draw < 0.9 {
                activity = .work(start: rng.value(in: 0.5...2.5), seconds: rng.value(in: 2.4...3.6))
            }
            drafts.append((Plan(spec: spec, activity: activity, glanceAt: glance, greetsPofu: greets), draw))
        }
        // Keep the cap: the lowest draws walk, the others work.
        let walkers = drafts.enumerated().filter { if case .walk = $0.element.plan.activity { true } else { false } }
            .sorted { $0.element.draw < $1.element.draw }
        for extra in walkers.dropFirst(maxMovers) {
            var plan = drafts[extra.offset].plan
            plan.activity = .work(start: 0.8, seconds: 3)
            plan.greetsPofu = false
            drafts[extra.offset].plan = plan
        }
        return drafts.map(\.plan)
    }

    /// A target 24 to 46 units to one side of `home`, in front of the
    /// stations' row, inside the walkable polygon along the whole path and
    /// clear of `avoid`. `nil` when no candidate fits in a few tries.
    static func walkTarget(
        from home: WorldPoint,
        walkable: WorldPolygon,
        avoid: [WorldPoint],
        rng: inout Generator
    ) -> WorldPoint? {
        for _ in 0..<16 {
            let side: Double = rng.unit() < 0.5 ? -1 : 1
            let dx = side * rng.value(in: 24...46)
            let dy = rng.value(in: -3...7)
            let target = WorldPoint(x: home.x + dx, y: home.y + dy)
            let pathInside = stride(from: 0.0, through: 1.0, by: 0.125).allSatisfy {
                walkable.contains(WorldPoint(x: home.x + dx * $0, y: home.y + dy * $0))
            }
            guard pathInside else { continue }
            // Depth is compressed: a unit of y is several of x on the ground.
            guard avoid.allSatisfy({ distance($0, target) >= 20 && distance($0, WorldPoint(x: home.x + dx / 2, y: home.y + dy / 2)) >= 12 }) else { continue }
            return target
        }
        return nil
    }

    static func distance(_ a: WorldPoint, _ b: WorldPoint) -> Double {
        let dx = a.x - b.x, dy = (a.y - b.y) * 3
        return (dx * dx + dy * dy).squareRoot()
    }

    // MARK: - Playing a plan

    /// Smooth ease in and out.
    static func ease(_ u: Double) -> Double {
        let t = min(max(u, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// The resident's frame `time` seconds into the cycle (wrapped into
    /// `0..<cycleSeconds`). `isAmbient` false returns the rest frame: a
    /// settled island holds still.
    public static func step(of plan: Plan, at time: Double, isAmbient: Bool = true) -> Step {
        guard isAmbient, time.isFinite else { return .rest }
        let t = min(max(time, 0), cycleSeconds)
        var step = Step()
        // A breath every 4 s, 1.0 to 1.012, always.
        step.breath = 1 + 0.012 * (0.5 - 0.5 * cos(2 * .pi * t / 4))
        // A glance: a lean to one side and back over 0.9 s.
        let g = t - plan.glanceAt
        if g >= 0, g < 0.9 {
            step.lean = 2.2 * sin(.pi * g / 0.9) * (plan.spec.home.x.truncatingRemainder(dividingBy: 2) == 0 ? 1 : -1)
        }
        switch plan.activity {
        case .idle:
            break
        case .work(let start, let seconds):
            let w = t - start
            if w >= 0, w < seconds {
                // Two frames, work and rest, every 0.5 s, with a small bob
                // that fades in and out so the beat starts and ends at rest.
                step.pose = Int(w / 0.5) % 2 == 0 ? .work : .rest
                let fade = min(w / 0.3, (seconds - w) / 0.3, 1)
                step.hop = 0.9 * fade * abs(sin(.pi * w / 0.5))
                step.lean = 1.2 * fade * sin(2 * .pi * w / 1.0)
            }
        case .walk(let target, let start, let seconds, let linger):
            let outEnd = start + seconds
            let backStart = outEnd + linger
            let backEnd = backStart + seconds
            let dx = target.x - plan.spec.home.x, dy = target.y - plan.spec.home.y
            var u = 0.0
            var walkingTime: Double?
            if t >= start, t < outEnd {
                walkingTime = t - start
                u = ease((t - start) / seconds)
                step.facesLeft = dx < 0
            } else if t >= outEnd, t < backStart {
                u = 1
                // A beat at the far end: a greeting for Pofu, else a glance.
                if plan.greetsPofu {
                    step.pose = .happy
                    if t - outEnd < 0.5 { step.hop = 0.8 * sin(.pi * (t - outEnd) / 0.5) }
                }
            } else if t >= backStart, t < backEnd {
                walkingTime = t - backStart
                u = 1 - ease((t - backStart) / seconds)
                step.facesLeft = dx > 0
            }
            step.dx = dx * u
            step.dy = dy * u
            if let w = walkingTime {
                step.isWalking = true
                // Steps: a soft hop every 0.45 s, none at the ends.
                let fade = min(w / 0.4, (seconds - w) / 0.4, 1)
                step.hop = 1.6 * fade * abs(sin(.pi * w / 0.45))
                step.lean = (step.facesLeft ? -1 : 1) * 2 * fade * sin(2 * .pi * w / 0.9)
            }
        }
        return step
    }

    /// How many of `plans` are walking `time` seconds into the cycle.
    public static func movers(of plans: [Plan], at time: Double) -> Int {
        plans.filter { step(of: $0, at: time).isWalking }.count
    }

    // MARK: - Reactions

    /// A reaction's pose and tiny hop, `age` seconds after it began (a tap,
    /// or a greeting from Pofu); `nil` once it is over.
    public static func reaction(age: Double) -> (hop: Double, lean: Double)? {
        guard age >= 0, age < reactionSeconds else { return nil }
        let up = age < 0.35 ? sin(.pi * age / 0.35) : 0
        return (2.2 * up, 0)
    }
}
