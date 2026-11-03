import Foundation

/// Pofu's idle life as numbers: how he breathes and how often he blinks,
/// low and thriving. The defaults are the motion spec's; the tuning lab panel in
/// Rehearsal mode sets them live through the `companionLife` environment
/// value (look round 4), mapped from `PofuTuning`'s `companion` values.
public struct CompanionLife: Hashable, Sendable {
    /// Seconds per breath at vitality 0 and at vitality 1.
    public var breathPeriodLow: Double
    public var breathPeriodHigh: Double
    /// Peak vertical scale change of a breath at vitality 0 and 1.
    public var breathAmplitudeLow: Double
    public var breathAmplitudeHigh: Double
    /// Seconds between idle blinks.
    public var blinkIntervalMin: Double
    public var blinkIntervalMax: Double

    public init(
        breathPeriodLow: Double = 4.6,
        breathPeriodHigh: Double = 3.3,
        breathAmplitudeLow: Double = 0.024,
        breathAmplitudeHigh: Double = 0.016,
        blinkIntervalMin: Double = 2.5,
        blinkIntervalMax: Double = 6
    ) {
        self.breathPeriodLow = breathPeriodLow
        self.breathPeriodHigh = breathPeriodHigh
        self.breathAmplitudeLow = breathAmplitudeLow
        self.breathAmplitudeHigh = breathAmplitudeHigh
        self.blinkIntervalMin = blinkIntervalMin
        self.blinkIntervalMax = blinkIntervalMax
    }

    /// The motion spec's values.
    public static let standard = CompanionLife()

    /// The blink interval range, ordered and kept positive.
    var blinkRange: ClosedRange<Double> {
        let lo = max(min(blinkIntervalMin, blinkIntervalMax), 0.3)
        return lo...max(blinkIntervalMax, lo)
    }
}
