import Foundation

/// The range and step of one tunable key, so the panel can draw a slider
/// for it without hand-written UI per value. Every key of
/// `TuningValues` has exactly one spec (a test holds this).
public struct TuningSpec: Hashable, Sendable, Identifiable {
    public var key: String
    public var range: ClosedRange<Double>
    public var step: Double

    public var id: String { key }

    public init(_ key: String, _ range: ClosedRange<Double>, step: Double) {
        self.key = key
        self.range = range
        self.step = step
    }

    /// `value` clamped to the range and snapped to the step, with the
    /// float noise of the snap rounded away so exports read cleanly.
    public func quantize(_ value: Double) -> Double {
        guard value.isFinite else { return range.lowerBound }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        let steps = ((clamped - range.lowerBound) / step).rounded()
        let snapped = min(range.lowerBound + steps * step, range.upperBound)
        return (snapped * 10_000).rounded() / 10_000
    }

    /// The domain, the first part of the key (`camera`).
    public var domain: String {
        String(key.prefix { $0 != "." })
    }
}

extension TuningSpec {
    public static let all: [TuningSpec] = springs("camera.travel")
        + springs("camera.far")
        + springs("camera.release")
        + springs("camera.focus")
        + springs("camera.buildPush")
        + [
            TuningSpec("depth.parallax", 0...2, step: 0.05),
            TuningSpec("depth.tiltShiftIsland", 1...3, step: 0.05),
            TuningSpec("depth.tiltShiftHome", 1...3, step: 0.05),
        ]
        + trim("grade.day")
        + trim("grade.golden")
        + trim("grade.night")
        + [
            TuningSpec("companion.breathPeriodLow", 2...8, step: 0.1),
            TuningSpec("companion.breathPeriodHigh", 2...8, step: 0.1),
            TuningSpec("companion.breathAmplitudeLow", 0...0.06, step: 0.001),
            TuningSpec("companion.breathAmplitudeHigh", 0...0.06, step: 0.001),
            TuningSpec("companion.blinkIntervalMin", 1...10, step: 0.1),
            TuningSpec("companion.blinkIntervalMax", 1...15, step: 0.1),
        ]
        + ["pofuTap", "collectTap", "buildSwap", "hopAppearDay", "hopAppearNight", "breathStart"].map {
            TuningSpec("haptics.\($0)", 0...1, step: 0.05)
        }

    /// The spec for `key`, if it is tunable.
    public static func spec(for key: String) -> TuningSpec? {
        byKey[key]
    }

    private static let byKey: [String: TuningSpec] = Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })

    private static func springs(_ prefix: String) -> [TuningSpec] {
        [
            TuningSpec("\(prefix).duration", 0.15...2.5, step: 0.05),
            TuningSpec("\(prefix).bounce", 0...0.6, step: 0.01),
        ]
    }

    private static func trim(_ prefix: String) -> [TuningSpec] {
        [
            TuningSpec("\(prefix).exposure", 0.6...1.4, step: 0.01),
            TuningSpec("\(prefix).saturation", 0.4...1.6, step: 0.01),
            TuningSpec("\(prefix).contrast", 0.7...1.3, step: 0.01),
            TuningSpec("\(prefix).warmth", -1...1, step: 0.02),
            TuningSpec("\(prefix).vignette", -0.3...0.4, step: 0.01),
        ]
    }
}
