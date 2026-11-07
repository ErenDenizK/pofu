import os
import PofuCore

/// Pofu's unified-log channels, for diagnosing device runs in Console
/// (subsystem `com.erendenizk.pofu`).
///
/// Privacy: anything about the user (which apps they guard, balances,
/// names, file paths) is `.private`, so it is redacted unless a debug
/// profile is installed. Only control flow (plans, rungs, choices, error
/// descriptions from the system) is `.public`.
enum Log {
    static let subsystem = "com.erendenizk.pofu"

    /// `CheckInIntent`: the automation running, and what it decided.
    static let intent = Logger(subsystem: subsystem, category: "intent")
    /// Hop!: shown, resolved, handed off, left.
    static let hop = Logger(subsystem: subsystem, category: "hop")
    /// Seeds: earning, passes, refunds, quiet time.
    static let economy = Logger(subsystem: subsystem, category: "economy")
    /// The snapshot and event log on disk.
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    /// Presentation: which screen or cover is up, and scene phases.
    static let routing = Logger(subsystem: subsystem, category: "routing")
    /// The Screen Time gate: authorization, the shield, thresholds, and the
    /// extensions' inbox.
    static let screenTime = Logger(subsystem: subsystem, category: "screentime")
}

extension CheckInPlan {
    /// The plan's case, without the pass it may carry.
    var logName: String {
        switch self {
        case .completeSilently: "completeSilently"
        case .ignore: "ignore"
        case .startHop: "startHop"
        case .continueInForegroundThenStartHop: "continueInForegroundThenStartHop"
        case .cannotStartHop: "cannotStartHop"
        }
    }
}

extension CheckInChoice {
    /// The choice's case, without minutes.
    var logName: String {
        switch self {
        case .resist: "resist"
        case .proceed: "proceed"
        }
    }
}
