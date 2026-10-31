import Foundation
import PofuCore

extension Calendar {
    /// Türkiye: UTC+3 all year, no DST. The default for tests.
    static let istanbul = Calendar.gregorian(timeZone: "Europe/Istanbul")
    /// Central Europe: has DST transitions, for clock-change tests.
    static let berlin = Calendar.gregorian(timeZone: "Europe/Berlin")
    static let utc = Calendar.gregorian(timeZone: "UTC")

    static func gregorian(timeZone identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(identifier: identifier) else {
            fatalError("Unknown time zone \(identifier)")
        }
        calendar.timeZone = timeZone
        return calendar
    }
}

/// An instant given as local wall-clock time in `calendar`.
func instant(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int = 12,
    _ minute: Int = 0,
    _ second: Int = 0,
    in calendar: Calendar = .istanbul
) -> Date {
    let components = DateComponents(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second
    )
    guard let date = calendar.date(from: components) else {
        fatalError("Invalid date components \(components)")
    }
    return date
}

extension Date {
    func adding(minutes: Double) -> Date {
        addingTimeInterval(minutes * 60)
    }

    func adding(hours: Double) -> Date {
        addingTimeInterval(hours * 3600)
    }
}

/// Runs `body` and returns the error it threw, or `nil`.
func capturedError<T>(_ body: () throws -> T) -> (any Error)? {
    do {
        _ = try body()
        return nil
    } catch {
        return error
    }
}

/// A session of `minutes` that ends at `end`.
func session(
    _ minutes: Double,
    _ verification: VerificationLevel = .honor,
    kind: ActivityKind = .study,
    endingAt end: Date
) -> ActivitySession {
    ActivitySession(
        kind: kind,
        verification: verification,
        startedAt: end.adding(minutes: -minutes),
        endedAt: end
    )
}

/// A small, fast, deterministic PRNG (SplitMix64) so simulations are
/// reproducible on every platform.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

let testTarget: TargetGroupID = "instagram"
