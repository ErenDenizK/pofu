import Foundation

/// A flight between two islands (§1.2): the camera rises to the
/// Archipelago's edge, travels over the sea, and descends to the target's
/// Island stop. Pure: the rig samples it by elapsed time.
public struct CameraFlight: Hashable, Sendable {
    /// Shares of the flight's time.
    public static let riseShare = 0.35
    public static let travelShare = 0.30
    public static let descendShare = 0.35
    /// The apex, as a rail position (just above the Archipelago).
    public static let apexZ = 0.15
    /// The flight holds at its apex for the target's plates at most this
    /// long (seconds).
    public static let maxApexHold = 0.3

    public let from: CameraPose
    public let to: CameraPose
    /// `ln s` at the apex.
    public let apexLogScale: Double
    public let duration: Double

    public init(from: CameraPose, to: CameraPose, apexLogScale: Double) {
        self.from = from
        self.to = to
        self.apexLogScale = min(apexLogScale, from.logScale, to.logScale)
        duration = Self.duration(distance: Self.distance(from: from, to: to))
    }

    /// The flight's length, in seconds: `0.9 + 0.25·log2(1 + d/1000)`,
    /// capped at 1.6 s.
    public static func duration(distance: Double) -> Double {
        let d = max(distance, 0)
        return min(0.9 + 0.25 * log2(1 + d / 1000), 1.6)
    }

    /// The distance between two poses' look points, in world units.
    public static func distance(from a: CameraPose, to b: CameraPose) -> Double {
        let dx = b.lookX - a.lookX, dy = b.lookY - a.lookY
        return (dx * dx + dy * dy).squareRoot()
    }

    private static func ease(_ t: Double) -> Double {
        let u = min(max(t, 0), 1)
        return u * u * (3 - 2 * u)
    }

    /// The camera `seconds` into the flight (clamped to the flight).
    public func pose(at seconds: Double) -> CameraPose {
        let t = min(max(seconds / max(duration, 1e-6), 0), 1)
        let riseEnd = Self.riseShare
        let travelEnd = Self.riseShare + Self.travelShare
        if t <= riseEnd {
            // Up: the scale drops to the apex over where we are.
            let u = Self.ease(t / riseEnd)
            var pose = from
            pose.logScale = from.logScale + (apexLogScale - from.logScale) * u
            return pose
        }
        let apexFrom = CameraPose(logScale: apexLogScale, lookX: from.lookX, lookY: from.lookY, anchorY: from.anchorY)
        let apexTo = CameraPose(logScale: apexLogScale, lookX: to.lookX, lookY: to.lookY, anchorY: to.anchorY)
        if t <= travelEnd {
            let u = Self.ease((t - riseEnd) / Self.travelShare)
            return CameraPose.mix(apexFrom, apexTo, u)
        }
        let u = Self.ease((t - travelEnd) / Self.descendShare)
        var pose = apexTo
        pose.logScale = apexLogScale + (to.logScale - apexLogScale) * u
        return pose
    }

    /// Whether `seconds` is past the flight's end.
    public func isFinished(at seconds: Double) -> Bool {
        seconds >= duration
    }
}
