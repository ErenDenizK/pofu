import Foundation

/// How the critters move (experience v1 §6, rule 3), pure and unit-tested.
///
/// A critter sits at its rest spot in a still frame. It moves only in the
/// Ambient state (the visit window after an arrival or a touch) or when a
/// finger brushes it (`TouchField`, drawn as a sway). In every other state
/// its pose is exactly the rest pose, so a settled world stays a cached
/// frame and the critters cost nothing.
public enum CritterMotion {
    /// A critter's pose at an instant, as an offset from its rest spot.
    public struct Pose: Hashable, Sendable {
        public var dx = 0.0
        public var dy = 0.0
        /// The frame of the four-frame loop; 0 is the rest pose.
        public var frame = 0
        /// Facing left (a critter that walks back and forth).
        public var facesLeft = false

        public static let rest = Pose()

        public var isRest: Bool { self == .rest }
    }

    /// Whether the critters may move under `directive`: only in Ambient.
    public static func moves(under directive: FrameDirective) -> Bool {
        directive.state == .ambient
    }

    /// A stable per-critter offset in time, so two butterflies never flap
    /// in step.
    static func phase(of id: String) -> Double {
        var hash: UInt64 = 5381
        for scalar in id.unicodeScalars {
            hash = (hash &* 33) &+ UInt64(scalar.value)
        }
        return Double(hash % 1000) / 1000 * 2 * .pi
    }

    /// The pose of `critter` at `time` seconds; the rest pose unless
    /// `isAmbient`.
    public static func pose(of critter: Critter, at time: Double, isAmbient: Bool) -> Pose {
        guard isAmbient else { return .rest }
        let ph = phase(of: critter.id)
        let t = time + ph
        switch critter.kind {
        case .butterfly:
            // A lazy loop above the flowers, the wings beating.
            let dx = 12 * sin(t * 0.9)
            return Pose(dx: dx, dy: -6 - 5 * sin(t * 1.7), frame: Int(time * 8) & 3, facesLeft: cos(t * 0.9) < 0)
        case .snail:
            // A slow crawl along the lip.
            let dx = 5 * sin(t * 0.18)
            return Pose(dx: dx, dy: 0, frame: Int(time * 1.5) & 3, facesLeft: cos(t * 0.18) < 0)
        case .bird:
            // A hop and a peck now and then.
            let u = (t / 2.8).truncatingRemainder(dividingBy: 1)
            let hop = u < 0.12 ? -3.5 * sin(u / 0.12 * .pi) : 0
            return Pose(dx: 0, dy: hop, frame: u < 0.12 ? 1 : 0, facesLeft: Int((t / 2.8).rounded(.down)) % 2 == 0)
        case .frog:
            // A small hop on a long breath.
            let u = (t / 3.6).truncatingRemainder(dividingBy: 1)
            let hop = u < 0.14 ? -4.5 * sin(u / 0.14 * .pi) : 0
            return Pose(dx: 0, dy: hop, frame: u < 0.14 ? 1 : 0)
        case .ladybug:
            // A short crawl over the flowers.
            let dx = 6 * sin(t * 0.5)
            return Pose(dx: dx, dy: 1.5 * sin(t * 0.9), frame: Int(time * 4) & 3, facesLeft: cos(t * 0.5) < 0)
        }
    }
}
