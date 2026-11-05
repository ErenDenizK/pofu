import Foundation

/// A spring parameterized like SwiftUI's `spring(duration:bounce:)`,
/// integrated in fixed sub-steps and retargetable at any time without
/// losing its velocity (interaction spec §0.1, rule 2: everything is a
/// spring that can be caught).
///
/// The camera owns its springs instead of using SwiftUI animations so a
/// gesture's velocity hands off exactly and a finger can stop a flight
/// where it is (§1.9, §7.3).
public struct WorldSpring: Hashable, Sendable {
    public var value: Double
    /// Units per second.
    public var velocity: Double
    public var target: Double
    /// The perceptual duration, as in `spring(duration:bounce:)`.
    public private(set) var duration: Double
    /// 0 is critically damped; up to 1 bounces more.
    public private(set) var bounce: Double

    public init(_ value: Double, duration: Double = 0.5, bounce: Double = 0) {
        self.value = value
        self.velocity = 0
        self.target = value
        self.duration = max(duration, 0.01)
        self.bounce = min(max(bounce, 0), 0.95)
    }

    /// Pulls toward `target` with a new spring, keeping value and velocity.
    public mutating func retarget(_ target: Double, duration: Double, bounce: Double) {
        self.target = target
        self.duration = max(duration, 0.01)
        self.bounce = min(max(bounce, 0), 0.95)
    }

    /// Puts the spring at rest at `value`.
    public mutating func jump(to value: Double) {
        self.value = value
        self.target = value
        self.velocity = 0
    }

    /// SwiftUI's mapping: response = duration, damping fraction = 1 − bounce.
    var stiffness: Double {
        let omega = 2 * Double.pi / duration
        return omega * omega
    }

    var damping: Double {
        4 * Double.pi * (1 - bounce) / duration
    }

    /// Advances by `dt` seconds in sub-steps of at most 1/240 s; a long
    /// hitch is capped at a quarter second.
    public mutating func step(_ dt: Double) {
        guard dt.isFinite, dt > 0 else { return }
        let total = min(dt, 0.25)
        let steps = max(1, Int((total * 240).rounded(.up)))
        let h = total / Double(steps)
        for _ in 0..<steps {
            let acceleration = stiffness * (target - value) - damping * velocity
            velocity += acceleration * h
            value += velocity * h
        }
    }

    public func isSettled(tolerance: Double = 1e-3) -> Bool {
        abs(value - target) < tolerance && abs(velocity) < tolerance * 10
    }

    /// Snaps to the target once settled, so a resting value is exact.
    public mutating func settleIfClose(tolerance: Double = 1e-3) {
        if isSettled(tolerance: tolerance) {
            jump(to: target)
        }
    }
}

/// The interaction spec's spring tokens (§7.1), as (duration, bounce).
public enum WorldSprings {
    public static let camera = (duration: 0.72, bounce: 0.10)
    public static let cameraFar = (duration: 1.10, bounce: 0.08)
    public static let cameraRelease = (duration: 0.55, bounce: 0.08)
    /// Landing from a rubber band: never bounce back past a hard end.
    public static let cameraFromBand = (duration: 0.55, bounce: 0.0)
    public static let focus = (duration: 0.52, bounce: 0.14)
    public static let residentFocus = (duration: 0.48, bounce: 0.14)
    public static let refocus = (duration: 0.60, bounce: 0.10)
    public static let peek = (duration: 0.45, bounce: 0.15)
    /// The build moment's push-in (§2.4).
    public static let buildPush = (duration: 0.60, bounce: 0.10)
    public static let rack = (duration: 0.60, bounce: 0.0)
    /// Reduce Motion: automatic travel lands in 200 ms without overshoot.
    public static let reduced = (duration: 0.20, bounce: 0.0)
}
