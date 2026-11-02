import Foundation
import PofuCore

/// One Hop! on screen: the attempt the gate recorded and where the user is
/// in it.
struct HopSession: Identifiable, Equatable {
    enum Phase: Equatable {
        /// Waiting for the user's choice. Every rung shows Skip it.
        case deciding
        /// Skipped; `skipsToday` includes this one.
        case skipped(skipsToday: Int)
        /// A pass was granted; Pofu hands the user back to the app.
        case handoff(Pass)
        /// The app could not be opened; the pass was voided.
        case handoffFailed(refund: Energy)
    }

    let app: ProtectedApp
    let attempt: CheckInAttempt
    /// Inside the bedtime window: the quieter, darker variant.
    let isNight: Bool
    /// "3rd reach this hour".
    let reachOrdinal: Int
    var reason: IntentReason?
    var phase: Phase = .deciding
    /// Whether the cover has been seen in the active scene. Leaving before
    /// that (the system briefly backgrounding during the transition) must
    /// not count as a skip.
    var hasBeenActive = false
    /// The app behind the Screen Time shield, when Hop! answers "Open with
    /// Pofu" there. A pass lifts the shield from it.
    var shieldedApp: ShieldedApp?
    /// Past the daily hour, Hop! opens in the breathing room first.
    var breath: BreathPlan?
    /// The breath was taken; the choices follow.
    var breathDone = false

    var id: UUID { attempt.id }
    var rung: FrictionRung { attempt.rung }
    var isDeciding: Bool { phase == .deciding }
    /// The breathing room is on screen.
    var isBreathing: Bool { isDeciding && breath != nil && !breathDone }
}

/// The breath before an open past the daily hour (ADR-0015, gate v2
/// section 6.5): in over 2 s and out over 3 s, then 4 s and 6 s from the
/// fourth over-limit open of the day.
struct BreathPlan: Equatable {
    static let explainedKey = "breath.explained"

    let inhale: Double
    let exhale: Double
    /// The daily hour, for the one-time explanation.
    let dailyHourMinutes: Int
    /// Explain once, in place, why the breath is here.
    let explains: Bool

    init(rules: ScreenTimeGateRules, overLimitOpen: Int, explains: Bool) {
        let long = rules.breathSeconds(forOverLimitOpen: overLimitOpen) > rules.shortBreathSeconds
        inhale = long ? 4 : 2
        exhale = long ? 6 : 3
        dailyHourMinutes = rules.dailyHourMinutes
        self.explains = explains
    }
}
