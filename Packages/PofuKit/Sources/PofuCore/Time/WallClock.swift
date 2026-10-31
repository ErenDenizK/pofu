import Foundation

/// A source of the current time.
///
/// Domain logic never reads the system clock. Every rule takes explicit
/// `Date` values; the app layer asks a `WallClock` for "now" and passes it
/// in. Tests and previews inject a fixed clock.
public protocol WallClock: Sendable {
    var now: Date { get }
}

/// The real system clock. The only place in PofuCore that reads `Date()`.
public struct SystemWallClock: WallClock {
    public init() {}

    public var now: Date {
        Date()
    }
}

/// A clock frozen at a chosen instant, for tests, previews, and simulations.
public struct FixedWallClock: WallClock {
    public var now: Date

    public init(now: Date) {
        self.now = now
    }
}
