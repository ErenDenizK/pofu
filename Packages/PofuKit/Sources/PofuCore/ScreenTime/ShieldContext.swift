import Foundation

/// What the app tells the shield extensions about the day, written to the
/// App Group on every save (gate v2, E2). The extensions add what happened
/// since (records still in the inbox) and their own memory.
public struct ShieldAppState: Hashable, Sendable, Codable {
    public static let currentVersion = 1
    public static let fileName = "shield-app-state.json"

    public var version: Int
    /// When the app wrote this; inbox records after it are not counted yet.
    public var writtenAt: Date
    /// The local day the counts belong to.
    public var day: LocalDay
    /// Reaches today, resolved or still waiting.
    public var reachesToday: Int
    /// Resisted reaches today.
    public var resistedToday: Int
    /// The times of today's reaches in the last hour before `writtenAt`.
    public var recentReaches: [Date]
    /// Pofu's wellbeing, `0...1`.
    public var wellbeing: Double
    /// Calm, once it exists (ADR-0015).
    public var calm: Double?
    /// Guarded minutes measured on `day`.
    public var measuredMinutes: Int
    /// The user's daily hour, in minutes.
    public var dailyHourMinutes: Int
    /// Opens past the daily hour on `day`.
    public var overLimitOpensToday: Int
    /// The bedtime window.
    public var bedtime: DailyWindow
    /// Day-1 spike (gate v2, case 23): answer "Open with Pofu" with
    /// `.openParentalControlsApp` on iOS 26.5 and later.
    public var tryOpenParentalControlsApp: Bool

    public init(
        writtenAt: Date,
        day: LocalDay,
        reachesToday: Int = 0,
        resistedToday: Int = 0,
        recentReaches: [Date] = [],
        wellbeing: Double = 0.6,
        calm: Double? = nil,
        measuredMinutes: Int = 0,
        dailyHourMinutes: Int = ScreenTimeGateRules.standard.dailyHourMinutes,
        overLimitOpensToday: Int = 0,
        bedtime: DailyWindow = SpendingRules().bedtime,
        tryOpenParentalControlsApp: Bool = false,
        version: Int = ShieldAppState.currentVersion
    ) {
        self.version = version
        self.writtenAt = writtenAt
        self.day = day
        self.reachesToday = reachesToday
        self.resistedToday = resistedToday
        self.recentReaches = recentReaches
        self.wellbeing = wellbeing
        self.calm = calm
        self.measuredMinutes = measuredMinutes
        self.dailyHourMinutes = dailyHourMinutes
        self.overLimitOpensToday = overLimitOpensToday
        self.bedtime = bedtime
        self.tryOpenParentalControlsApp = tryOpenParentalControlsApp
    }
}

/// An "Open with Pofu" the action extension posted, so the configuration
/// extension can draw the waiting shield after `.defer` (section 5.5).
public struct ShieldOpenRequestNote: Hashable, Sendable, Codable {
    public static let fileName = "shield-open-request.json"

    /// The encoded token of the app (or category) the request is for.
    public var token: String
    public var requestedAt: Date
    /// Whether the notification could be posted; when not, the shield
    /// asks the user to open Pofu by hand.
    public var notificationsAllowed: Bool
    /// The request goes to the breathing room (past the daily hour).
    public var breath: Bool

    public init(token: String, requestedAt: Date, notificationsAllowed: Bool, breath: Bool) {
        self.token = token
        self.requestedAt = requestedAt
        self.notificationsAllowed = notificationsAllowed
        self.breath = breath
    }

    /// Whether the request still waits at `date`.
    public func isWaiting(at date: Date, lifetime: TimeInterval) -> Bool {
        let age = date.timeIntervalSince(requestedAt)
        return age >= 0 && age <= lifetime
    }
}

