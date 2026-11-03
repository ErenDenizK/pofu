import Foundation

/// One spring as the tuning lab panel tunes it: settling time and overshoot.
public struct SpringSpec: Hashable, Sendable {
    public var duration: Double
    public var bounce: Double

    public init(duration: Double, bounce: Double) {
        self.duration = max(duration, 0.05)
        self.bounce = min(max(bounce, 0), 0.9)
    }

    init(_ token: (duration: Double, bounce: Double)) {
        self.init(duration: token.duration, bounce: token.bounce)
    }

    var token: (duration: Double, bounce: Double) {
        (duration, bounce)
    }
}

/// The camera's tunable springs (look round 4: the tuning lab panel sets them
/// live through `WorldLook.tuning`). The defaults are `WorldSprings`'.
public struct CameraSprings: Hashable, Sendable {
    /// Between neighbouring framings (Home ↔ Island).
    public var travel: SpringSpec
    /// To or from the Map.
    public var far: SpringSpec
    /// After a pinch or a pan lets go.
    public var release: SpringSpec
    /// Into a station.
    public var focus: SpringSpec
    /// The build moment's push-in.
    public var buildPush: SpringSpec

    public init(travel: SpringSpec, far: SpringSpec, release: SpringSpec, focus: SpringSpec, buildPush: SpringSpec) {
        self.travel = travel
        self.far = far
        self.release = release
        self.focus = focus
        self.buildPush = buildPush
    }

    public static let standard = CameraSprings(
        travel: SpringSpec(WorldSprings.camera),
        far: SpringSpec(WorldSprings.cameraFar),
        release: SpringSpec(WorldSprings.cameraRelease),
        focus: SpringSpec(WorldSprings.focus),
        buildPush: SpringSpec(WorldSprings.buildPush)
    )
}

/// The world's feel numbers that the tuning lab panel tunes live (look round 4),
/// carried in `WorldLook.tuning`. The defaults change nothing.
public struct WorldTuning: Hashable, Sendable {
    public var springs: CameraSprings
    /// Depth in motion's parallax, as a multiple of the authored one.
    public var parallax: Double
    /// The HD-2D tilt-shift strength at the Island and at Home.
    public var tiltShiftIsland: Double
    public var tiltShiftHome: Double

    public init(springs: CameraSprings = .standard, parallax: Double = 1, tiltShiftIsland: Double = 1.7, tiltShiftHome: Double = 1.3) {
        self.springs = springs
        self.parallax = parallax
        self.tiltShiftIsland = tiltShiftIsland
        self.tiltShiftHome = tiltShiftHome
    }

    public static let standard = WorldTuning()
}
