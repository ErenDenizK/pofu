import Foundation

/// A damped spring integrated in fixed steps.
///
/// It is parameterized like SwiftUI's `.spring(response:dampingFraction:)`
/// so values tuned in the web prototype
/// (`design/prototypes/companion-motion`) carry over unchanged. Unlike a
/// SwiftUI animation, it can be kicked with a velocity impulse at any time
/// and keeps its momentum, which is what makes squishes and landings feel
/// physical.
public struct CompanionSpring: Hashable, Sendable {
    /// The current value.
    public var value: Double
    /// The current velocity, in units per second.
    public var velocity: Double
    /// The value the spring pulls toward.
    public var target: Double
    /// The period of the undamped oscillation, in seconds.
    public let response: Double
    /// 1 is critically damped; below 1 overshoots and wobbles.
    public let dampingFraction: Double

    public init(value: Double = 0, response: Double, dampingFraction: Double) {
        self.value = value
        self.velocity = 0
        self.target = value
        self.response = max(response, 0.01)
        self.dampingFraction = max(dampingFraction, 0)
    }

    var stiffness: Double {
        let omega = 2 * Double.pi / response
        return omega * omega
    }

    var damping: Double {
        4 * Double.pi * dampingFraction / response
    }

    /// Advances the spring by `duration` seconds. Long frames are split into
    /// sub-steps of at most 1/240 s, so stiff springs stay stable even when
    /// the app hitches.
    public mutating func step(_ duration: Double) {
        guard duration.isFinite, duration > 0 else { return }
        let total = min(duration, 0.25)
        let steps = max(1, Int((total * 240).rounded(.up)))
        let dt = total / Double(steps)
        for _ in 0..<steps {
            let acceleration = stiffness * (target - value) - damping * velocity
            velocity += acceleration * dt
            value += velocity * dt
        }
    }

    /// Whether the spring has come to rest at its target.
    public func isSettled(tolerance: Double = 1e-3) -> Bool {
        abs(value - target) < tolerance && abs(velocity) < tolerance * 10
    }
}
