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
    /// The app behind the Screen Time shield, when Hop! answers "Talk to
    /// Pofu" there. A pass lifts the shield from it.
    var shieldedApp: ShieldedApp?

    var id: UUID { attempt.id }
    var rung: FrictionRung { attempt.rung }
    var isDeciding: Bool { phase == .deciding }
}
