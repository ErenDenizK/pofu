import Foundation
import Observation
import PofuCore
import PofuScreenTime

/// The app's state holder. It owns the domain state and talks to the
/// Screen Time boundary; views only read from it and call its intents.
///
/// Persistence is not wired yet: state lives in memory until the
/// `PofuPersistence` module exists (ADR-0003).
@MainActor
@Observable
final class AppModel {
    private(set) var state = PofuState()
    private(set) var screenTimeStatus: ScreenTimeAuthorizationStatus = .notDetermined
    /// The instant the view last refreshed, so derived values are stable
    /// within one render.
    private(set) var now: Date

    let economy: Economy
    private let clock: any WallClock
    private let screenTime: any ScreenTimeService

    init(
        clock: any WallClock = SystemWallClock(),
        screenTime: any ScreenTimeService = SimulatedScreenTimeService(),
        configuration: EconomyConfiguration = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.clock = clock
        self.screenTime = screenTime
        self.economy = Economy(configuration: configuration, calendar: calendar)
        self.now = clock.now
    }

    // MARK: Derived values

    var balance: Energy {
        state.wallet.balance
    }

    var dailyAllowance: Energy {
        economy.configuration.dailyAllowance
    }

    /// The cheapest unlock window right now.
    var nextUnlock: UnlockQuote? {
        economy.cheapestQuote(at: now, for: state.wallet)
    }

    var impulsesToday: ImpulseMetrics {
        ImpulseMetrics.daily(on: economy.day(of: now), from: state.checkIns, calendar: economy.calendar)
    }

    // MARK: Intents

    /// Brings the model up to date: today's allowance and Screen Time
    /// status. Called on launch and whenever the app becomes active.
    func refresh() async {
        now = clock.now
        economy.openDay(&state.wallet, at: now)
        screenTimeStatus = await screenTime.authorizationStatus()
    }

    func connectScreenTime() async {
        do {
            screenTimeStatus = try await screenTime.requestAuthorization()
        } catch {
            screenTimeStatus = await screenTime.authorizationStatus()
        }
    }

    /// Development affordance: credits a self-reported 20-minute walk that
    /// ends now, to exercise the economy end to end.
    func logDemoWalk() {
        now = clock.now
        let walk = ActivitySession(
            kind: .walk,
            verification: .honor,
            startedAt: now.addingTimeInterval(-20 * 60),
            endedAt: now
        )
        economy.earn(walk, into: &state.wallet)
    }
}
