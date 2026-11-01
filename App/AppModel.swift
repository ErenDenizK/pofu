import Foundation
import Observation
import os
import PofuCore
import PofuPersistence

/// The app's state holder. It owns the domain state, persists every change,
/// and runs the soft gate for `CheckInIntent`. Views read from it and call
/// its intents; they never mutate domain state themselves.
///
/// There is one shared instance, because the intent can run before any
/// scene exists (a background launch) and must see the same passes as the
/// UI.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel(store: AppModel.makeStore())

    private(set) var state: PofuState
    private(set) var profile: UserProfile
    /// The running honor session, if any.
    private(set) var activeSession: ActiveSession?
    /// The result of the session that just ended, until Pofu has shown the
    /// cheeks-fill moment.
    private(set) var earningResult: EarningResult?
    /// The instant the model last refreshed, so derived values are stable
    /// within one render.
    private(set) var now: Date
    /// Counts quiet-seed collections, so Pofu celebrates each one.
    private(set) var quietCollections = 0
    /// The Hop! on screen, if any. Drives the full-screen cover.
    var hop: HopSession?
    /// The sheet open over Home, if any.
    var homeSheet: HomeSheet?
    /// Set when the last save failed, so a broken disk is never silent.
    private(set) var persistenceProblem = false
    /// Whether Pofu is on screen. Being here is a sign the user left the
    /// guarded app, so quiet time paused by an ended pass starts again.
    private var isOnScreen = false

    let economy: Economy
    let gatekeeper: Gatekeeper
    let router = CheckInRouter()
    let vitalityModel: VitalityModel
    private let clock: any WallClock
    private let store: PofuStore?

    init(
        store: PofuStore?,
        clock: any WallClock = SystemWallClock(),
        configuration: EconomyConfiguration = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        let economy = Economy(configuration: configuration, calendar: calendar)
        self.store = store
        self.clock = clock
        self.economy = economy
        self.gatekeeper = Gatekeeper(economy: economy)
        self.vitalityModel = VitalityModel(rules: configuration.vitality)
        self.now = clock.now

        var snapshot = PofuSnapshot()
        if let store {
            switch store.load() {
            case .empty:
                Log.persistence.info("No snapshot yet: first launch (\(store.location.kind.rawValue, privacy: .public))")
            case .loaded(let loaded):
                snapshot = loaded
                Log.persistence.info("Loaded the snapshot (\(store.location.kind.rawValue, privacy: .public))")
            case .recovered(let error, let quarantinedAt):
                // The unreadable file was moved aside; start fresh rather
                // than refuse to run the gate.
                let movedTo = quarantinedAt?.path ?? "nowhere"
                Log.persistence.fault("Snapshot unreadable, starting fresh: \(String(describing: error), privacy: .public); moved to \(movedTo, privacy: .private)")
            }
        }
        self.state = snapshot.state
        self.profile = snapshot.profile
        self.activeSession = snapshot.activeSession
        if snapshot.state.vitality.settledThrough == nil {
            state.vitality = VitalityLedger(initialVitality: configuration.vitality.initialVitality)
        }
        // Users from before quiet time start observed from their last
        // check-in, not from scratch.
        if let lastCheckIn = snapshot.profile.lastCheckIn.values.max() {
            gatekeeper.quietTime.bootstrap(&state.quietTime, lastSignal: lastCheckIn, checkIns: state.checkIns)
        }
        settleDay()
    }

    /// The store in the App Group container when entitled, else in
    /// Application Support, after moving any files the other location
    /// already holds.
    static func makeStore() -> PofuStore {
        let location = StorageLocation.resolve()
        if location.kind == .appGroup {
            do {
                if try location.migrateIfNeeded(from: .applicationSupport()) {
                    Log.persistence.notice("Moved the files into the App Group container")
                }
            } catch {
                Log.persistence.error("Migration to the App Group failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        return PofuStore(location: location)
    }

    // MARK: - Derived values

    var today: LocalDay { economy.day(of: now) }

    var balance: Energy { state.wallet.balance }

    var impulsesToday: ImpulseMetrics {
        ImpulseMetrics.daily(on: today, from: state.checkIns, calendar: economy.calendar)
    }

    var beadsToday: [ImpulseBead] {
        ImpulseMetrics.beads(on: today, from: state.checkIns, calendar: economy.calendar)
    }

    /// Today's live vitality: settled history moved by today so far.
    var vitality: Double {
        let input = VitalityInput.observed(on: today, in: state, calendar: economy.calendar)
        return state.vitality.live(today: input, model: vitalityModel)
    }

    var isBedtime: Bool { economy.isBedtime(now) }

    /// Cheek fill in `0...1` from the balance and the quiet seeds waiting
    /// to be collected.
    var cheekFill: Double {
        Self.cheekFill(for: balance, pending: state.quietTime.pending)
    }

    /// Seeds waiting in the cheeks puff them visibly beyond the balance's
    /// pouch level, so there is something to collect; collecting swallows
    /// the puff into the pouch.
    static func cheekFill(for balance: Energy, pending: Energy) -> Double {
        let base = cheekFill(for: balance)
        guard pending > .zero else { return base }
        let puff = 0.12 + 0.18 * min(1, Double(pending.units) / 48)
        return min(1, max(cheekFill(for: balance + pending), base + puff))
    }

    /// Cheek fill in `0...1` from the balance, following the pouch levels of
    /// the user flows: empty below 10, snack to 40, full to 90, stuffed.
    static func cheekFill(for balance: Energy) -> Double {
        let points: [(Double, Double)] = [(0, 0.04), (10, 0.25), (40, 0.55), (90, 0.88), (150, 1)]
        let value = Double(max(0, balance.units))
        for (lower, upper) in zip(points, points.dropFirst()) where value <= upper.0 {
            let t = (value - lower.0) / (upper.0 - lower.0)
            return lower.1 + (upper.1 - lower.1) * t
        }
        return 1
    }

    /// Valid passes, soonest to end first.
    var activePasses: [Pass] {
        state.passes.passes
            .filter { $0.isValid(at: now) }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    var needsOnboarding: Bool { !profile.hasCompletedOnboarding }

    // MARK: Quiet time (ADR-0014)

    /// Everything quiet time has put in Pofu's cheeks.
    var pendingQuiet: (quietSeeds: Energy, sleepBonus: Energy) {
        (state.quietTime.pendingQuietSeeds, state.quietTime.pendingSleepBonus)
    }

    /// Seeds are waiting and Pofu is observing, so they can be collected.
    var canCollectQuietSeeds: Bool {
        state.quietTime.pending > .zero && gatekeeper.quietTime.isObserving(state.quietTime, at: now)
    }

    /// The automation has been silent past the observation window: quiet
    /// time is paused and any seeds are held until it fires again.
    var isAwaitingSignOfLife: Bool {
        gatekeeper.quietTime.isAwaitingSignOfLife(state.quietTime, at: now)
    }

    /// How long the current quiet stretch has lasted at `date`, or `nil`
    /// while a pass runs or Pofu is not observing.
    func quietStretch(at date: Date) -> TimeInterval? {
        gatekeeper.quietTime.quietStretch(state.quietTime, at: date)
    }

    /// Chosen apps whose automation has never fired.
    var unverifiedApps: [ProtectedApp] {
        profile.protectedApps.filter { !profile.isVerified($0) }
    }

    // MARK: - Lifecycle

    /// Brings the model up to date: today's allowance, expired passes, and
    /// settled vitality. Called whenever the app becomes active: Pofu on
    /// screen is a sign of life for quiet time (decision audit C1).
    func refresh() {
        isOnScreen = true
        settleDay()
        gatekeeper.noteUserReturned(at: now, state: &state)
        save()
    }

    /// The scene left the foreground.
    func leftForeground() {
        isOnScreen = false
    }

    /// Keeps quiet time and the day current while Home is on screen, and
    /// saves only when something the user can see changed. A pass that
    /// expires while Pofu is on screen hands over to quiet time at once.
    func tick() {
        let before = (state.quietTime.pending, state.wallet.balance, state.quietTime.quietSince)
        settleDay()
        if isOnScreen {
            gatekeeper.noteUserReturned(at: now, state: &state)
        }
        if before != (state.quietTime.pending, state.wallet.balance, state.quietTime.quietSince) {
            save()
        }
    }

    private func settleDay() {
        now = clock.now
        economy.openDay(&state.wallet, at: now)
        gatekeeper.advanceQuietTime(to: now, state: &state)
        state.passes.removeExpired(at: now)
        let calendar = economy.calendar
        let snapshotState = state
        state.vitality.settle(through: today.adding(days: -1), model: vitalityModel) { day in
            VitalityInput.observed(on: day, in: snapshotState, calendar: calendar)
        }
    }

    // MARK: - The soft gate (called by CheckInIntent)

    /// Decides what an automation run for `app` does, and records what can
    /// be recorded without the foreground: that the automation fired, and
    /// a pass-through when a valid pass covers the open.
    func planCheckIn(for app: ProtectedApp, isForeground: Bool, canContinueInForeground: Bool) -> CheckInPlan {
        now = clock.now
        profile.recordCheckIn(from: app, at: now)
        // The automation fired: a sign of life for quiet time, whatever
        // happens next.
        gatekeeper.noteAutomationRan(at: now, state: &state)
        log(.checkInRequested(app: app, foreground: isForeground))

        let presenting = hop.flatMap { $0.isDeciding ? $0.app : nil }
        let route = router.route(for: app, at: now, passes: state.passes, presenting: presenting)
        let plan = router.plan(for: route, isForeground: isForeground, canContinueInForeground: canContinueInForeground)
        Log.intent.debug("Routed \(app.rawValue, privacy: .private): \(plan.logName, privacy: .public), Hop! on screen: \(presenting != nil, privacy: .public)")
        switch plan {
        case .completeSilently(let pass):
            // Records the pass-through; the ladder does not move.
            _ = gatekeeper.beginCheckIn(for: app.target, at: now, state: &state)
            log(.passThrough(app: app, passID: pass.id))
        case .cannotStartHop:
            log(.hopUnavailable(app: app))
        case .ignore, .startHop, .continueInForegroundThenStartHop:
            break
        }
        save()
        return plan
    }

    /// The system refused to bring Pofu forward after all.
    func hopCouldNotStart(for app: ProtectedApp) {
        Log.hop.error("Hop! could not start for \(app.rawValue, privacy: .private)")
        log(.hopUnavailable(app: app))
    }

    /// Starts Hop! for `app`, now that Pofu is in the foreground.
    func startHop(for app: ProtectedApp) {
        now = clock.now
        if let current = hop {
            if current.app == app && current.isDeciding {
                Log.hop.debug("Hop! already on screen for this app")
                return
            }
            // Another app's Hop! was left open: leaving it was a skip.
            if current.isDeciding {
                resolveHop(current, with: .resist)
            }
        }
        let ordinal = ImpulseMetrics.reachOrdinal(at: now, from: state.checkIns)
        switch gatekeeper.beginCheckIn(for: app.target, at: now, state: &state) {
        case .covered(let pass):
            Log.hop.info("A pass covers \(app.rawValue, privacy: .private): no Hop!")
            log(.passThrough(app: app, passID: pass.id))
            hop = nil
        case .intervene(let attempt):
            Log.hop.info("Hop! for \(app.rawValue, privacy: .private) on rung \(String(describing: attempt.rung), privacy: .public)")
            hop = HopSession(app: app, attempt: attempt, isNight: economy.isBedtime(now), reachOrdinal: ordinal)
            log(.hopShown(attemptID: attempt.id, app: app, rung: attempt.rung))
        }
        save()
    }

    // MARK: - Hop! choices

    func chooseReason(_ reason: IntentReason) {
        guard var current = hop, current.isDeciding else { return }
        current.reason = reason
        hop = current
        log(.reasonChosen(attemptID: current.attempt.id, reason: reason))
        save()
    }

    /// Records a skip and shows the celebration.
    func skipHop() {
        guard let current = hop, current.isDeciding else { return }
        resolveHop(current, with: .resist)
    }

    /// Opens the app with `choice` (`.proceed`, `.pay`, or `.emergency`).
    ///
    /// - Returns: Whether the choice went through. A failed payment leaves
    ///   Hop! open so the user can choose again.
    @discardableResult
    func openFromHop(with choice: CheckInChoice) -> Bool {
        guard let current = hop, current.isDeciding else { return false }
        return resolveHop(current, with: choice)
    }

    /// Hop! was left without a choice (the user swiped home or switched
    /// apps). Leaving counts as skipping (ADR-0008). Celebrations and
    /// hand-offs that already resolved are simply dismissed.
    func leaveHop() {
        guard let current = hop else { return }
        if current.isDeciding {
            guard current.hasBeenActive else {
                Log.hop.debug("Left Hop! before it was active: not a skip")
                return
            }
            Log.hop.info("Left Hop! without choosing: counts as a skip")
            resolveHop(current, with: .resist)
        }
        hop = nil
    }

    func markHopActive() {
        guard var current = hop, !current.hasBeenActive else { return }
        current.hasBeenActive = true
        hop = current
    }

    func dismissHop() {
        hop = nil
    }

    /// Hop! asked for the earn sheet ("Or earn seeds with a focus"):
    /// the reach counts as skipped, then Home opens the sheet.
    func skipHopAndEarn() {
        skipHop()
        hop = nil
        requestHomeSheet(.earn)
    }

    /// Opens a sheet over Home once Hop!'s cover has finished dismissing;
    /// UIKit cannot present while a dismissal is in flight.
    func requestHomeSheet(_ sheet: HomeSheet) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650))
            if self.hop == nil {
                self.homeSheet = sheet
            }
        }
    }

    /// The target app could not be opened after the pass was granted: the
    /// pass is voided and its price returned.
    func handoffFailed(for pass: Pass, app: ProtectedApp) {
        now = clock.now
        let ending = gatekeeper.voidPass(id: pass.id, state: &state)
        Log.hop.error("Hand-off to \(app.rawValue, privacy: .private) failed; pass voided")
        log(.handoffFailed(app: app))
        if let ending {
            log(.passVoided(passID: ending.pass.id, refund: ending.refund))
        }
        if var current = hop {
            current.phase = .handoffFailed(refund: ending?.refund ?? .zero)
            hop = current
        }
        save()
    }

    @discardableResult
    private func resolveHop(_ session: HopSession, with choice: CheckInChoice) -> Bool {
        now = clock.now
        do {
            let record = try gatekeeper.resolve(
                session.attempt,
                with: choice,
                at: now,
                state: &state,
                reason: session.reason
            )
            log(.checkInResolved(record))
            Log.hop.info("Hop! resolved: \(choice.logName, privacy: .public)")
            var updated = session
            if let pass = record.outcome.pass {
                updated.phase = .handoff(pass)
            } else {
                updated.phase = .skipped(skipsToday: impulsesToday.resisted)
            }
            hop = updated
            save()
            return true
        } catch {
            Log.hop.error("Hop! choice \(choice.logName, privacy: .public) refused: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    // MARK: - Passes

    /// Ends a pass early from Pofu and refunds its unused whole minutes.
    @discardableResult
    func endPass(_ pass: Pass) -> Energy {
        now = clock.now
        guard let ending = gatekeeper.endPass(id: pass.id, at: now, state: &state) else { return .zero }
        Log.economy.info("Pass ended early; refund \(ending.refund.units, privacy: .private)")
        log(.passEnded(passID: pass.id, refund: ending.refund))
        save()
        return ending.refund
    }

    // MARK: - Earning

    /// What a session of `minutes` would earn on the honor system, before
    /// the daily cap.
    func preview(minutes: Int) -> Energy {
        let start = now
        let session = ActivitySession(
            kind: .focus,
            verification: .honor,
            startedAt: start,
            endedAt: start.addingTimeInterval(TimeInterval(minutes) * 60)
        )
        return economy.grossEnergy(for: session)
    }

    func startSession(kind: ActivityKind, minutes: Int) {
        now = clock.now
        activeSession = ActiveSession(kind: kind, startedAt: now, plannedMinutes: minutes)
        Log.economy.info("Honor session started: \(minutes, privacy: .public) min")
        save()
    }

    /// Ends the running session at `min(now, planned end)` and credits it.
    @discardableResult
    func finishSession() -> EarningResult? {
        guard let running = activeSession else { return nil }
        now = clock.now
        let session = running.completed(at: now)
        let result = economy.earn(session, into: &state.wallet)
        Log.economy.info("Honor session credited: \(result.earned.units, privacy: .private) seeds, \(result.forfeitedToCap.units, privacy: .private) over the cap")
        log(.activityCredited(session, earned: result.earned, forfeited: result.forfeitedToCap))
        activeSession = nil
        earningResult = result
        save()
        return result
    }

    /// Moves the quiet seeds in Pofu's cheeks to the balance.
    ///
    /// - Returns: What was collected, or `nil` when there was nothing to
    ///   collect or the seeds are held.
    @discardableResult
    func collectQuietSeeds() -> QuietCollection? {
        now = clock.now
        guard let collection = gatekeeper.collectQuietSeeds(at: now, state: &state) else { return nil }
        quietCollections += 1
        Log.economy.info("Quiet seeds collected: \((collection.quietSeeds + collection.sleepBonus).units, privacy: .private)")
        log(.quietSeedsCollected(quietSeeds: collection.quietSeeds, sleepBonus: collection.sleepBonus))
        save()
        return collection
    }

    func dismissEarningResult() {
        earningResult = nil
    }

    /// The current time from the model's clock, for views that tick.
    func currentTime() -> Date {
        clock.now
    }

    func cancelSession() {
        activeSession = nil
        save()
    }

    // MARK: - Profile

    func setCompanionName(_ name: String) {
        profile.companionName = name
        save()
    }

    func setProtected(_ app: ProtectedApp, _ isProtected: Bool) {
        if isProtected {
            if !profile.protectedApps.contains(app) {
                profile.protectedApps.append(app)
            }
        } else {
            profile.protectedApps.removeAll { $0 == app }
        }
        save()
    }

    func setProtectedApps(_ apps: [ProtectedApp]) {
        var unique: [ProtectedApp] = []
        for app in apps where !unique.contains(app) {
            unique.append(app)
        }
        profile.protectedApps = unique
        save()
    }

    func completeOnboarding() {
        profile.hasCompletedOnboarding = true
        Log.routing.info("Onboarding completed with \(self.profile.protectedApps.count, privacy: .public) apps")
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let store else { return }
        do {
            try store.save(PofuSnapshot(state: state, profile: profile, activeSession: activeSession))
            persistenceProblem = false
        } catch {
            Log.persistence.error("Saving the snapshot failed: \(error.localizedDescription, privacy: .public)")
            persistenceProblem = true
        }
    }

    private func log(_ event: PofuEvent) {
        do {
            try store?.log(event, at: clock.now)
        } catch {
            Log.persistence.error("Appending to the event log failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// The sheets presented over Home (information architecture: one home,
/// tasks as sheets).
enum HomeSheet: String, Identifiable {
    case earn
    case passes
    case settings
    case setup

    var id: String { rawValue }
}
