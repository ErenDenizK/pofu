import Foundation
import os
import PofuCore
import PofuPersistence

/// Rehearsal mode (Prova modu): the Screen Time product with the system
/// parts simulated inside the app, so the whole day-1 loop can be felt on a
/// free Personal Team build, before the paid membership.
///
/// It is the default in the free build and a developer toggle, off by
/// default, in `PofuLive`. The choice is read once at launch: Rehearsal
/// mode keeps its own store (`location`), so its simulated reaches, passes
/// and island never mix with live data, and every event it logs is tagged
/// `simulated` as well.
enum RehearsalMode {
    private static let enabledKey = "rehearsal.enabled"

    /// Whether this launch runs in Rehearsal mode. Fixed for the process.
    static let isOnAtLaunch: Bool = isEnabled

    /// The saved choice, or the build's default.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? isDefault
    }

    /// On in the free build, off in `PofuLive` (`ScreenTimeGate.isLiveBuild`).
    static var isDefault: Bool {
        #if POFU_SCREEN_TIME_LIVE
        return false
        #else
        return true
        #endif
    }

    /// Saves the choice for the next launch.
    static func setEnabled(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: enabledKey)
        Log.routing.notice("Rehearsal mode \(isOn ? "on" : "off", privacy: .public) from the next launch")
    }

    /// Rehearsal mode's own folder, beside the real store and never in the
    /// App Group, so the real extensions never see it.
    static var location: StorageLocation {
        let base = StorageLocation.applicationSupport().directory.deletingLastPathComponent()
        return StorageLocation(directory: base.appendingPathComponent("Pofu-Rehearsal", isDirectory: true))
    }

    /// The clock Rehearsal mode's time controls move.
    static let clock = RehearsalClock()
}

/// The system clock plus the time Rehearsal mode's controls skipped ahead.
/// The offset is saved, so a relaunch keeps the rehearsed day.
final class RehearsalClock: WallClock, Sendable {
    private static let offsetKey = "rehearsal.clockOffset"

    private let offset: OSAllocatedUnfairLock<TimeInterval>

    init() {
        offset = OSAllocatedUnfairLock(initialState: UserDefaults.standard.double(forKey: Self.offsetKey))
    }

    var now: Date {
        Date().addingTimeInterval(offsetSeconds)
    }

    /// How far ahead of the system clock the rehearsal runs.
    var offsetSeconds: TimeInterval {
        offset.withLock { $0 }
    }

    /// The rehearsal time at the system time `date`, for views whose
    /// timelines tick on the system clock.
    func time(at date: Date) -> Date {
        date.addingTimeInterval(offsetSeconds)
    }

    /// Moves the clock to `date`; never backward.
    func jump(to date: Date) {
        let added = max(0, date.timeIntervalSince(now))
        let total = offset.withLock { value in
            value += added
            return value
        }
        UserDefaults.standard.set(total, forKey: Self.offsetKey)
    }

    /// Back to the system time.
    func reset() {
        offset.withLock { $0 = 0 }
        UserDefaults.standard.removeObject(forKey: Self.offsetKey)
    }
}
