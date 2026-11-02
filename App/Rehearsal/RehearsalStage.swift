import Foundation
import Observation
import PofuCore
import PofuScreenTime

/// What Rehearsal mode shows over Pofu: the shield replica, or the inside
/// of a simulated app, and the Prova panel's state. The model drives it;
/// views only read it and call the model.
@MainActor
@Observable
final class RehearsalStage {
    /// Where the user is, outside Pofu.
    enum Screen: Equatable {
        /// At the shield over `app`, which the system calls `shielded`,
        /// showing `copy`.
        case shield(app: ProtectedApp, shielded: ShieldedApp, copy: ShieldCopy)
        /// Inside `app`.
        case app(ProtectedApp)
    }

    let system: RehearsalScreenTime
    let clock: RehearsalClock
    /// `nil` while the user is in Pofu.
    var screen: Screen?
    /// The panel shows its controls rather than its pill.
    var isPanelExpanded = true
    /// The Ayçiçeği garden game is open (the debug entry for the island
    /// minigame, until islands have a "Play" door and rounds a ledger).
    var isPlayingGarden = false
    /// Earned rounds when the garden opened: the set's length.
    var gardenRounds = 0
    /// Counts the clock's jumps, so the panel's clock readout follows.
    private(set) var jumps = 0

    init(system: RehearsalScreenTime, clock: RehearsalClock) {
        self.system = system
        self.clock = clock
    }

    /// The user is outside Pofu: at a shield or in an app.
    var isAway: Bool { screen != nil }

    func noteJump() {
        jumps += 1
    }
}