/// The configuration extension's own memory, which only it writes: the
/// jealous budget, the last title, and the last shield per app, so a
/// redraw within seconds is the same shield and not a new reach.
public struct ShieldMemory: Hashable, Sendable, Codable {
    public static let fileName = "shield-memory.json"

    public struct Shown: Hashable, Sendable, Codable {
        public var at: Date
        public var copy: ShieldCopy

        public init(at: Date, copy: ShieldCopy) {
            self.at = at
            self.copy = copy
        }
    }

    public var day: LocalDay?
    public var jealousLinesToday: Int
    public var lastWasJealous: Bool
    public var lastTitle: String?
    /// The last shield drawn per token key.
    public var shown: [String: Shown]

    public init(
        day: LocalDay? = nil,
        jealousLinesToday: Int = 0,
        lastWasJealous: Bool = false,
        lastTitle: String? = nil,
        shown: [String: Shown] = [:]
    ) {
        self.day = day
        self.jealousLinesToday = jealousLinesToday
        self.lastWasJealous = lastWasJealous
        self.lastTitle = lastTitle
        self.shown = shown
    }

    /// The shield drawn for `tokenKey` within `window` before `date` in
    /// `scene`, if any: the system redrawing the same shield.
    public func recent(for tokenKey: String, scene: ShieldScene, at date: Date, window: TimeInterval) -> ShieldCopy? {
        guard let entry = shown[tokenKey], entry.copy.scene == scene else { return nil }
        let age = date.timeIntervalSince(entry.at)
        return age >= 0 && age < window ? entry.copy : nil
    }

    /// Remembers `copy`, drawn for `tokenKey` at `date` on `day`.
    public mutating func note(_ copy: ShieldCopy, for tokenKey: String, at date: Date, on day: LocalDay) {
        if self.day != day {
            self.day = day
            jealousLinesToday = 0
            lastWasJealous = false
        }
        switch copy.line {
        case .jealous:
            jealousLinesToday += 1
            lastWasJealous = true
        case .waiting, .waitingForHand:
            break
        default:
            lastWasJealous = false
        }
        lastTitle = copy.title
        shown[tokenKey] = Shown(at: date, copy: copy)
        // Keep the memory small: forget shields older than a day.
        shown = shown.filter { date.timeIntervalSince($0.value.at) < 24 * 60 * 60 }
    }

    /// The shield the configuration extension drew last for `tokenKey`, if
    /// it is recent enough for a button tap to belong to it.
    public func lastShown(for tokenKey: String, at date: Date, within window: TimeInterval) -> ShieldCopy? {
        guard let entry = shown[tokenKey] else { return nil }
        let age = date.timeIntervalSince(entry.at)
        return age >= 0 && age <= window ? entry.copy : nil
    }
}

/// Builds a `ShieldContext` from what the extensions can read in the App
/// Group, at the moment the shield is drawn.
public struct ShieldContextInputs: Sendable {
    public var app: ShieldedApp
    public var now: Date
    public var calendar: Calendar
    public var rules: ScreenTimeGateRules
    /// What the app wrote last, if anything.
    public var appState: ShieldAppState?
    /// Records in the inbox the app has not taken in yet.
    public var pendingRecords: [ScreenTimeRecord]
    /// Measured guarded time, as the monitor extension wrote it.
    public var measuredUsage: GuardedUsageDay?
    public var memory: ShieldMemory
    public var openRequest: ShieldOpenRequestNote?
    /// When the last pass for this app ended, and how long it was.
    public var endedPass: (end: Date, minutes: Int)?
    /// When the last quick check from the shield ends or ended, if any.
    public var lastQuickCheckEnd: Date?
    public var submenuAvailable: Bool

