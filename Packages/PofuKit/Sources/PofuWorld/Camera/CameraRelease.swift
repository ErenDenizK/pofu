import Foundation

/// Where a pinch lands when the fingers lift (interaction spec §1.3):
/// project the scale forward by its velocity, pick the nearest framing,
/// and hand the velocity to the landing spring, like a sheet's detents.
public enum CameraRelease {
    /// Seconds of travel the release projects forward.
    public static let projectionTime = 0.18
    /// The velocity cap, in `ln s` per second.
    public static let maxVelocity = 6.0
    /// Fingers that rested this long before lifting do not fling.
    public static let restThreshold = 0.06

    public struct Landing: Hashable, Sendable {
        /// The framing the camera springs to.
        public var framing: WorldFraming
        /// The projected rail position the framing was picked from.
        public var projectedZ: Double
        /// The spring's starting velocity along the rail (z per second).
        public var velocityZ: Double
        /// The release happened inside a rubber band: land without bounce.
        public var fromBand: Bool
    }

    /// The velocity the release may use: zero when the fingers rested
    /// before lifting, otherwise clamped.
    public static func effectiveVelocity(_ velocity: Double, idle: TimeInterval) -> Double {
        guard velocity.isFinite, idle <= restThreshold else { return 0 }
        return min(max(velocity, -maxVelocity), maxVelocity)
    }

    /// The rail position a release at `logScale` with `velocity` (ln s per
    /// second) projects to.
    public static func projectedZ(logScale: Double, velocity: Double, idle: TimeInterval, rail: CameraRail) -> Double {
        rail.z(logScale: logScale + effectiveVelocity(velocity, idle: idle) * projectionTime)
    }

    /// The framing a release would land on now: the detent tick fires when
    /// this changes during a pinch.
    public static func projectedFraming(logScale: Double, velocity: Double, idle: TimeInterval, rail: CameraRail) -> WorldFraming {
        WorldFraming.nearest(to: projectedZ(logScale: logScale, velocity: velocity, idle: idle, rail: rail))
    }

    public static func landing(logScale: Double, velocity: Double, idle: TimeInterval, rail: CameraRail) -> Landing {
        let z = rail.z(logScale: logScale)
        // In a band: the end framing, with the velocity zeroed so the
        // camera never bounces back past a hard end.
        if z > WorldFraming.home.z {
            return Landing(framing: .home, projectedZ: z, velocityZ: 0, fromBand: true)
        }
        if z < WorldFraming.map.z {
            return Landing(framing: .map, projectedZ: z, velocityZ: 0, fromBand: true)
        }
        let v = effectiveVelocity(velocity, idle: idle)
        let projected = projectedZ(logScale: logScale, velocity: velocity, idle: idle, rail: rail)
        return Landing(
            framing: WorldFraming.nearest(to: projected),
            projectedZ: projected,
            velocityZ: v * rail.zPerLogScale(at: z),
            fromBand: false
        )
    }
}
