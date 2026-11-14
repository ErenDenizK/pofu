import Foundation

/// The painted Home's idle life: now and then one resident hops on the
/// spot. Walks stay parked (no art, no path); a hop is only a lift of an
/// existing layer. Pure and stateless: the same day and the same visit
/// second always give the same answer, so tests and replays are stable.
///
/// Time is cut into `slotSeconds` slots. Each slot holds at most one hop,
/// starting `0...startSpread` seconds into the slot, so two hops are always
/// 6 to 14 seconds apart and never overlap.
public enum PlateHops {
    /// Slot length, seconds.
    public static let slotSeconds = 10.0
    /// A hop starts this far into its slot at most; the gap between two
    /// hops is `slotSeconds` plus the difference of two starts: 6...14 s.
    public static let startSpread = 4.0
    /// One hop, take-off to landing.
    public static let hopSeconds = 0.4
    /// The lift at the top of the arc, in world units (a tap hop is 2.2).
    public static let height = 1.6
    /// The quietness of an idle hop's sound, against a build or tap hop.
    public static let soundLevel = 0.45

    public struct Hop: Hashable, Sendable {
        /// The slot, counting from the start of the visit: one sound each.
        public var slot: Int
        public var id: String
        /// World units off the ground now.
        public var lift: Double
        /// Seconds since take-off.
        public var age: Double
    }

    /// Whether hops run at all: the Ambient state is on, Reduce Motion is
    /// off, it is not a still frame, and the app is awake. Low Power Mode,
    /// heat and an inactive app are the frame policy's `isAmbient`.
    public static func runs(isAmbient: Bool, reduceMotion: Bool, isStill: Bool, isActive: Bool = true) -> Bool {
        isAmbient && !reduceMotion && !isStill && isActive
    }

    /// When the slot's hop starts, seconds into the slot, and who hops
    /// (an index into the candidates).
    static func draw(day: Int, slot: Int) -> (start: Double, pick: Double) {
        var rng = ResidentLife.Generator(seed: ResidentLife.seed(day: day, cycle: slot, id: "plate-hop"))
        return (rng.value(in: 0...startSpread), rng.unit())
    }

    /// The hop going on `elapsed` seconds into a visit, if any. `ids` are
    /// the residents who may hop (built stations only).
    public static func hop(day: Int, elapsed: Double, ids: [String]) -> Hop? {
        guard elapsed.isFinite, elapsed >= 0, !ids.isEmpty else { return nil }
        let slot = Int(elapsed / slotSeconds)
        let drawn = draw(day: day, slot: slot)
        let age = elapsed - Double(slot) * slotSeconds - drawn.start
        guard age >= 0, age < hopSeconds else { return nil }
        let index = min(Int(drawn.pick * Double(ids.count)), ids.count - 1)
        return Hop(slot: slot, id: ids[index], lift: height * sin(.pi * age / hopSeconds), age: age)
    }
}