    public init(
        app: ShieldedApp,
        now: Date,
        calendar: Calendar,
        rules: ScreenTimeGateRules = .standard,
        appState: ShieldAppState?,
        pendingRecords: [ScreenTimeRecord] = [],
        measuredUsage: GuardedUsageDay? = nil,
        memory: ShieldMemory = ShieldMemory(),
        openRequest: ShieldOpenRequestNote? = nil,
        endedPass: (end: Date, minutes: Int)? = nil,
        lastQuickCheckEnd: Date? = nil,
        submenuAvailable: Bool
    ) {
        self.app = app
        self.now = now
        self.calendar = calendar
        self.rules = rules
        self.appState = appState
        self.pendingRecords = pendingRecords
        self.measuredUsage = measuredUsage
        self.memory = memory
        self.openRequest = openRequest
        self.endedPass = endedPass
        self.lastQuickCheckEnd = lastQuickCheckEnd
        self.submenuAvailable = submenuAvailable
    }

    /// The rules with the user's daily hour from the app's state.
    public var effectiveRules: ScreenTimeGateRules {
        rules.withDailyHour(appState?.dailyHourMinutes)
    }

    public var context: ShieldContext {
        let rules = effectiveRules
        let day = LocalDay(containing: now, in: calendar)
        let state = appState.flatMap { $0.day == day ? $0 : nil }
        let since = appState?.writtenAt ?? .distantPast
        let fresh = pendingRecords.filter { record in
            record.at > since && record.at <= now.addingTimeInterval(1) && LocalDay(containing: record.at, in: calendar) == day
        }
        var reaches = state?.reachesToday ?? 0
        var resisted = state?.resistedToday ?? 0
        var recent = (state?.recentReaches ?? []).filter { now.timeIntervalSince($0) < 60 * 60 }
        for record in fresh {
            switch record.kind {
            case .shieldShown(_, let scene) where scene.countsAsReach:
                reaches += 1
                if now.timeIntervalSince(record.at) < 60 * 60 {
                    recent.append(record.at)
                }
            case .shieldResisted, .openRequestCancelled:
                resisted += 1
            default:
                break
            }
        }
        var measured = state?.measuredMinutes ?? 0
        if let usage = measuredUsage, usage.day == day {
            measured = max(measured, usage.measuredMinutes)
        }
        let memory = self.memory.day == day ? self.memory : ShieldMemory(lastTitle: self.memory.lastTitle)
        let bedtime = appState?.bedtime ?? SpendingRules().bedtime

        var waiting: ShieldContext.Waiting?
        if let request = openRequest, request.token == app.token, request.isWaiting(at: now, lifetime: rules.openRequestLifetime) {
            waiting = request.notificationsAllowed ? .notification : .byHand
        }
        var endedMinutes: Int?
        if let endedPass {
            let age = now.timeIntervalSince(endedPass.end)
            if age >= -1, age <= rules.passEndedWindow {
                endedMinutes = endedPass.minutes
            }
        }
        var quickCheckAllowed = true
        if let end = lastQuickCheckEnd {
            quickCheckAllowed = now.timeIntervalSince(end) >= rules.quickCheckChainInterval
        }

        return ShieldContext(
            appName: app.displayName,
            bundleIdentifier: app.bundleIdentifier,
            hour: calendar.component(.hour, from: now),
            dayOfYear: calendar.ordinality(of: .day, in: .year, for: now) ?? 1,
            isBedtime: bedtime.contains(now, in: calendar),
            reachesToday: reaches,
            resistedToday: resisted,
            reachesThisHour: recent.count + 1,
            wellbeing: appState?.wellbeing ?? 0.6,
            calm: appState?.calm,
            isPastDailyHour: measured >= rules.dailyHourMinutes,
            overLimitOpensToday: state?.overLimitOpensToday ?? 0,
            jealousLinesToday: memory.jealousLinesToday,
            lastWasJealous: memory.lastWasJealous,
            lastTitle: memory.lastTitle,
            waiting: waiting,
            endedPassMinutes: endedMinutes,
            quickCheckAllowed: quickCheckAllowed,
            submenuAvailable: submenuAvailable
        )
    }
}
