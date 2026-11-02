import Foundation

/// Closed-form curves for the scripted moments, so a moment is a pure
/// function of its time and a screenshot or a test can stop it anywhere.
public enum MomentCurves {
    /// How much of a spring's travel is still ahead `t` seconds after it
    /// was released, for SwiftUI's `spring(duration:bounce:)`: 1 at the
    /// start, 0 at rest, negative while it overshoots.
    public static func springRemaining(_ t: Double, duration: Double, bounce: Double) -> Double {
        guard t > 0 else { return 1 }
        let omega = 2 * Double.pi / max(duration, 0.01)
        let zeta = 1 - min(max(bounce, 0), 0.95)
        if zeta >= 1 {
            return exp(-omega * t) * (1 + omega * t)
        }
        let damped = omega * (1 - zeta * zeta).squareRoot()
        return exp(-zeta * omega * t) * (cos(damped * t) + zeta * omega / damped * sin(damped * t))
    }

    /// `x` clamped to 0…1.
    public static func unit(_ x: Double) -> Double {
        guard x.isFinite else { return 0 }
        return min(max(x, 0), 1)
    }

    /// The fraction of `[start, start + length]` that `t` has covered.
    public static func progress(_ t: Double, from start: Double, length: Double) -> Double {
        guard length > 0 else { return t >= start ? 1 : 0 }
        return unit((t - start) / length)
    }

    public static func easeIn(_ p: Double) -> Double {
        let p = unit(p)
        return p * p
    }

    public static func easeOut(_ p: Double) -> Double {
        let p = unit(p)
        return 1 - (1 - p) * (1 - p)
    }

    public static func smoothstep(_ p: Double) -> Double {
        let p = unit(p)
        return p * p * (3 - 2 * p)
    }
}

/// A point in screen points, for moments that cross the chrome.
public struct MomentPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// One particle of a moment at one instant, in the moment's own units
/// (world units around a station, or screen points).
public struct MomentParticle: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var scale: Double
    public var opacity: Double
    /// Degrees.
    public var rotation: Double

    public init(x: Double, y: Double, scale: Double, opacity: Double, rotation: Double = 0) {
        self.x = x
        self.y = y
        self.scale = scale
        self.opacity = opacity
        self.rotation = rotation
    }
}
