import Foundation

/// The painted Home's characters change spots: now and then one of them
/// (Pofu, Mochi or Fındık) goes from the spot they stand on to the next on
/// their tour in two to four arcing hops along a straight line, then rests.
/// There are no walk cycles and no new art: a hop is only a lift of an
/// existing layer, as `PlateHops`.
///
/// Time is cut into `slotSeconds` slots, each holding at most one move, so
/// at most one character moves at a time and a move happens at most twice a
/// minute over all three. The draws are seeded by the day and the visit's
/// seconds like `PlateHops`; the one thing that is not a pure function of
/// time is where everyone stands (a slot the scene could not use, because a
/// card was open, is skipped), so that lives in a `State` the scene advances
/// each frame. A pinned screenshot replays from the visit's start instead
/// (`replay`).
public enum PlateMoves {
    /// Slot length, seconds: two moves a minute at most, over all three.
    public static let slotSeconds = 30.0
    /// A move starts this far into its slot, seconds.
    public static let startRange = 2.0...20.0
    /// One hop, take-off to landing, and the crouch between two hops.
    public static let hopSeconds = 0.42
    public static let hopRest = 0.14
    /// A hop covers this many plate pixels at most; a move is 2 to 4 hops.
    public static let hopReach = 110.0
    public static let minHops = 2
    public static let maxHops = 4
    /// The lift at the top of an arc, in world units (a tap hop is 2.2).
    public static let height = 2.4
    /// The quietness of a move's hop sound, against a build or tap hop.
    public static let soundLevel = PlateHops.soundLevel
    /// A character keeps this far (plate pixels, across and along the lawn) from the others' feet.
    static let clearX = 44.0
    static let clearY = 30.0

    /// Pofu and the residents who may move, in the order draws pick from.
    public static let ids = ["pofu", "mochi", "findik"]

    /// One move: from a spot to another in `hops` hops.
    public struct Move: Hashable, Sendable {
        public var id: String
        public var from: PlatePoint
        public var to: PlatePoint
        /// Seconds into the visit.
        public var start: Double
        public var slot: Int
        public var hops: Int

        public var duration: Double {
            Double(hops) * hopSeconds + Double(hops - 1) * hopRest
        }
    }

    /// Where a character stands now and how high it is lifted.
    public struct Placement: Hashable, Sendable {
        /// The ground under the feet, in plate pixels.
        public var feet: PlatePoint
        /// World units off the ground now.
        public var lift: Double
        /// The hop in the air now, as one number per slot and hop, for its sound; `nil` on the ground.
        public var hop: Int?
        public var isMoving: Bool
    }

    // MARK: Draws

    static func draw(day: Int, slot: Int) -> (start: Double, pick: Double) {
        var rng = ResidentLife.Generator(seed: ResidentLife.seed(day: day, cycle: slot, id: "plate-move"))
        return (rng.value(in: startRange), rng.unit())
    }

    /// A character's tour of its spots: the painted spot first, the rest in a day's order. A move goes to
    /// the next on the tour.
    public static func tour(of id: String, spots: [PlatePoint], day: Int) -> [PlatePoint] {
        guard let first = spots.first else { return [] }
        var rng = ResidentLife.Generator(seed: ResidentLife.seed(day: day, cycle: 0, id: "tour-\(id)"))
        var rest = Array(spots.dropFirst())
        var shuffled: [PlatePoint] = []
        while !rest.isEmpty {
            shuffled.append(rest.remove(at: min(Int(rng.unit() * Double(rest.count)), rest.count - 1)))
        }
        return [first] + shuffled
    }

    static func hops(from a: PlatePoint, to b: PlatePoint) -> Int {
        let d = ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot()
        return min(max(Int((d / hopReach).rounded(.up)), minHops), maxHops)
    }

    /// Whether `p` is too close to a character standing at `other`.
    static func crowds(_ p: PlatePoint, _ other: PlatePoint) -> Bool {
        abs(p.x - other.x) < clearX && abs(p.y - other.y) < clearY
    }

    /// Whether the straight line from `a` to `b` passes through anyone in `others`.
    static func passes(from a: PlatePoint, to b: PlatePoint, others: [PlatePoint]) -> Bool {
        stride(from: 0.0, through: 1.0, by: 0.05).contains { t in
            let p = PlatePoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
            return others.contains { crowds(p, $0) }
        }
    }

    // MARK: Playing a move

