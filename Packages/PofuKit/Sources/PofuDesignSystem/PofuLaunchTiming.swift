import Foundation

/// The honest loading screen's clock (experience-v1 section 3.5). There is
/// no minimum duration and no fake progress: the launch sky crossfades to
/// the world when it is ready, or a cloud curtain waits only while loading
/// actually runs.
public enum PofuLaunchTiming {
    /// Ready within this long of the first frame: a plain crossfade.
    public static let crossfadeThreshold: TimeInterval = 0.15
    /// The crossfade from sky to world.
    public static let crossfade: TimeInterval = 0.2
    /// The curtain parting into the establishing shot.
    public static let curtainParts: TimeInterval = 0.6
    /// After this long still loading, one honest line appears.
    public static let lineAfter: TimeInterval = 2.0
    /// The cold-launch target on iPhone 17, in milliseconds.
    public static let coldLaunchTargetMilliseconds = 600

    public enum Reveal: Equatable, Sendable {
        /// The sky crossfades straight to the world.
        case crossfade
        /// The cloud curtain was needed, and now parts.
        case curtain
    }

    /// How the loading screen ends, given when the world became ready
    /// (seconds after the first frame).
    public static func reveal(readyAfter seconds: TimeInterval) -> Reveal {
        seconds <= crossfadeThreshold ? .crossfade : .curtain
    }

    /// Whether the curtain is drawn `seconds` after the first frame while
    /// the world is still not ready: only once the crossfade window passed.
    public static func showsCurtain(after seconds: TimeInterval, isReady: Bool) -> Bool {
        !isReady && seconds > crossfadeThreshold
    }

    /// Whether the honest line shows: still loading after two seconds.
    public static func showsLine(after seconds: TimeInterval, isReady: Bool) -> Bool {
        !isReady && seconds >= lineAfter
    }

    /// The reveal's length.
    public static func revealDuration(_ reveal: Reveal) -> TimeInterval {
        switch reveal {
        case .crossfade: crossfade
        case .curtain: curtainParts
        }
    }
}
