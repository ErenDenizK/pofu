import Foundation

/// The cloud wake behind the Gezgin on the ride (plan row 2d's art list, motion verb "drift": a cut-out slides,
/// fades and bobs, nothing is painted mid-move). Two cut-outs, `world-gezgin-wake-short` (a cluster of five puffs)
/// and `world-gezgin-wake-long` (a chain of seven). The short one marks take-off and landing, the long one the
/// cruise between; they cross-fade. All of it is born from nothing as she lifts off and is gone again soon after
/// she nears the berth, so the wake is never there while she is moored, and never under Reduce Motion.
///
/// This is only the timeline and the placement; `VoyageRideView` draws it. It is the first thing to cut if the
/// ride drops frames on the render server (row 2d): nothing else depends on it.
public enum VoyageWake {
    public enum Piece: String, CaseIterable, Sendable {
        case short, long

        public var asset: String { "world-gezgin-wake-" + rawValue }
        /// The piece's width as a share of her screen width (the cut-outs are 520 and 920 px against her 760).
        public var share: Double { self == .short ? 0.65 : 1.15 }
        /// The cut-out's height over its width.
        public var aspect: Double { self == .short ? 197.0 / 520.0 : 223.0 / 920.0 }
    }

    /// Where the wake ends after the flight, as a share of the moor beat: it has died by then, well before
    /// she is moored.
    static let dyingShare = 0.4
    private static func smooth(_ x: Double, _ a: Double, _ b: Double) -> Double {
        let u = min(max((x - a) / (b - a), 0), 1)
        return u * u * (3 - 2 * u)
    }

    /// Her flight phase `s` at `seconds`: 0 to 1 over the flight beat, then 1 to 1.4 over the first 40 % of the
    /// moor beat, while the wake dies; `nil` while she boards, once the wake has died, and for a ride under Reduce Motion.
    static func phase(_ ride: VoyageRide, at seconds: Double) -> Double? {
        guard !ride.reduced else { return nil }
        let (beat, progress) = ride.beat(at: seconds)
        switch beat {
        case .board, .done: return nil
        case .fly: return progress
        case .moor: return progress < dyingShare ? 1 + progress : nil
        }
    }

    /// The opacity (0 to 1) of one piece `seconds` into the ride. 0 at both ends of the ride, while she boards
    /// and moors, and under Reduce Motion.
    public static func opacity(_ piece: Piece, ride: VoyageRide, at seconds: Double) -> Double {
        guard let s = phase(ride, at: seconds) else { return 0 }
        switch piece {
        case .short:
            let takeOff = smooth(s, 0, 0.1) * (1 - smooth(s, 0.14, 0.34))
            let landing = smooth(s, 0.7, 0.9) * (1 - smooth(s, 1.05, 1 + dyingShare))
            return max(takeOff, landing)
        case .long:
            return smooth(s, 0.12, 0.32) * (1 - smooth(s, 0.7, 0.92))
        }
    }

    /// Whether any of the wake shows at `seconds`.
    public static func isVisible(ride: VoyageRide, at seconds: Double) -> Bool {
        Piece.allCases.contains { opacity($0, ride: ride, at: seconds) > 0.001 }
    }

    /// Where a piece's leading (big) end sits and how far it has drifted, relative to her centre, as shares of
    /// her screen width. She is painted facing left with her tail on the right at about 0.40 of her width from
    /// the centre; the wake streams from there opposite to her heading and slides slowly away from her.
    /// `behind` is +1 when she goes left (the wake trails to the right) and -1 when she goes right.
    public static func offset(_ piece: Piece, ride: VoyageRide, at seconds: Double) -> (dx: Double, dy: Double) {
        let behind = ride.toTheRight ? -1.0 : 1.0
        let s = phase(ride, at: seconds) ?? 0
        let slide = 0.10 * s
        let bob = sin(2 * .pi * seconds / 2.4 + (piece == .long ? 0.8 : 0)) * 0.02
        return (behind * (0.40 + slide), bob - 0.01)
    }
}