    /// Where a move has put its character `elapsed` seconds into the visit.
    public static func placement(of move: Move, at elapsed: Double) -> Placement {
        let t = elapsed - move.start
        func at(_ u: Double) -> PlatePoint {
            PlatePoint(x: move.from.x + (move.to.x - move.from.x) * u, y: move.from.y + (move.to.y - move.from.y) * u)
        }
        guard t > 0 else { return Placement(feet: move.from, lift: 0, hop: nil, isMoving: true) }
        guard t < move.duration else { return Placement(feet: move.to, lift: 0, hop: nil, isMoving: false) }
        let period = hopSeconds + hopRest
        let index = min(Int(t / period), move.hops - 1)
        let local = t - Double(index) * period
        if local >= hopSeconds {
            return Placement(feet: at(Double(index + 1) / Double(move.hops)), lift: 0, hop: nil, isMoving: true)
        }
        let phase = local / hopSeconds
        return Placement(
            feet: at((Double(index) + phase) / Double(move.hops)),
            lift: height * sin(.pi * phase),
            hop: move.slot * 8 + index,
            isMoving: true
        )
    }

    // MARK: State

    /// Who stands where, and the move going on. The scene advances it every frame.
    public struct State: Sendable {
        /// Where each character rests, by id; a character missing here stands on its first spot.
        public private(set) var at: [String: PlatePoint] = [:]
        public private(set) var active: Move?
        private var consumed = -1
        private var lastElapsed = 0.0

        public init() {}

        /// Everyone where the day's moves have put them, `elapsed` seconds into the visit, and what moves.
        /// - Parameters:
        ///   - spots: each character's spots, the painted one first; a character with fewer than two never moves.
        ///   - present: who is on the lawn (Pofu always; a resident once their station is built).
        ///   - allowed: whether a move may begin, or go on. A move in the air when this turns false ends where
        ///     it was going (a card, a focus or a build must never find someone off a spot).
        @discardableResult
        public mutating func advance(
            day: Int,
            elapsed: Double,
            spots: [String: [PlatePoint]],
            present: [String],
            allowed: Bool
        ) -> [String: Placement] {
            // A new visit starts the day again.
            if elapsed + 1 < lastElapsed { self = State() }
            lastElapsed = elapsed
            if let move = active, elapsed >= move.start + move.duration || !allowed { settle() }
            if elapsed.isFinite, elapsed >= 0 {
                let slot = Int(elapsed / slotSeconds)
                let drawn = draw(day: day, slot: slot)
                let start = Double(slot) * slotSeconds + drawn.start
                if consumed < slot, elapsed >= start {
                    consumed = slot
                    // A slot is used on time or not at all: a late start would pop in mid-hop.
                    if allowed, active == nil, elapsed - start < 1, !present.isEmpty {
                        let id = present[min(Int(drawn.pick * Double(present.count)), present.count - 1)]
                        begin(id, day: day, slot: slot, start: start, spots: spots, present: present)
                    }
                }
            }
            var result: [String: Placement] = [:]
            for id in present {
                if let move = active, move.id == id {
                    result[id] = placement(of: move, at: elapsed)
                } else if let feet = at[id] ?? spots[id]?.first {
                    result[id] = Placement(feet: feet, lift: 0, hop: nil, isMoving: false)
                }
            }
            return result
        }

        /// Ends the move going on at its spot.
        public mutating func settle() {
            if let move = active { at[move.id] = move.to }
            active = nil
        }

        private mutating func begin(_ id: String, day: Int, slot: Int, start: Double, spots: [String: [PlatePoint]], present: [String]) {
            guard let list = spots[id], list.count > 1 else { return }
            let tour = PlateMoves.tour(of: id, spots: list, day: day)
            let here = at[id] ?? list[0]
            let index = tour.firstIndex { abs($0.x - here.x) < 0.5 && abs($0.y - here.y) < 0.5 } ?? 0
            let others = present.filter { $0 != id }.compactMap { at[$0] ?? spots[$0]?.first }
            for step in 1..<tour.count {
                let to = tour[(index + step) % tour.count]
                guard !others.contains(where: { PlateMoves.crowds(to, $0) }),
                      !PlateMoves.passes(from: here, to: to, others: others) else { continue }
                active = Move(id: id, from: here, to: to, start: start, slot: slot, hops: PlateMoves.hops(from: here, to: to))
                return
            }
        }
    }

    /// Everyone `elapsed` seconds into a visit with every move allowed, from a fresh start: what a pinned
    /// screenshot shows.
    public static func replay(day: Int, elapsed: Double, spots: [String: [PlatePoint]], present: [String]) -> [String: Placement] {
        var state = State()
        var t = 0.0
        while t < elapsed {
            state.advance(day: day, elapsed: t, spots: spots, present: present, allowed: true)
            t += 0.1
        }
        return state.advance(day: day, elapsed: elapsed, spots: spots, present: present, allowed: true)
    }
}
