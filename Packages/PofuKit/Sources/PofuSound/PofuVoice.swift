import Foundation

/// Which of Pofu's voices answers a tap on him. Pure: the app feeds it the
/// time and the hour's state and plays what it names.
public struct PofuVoice: Sendable {
    /// A tap this soon after the last one is the second: he giggles.
    public static let giggleWindow: TimeInterval = 2.5

    private var lastTap: TimeInterval?

    public init() {}

    /// The voice for a tap at `now`. At bedtime he only sighs; a second tap
    /// soon after the first giggles in place of the poke.
    public mutating func tap(at now: TimeInterval, isBedtime: Bool) -> SoundCue {
        defer { lastTap = now }
        if isBedtime { return .pofuSleepySigh }
        if let last = lastTap, now - last <= Self.giggleWindow, now >= last { return .pofuGiggle }
        return .pofuPoke
    }
}
