import Foundation
import Observation
import os
import PofuCore
import PofuPersistence
import PofuScreenTime

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
    /// Scheduling the newest pass's expiry reminder, which may wait on the
    /// notification permission prompt. The hand-off waits for it.
    private var reminderTask: Task<Void, Never>?

    let economy: Economy
    let gatekeeper: Gatekeeper
    let router = CheckInRouter()
    let vitalityModel: VitalityModel
    /// The Screen Time gate; available only in the `PofuLive` build.
    let screenTime: ScreenTimeGate
    /// What the app learned from the Screen Time extensions.
    private(set) var screenTimeLedger: ScreenTimeLedger
    private let clock: any WallClock
    private let store: PofuStore?
    private let ledgerFile: JSONFile<ScreenTimeLedger>?

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
        // The extensions can only see the App Group, so the gate's shared
        // files live there whenever the build is entitled to it.
        self.screenTime = ScreenTimeGate(location: StorageLocation.appGroup() ?? store?.location)
        let ledgerFile = store.map { JSONFile<ScreenTimeLedger>(url: $0.location.directory.appendingPathComponent("screen-time-ledger.json")) }
        self.ledgerFile = ledgerFile
        self.screenTimeLedger = ledgerFile?.read() ?? ScreenTimeLedger()
        self.tryOpenParentalControlsApp = UserDefaults.standard.bool(forKey: Self.openParentalControlsKey)

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
        screenTime.update(rules: gateRules)
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

    /// The Screen Time gate's rules with the user's daily hour.
    var gateRules: ScreenTimeGateRules {
        economy.configuration.gate.withDailyHour(profile.dailyHourMinutes)
    }

    /// Today's reaches at the shield and in Hop!, resolved or not, and how
    /// many were resisted: the tally the shield and Home show.
    var reachesToday: (reaches: Int, resisted: Int) {
        let pending = screenTimeLedger.pendingReaches(on: today, calendar: economy.calendar).count
        let metrics = impulsesToday
        return (metrics.attempts + pending, metrics.resisted)
    }

    /// Whether today's measured guarded time reached the daily hour.
    var isPastDailyHour: Bool {
        guard let measured = measuredGuardedMinutesToday else { return false }
        return measured >= gateRules.dailyHourMinutes
    }

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
        syncScreenTime()
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
    ///
    /// - Parameter shieldedApp: The app behind the Screen Time shield when
    ///   the user tapped "Open with Pofu" there. A pass then lifts the shield
    ///   from it, and its own target keeps unknown apps' passes apart.
    func startHop(for app: ProtectedApp, shieldedApp: ShieldedApp? = nil) {
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
        let target = shieldedApp?.target ?? app.target
        switch gatekeeper.beginCheckIn(for: target, at: now, state: &state) {
        case .covered(let pass):
            Log.hop.info("A pass covers \(app.rawValue, privacy: .private): no Hop!")
            log(.passThrough(app: app, passID: pass.id))
            if let shieldedApp {
                // The shield showed despite a running pass: lift it for
                // the rest of that pass.
                screenTime.lift(shieldedApp, for: pass, at: now)
            }
            hop = nil
        case .intervene(let attempt):
            Log.hop.info("Hop! for \(app.rawValue, privacy: .private) on rung \(String(describing: attempt.rung), privacy: .public)")
            hop = HopSession(
                app: app,
                attempt: attempt,
                isNight: economy.isBedtime(now),
                reachOrdinal: ordinal,
                shieldedApp: shieldedApp
            )
            if isPastDailyHour {
                // Past the daily hour every open starts with a breath
                // (ADR-0015, gate v2 section 6.5).
                let overLimitOpen = screenTimeLedger.noteOverLimitOpen(on: today)
                saveScreenTimeLedger()
                hop?.breath = BreathPlan(
                    rules: gateRules,
                    overLimitOpen: overLimitOpen,
                    explains: !UserDefaults.standard.bool(forKey: BreathPlan.explainedKey)
                )
            }
            log(.hopShown(attemptID: attempt.id, app: app, rung: attempt.rung))
        }
        save()
    }

    /// The breath in the breathing room is done; the choices follow.
    func finishBreath() {
        guard var current = hop, current.isDeciding, current.breath != nil else { return }
        current.breathDone = true
        hop = current
        UserDefaults.standard.set(true, forKey: BreathPlan.explainedKey)
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
        cancelReminder(for: pass)
        screenTime.restore(passID: pass.id)
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
                if let shieldedApp = session.shieldedApp {
                    // Before the hand-off opens the app.
                    screenTime.lift(shieldedApp, for: pass, at: now)
                    log(.shieldLifted(passID: pass.id, target: shieldedApp.target))
                }
                // With the shield on, its return is the expiry cue: no push
                // on top of it (gate v2, section 7.2).
                if !screenTime.isOn {
                    let grantedAt = now
                    reminderTask = Task {
                        await PassExpiryReminder.schedule(for: pass, now: grantedAt)
                    }
                }
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

    // MARK: - The Screen Time gate (ADR-0013)

    /// Guarded minutes DeviceActivity measured today, in 15-minute steps;
    /// `nil` when the live gate is not on.
    var measuredGuardedMinutesToday: Int? {
        guard screenTime.isOn else { return nil }
        return screenTimeLedger.measuredMinutes(on: today)
    }

    /// Takes in what the Screen Time extensions recorded (reaches at the
    /// shield and what came of them, measured usage, restored shields),
    /// resolves reaches time has decided (silent leaves, abandoned
    /// requests), and puts any shield back whose pass has ended.
    private func syncScreenTime() {
        guard screenTime.isAvailable else { return }
        screenTime.update(rules: gateRules)
        screenTime.reconcile(at: now)
        let contents = screenTime.readInbox()
        let records = (contents?.records ?? []).map { screenTime.resolved($0) }
        let ledgerBefore = screenTimeLedger
        let events = ScreenTimeIngestion(calendar: economy.calendar, rules: gateRules)
            .ingest(records, at: now, into: &screenTimeLedger, checkIns: &state.checkIns, passes: &state.passes)
        if let note = screenTime.openRequestNote(), !note.isWaiting(at: now, lifetime: gateRules.openRequestLifetime) {
            screenTime.clearOpenRequest()
        }
        guard screenTimeLedger != ledgerBefore || !(contents?.consumable.isEmpty ?? true) else { return }
        for event in events {
            do {
                try store?.events.append(event)
            } catch {
                Log.persistence.error("Appending to the event log failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        Log.screenTime.info("Ingested \(records.count, privacy: .public) Screen Time records")
        // The snapshot and the ledger are saved before the files go, so a
        // crash in between ingests nothing twice (the ledger remembers ids).
        save()
        saveScreenTimeLedger()
        if let contents {
            screenTime.acknowledge(contents)
        }
    }

    /// Starts Hop! for a fresh "Open with Pofu" from the shield.
    ///
    /// The notification's tap routes here through the notification
    /// delegate; coming to the foreground does too, as the fallback for a
    /// user who opens Pofu by hand within the request's lifetime (with
    /// notifications off, the shield asks for exactly that).
    func answerShieldRequest() {
        guard screenTime.isAvailable, !needsOnboarding else { return }
        // Take in the request if it is still in the inbox (a cold launch
        // from the notification).
        if screenTimeLedger.openRequest == nil {
            now = clock.now
            syncScreenTime()
        }
        guard screenTimeLedger.openRequest != nil else { return }
        let request = screenTimeLedger.takeOpenRequest(at: clock.now, maximumAge: gateRules.openRequestLifetime)
        saveScreenTimeLedger()
        guard let request else { return }
        screenTime.clearOpenRequest()
        if let current = hop, !current.isDeciding {
            hop = nil
        }
        Log.screenTime.info("Answering Open with Pofu from the shield")
        startHop(for: request.app.protectedApp, shieldedApp: request.app)
    }

    /// Whether the shield met a reach since `date`: the onboarding demo's
    /// check that the gate works (gate v2, O7).
    func hasShieldReach(since date: Date) -> Bool {
        if screenTimeLedger.pendingReaches.contains(where: { $0.shownAt >= date }) {
            return true
        }
        return state.checkIns.contains { $0.resolvedChannel == .shield && $0.attemptedAt >= date }
    }

    /// The "Open with Pofu" notification was tapped.
    func gateNotificationTapped() {
        Log.screenTime.info("Gate notification tapped")
        refresh()
        answerShieldRequest()
    }

    /// Day-1 spike (gate v2, case 23): answer "Open with Pofu" with
    /// `.openParentalControlsApp` on iOS 26.5 and later.
    private(set) var tryOpenParentalControlsApp: Bool
    private static let openParentalControlsKey = "developer.tryOpenParentalControlsApp"

    func setTryOpenParentalControlsApp(_ isOn: Bool) {
        tryOpenParentalControlsApp = isOn
        UserDefaults.standard.set(isOn, forKey: Self.openParentalControlsKey)
        save()
    }

    /// What the shield extensions read to speak about today (gate v2, E2).
    private func writeShieldState() {
        guard screenTime.isAvailable else { return }
        let calendar = economy.calendar
        let hourAgo = now.addingTimeInterval(-60 * 60)
        let todaysCheckIns = state.checkIns.filter { LocalDay(containing: $0.attemptedAt, in: calendar) == today }
        let pending = screenTimeLedger.pendingReaches(on: today, calendar: calendar)
        let recent = (todaysCheckIns.map(\.attemptedAt) + pending.map(\.shownAt)).filter { $0 > hourAgo && $0 <= now }
        let tally = reachesToday
        screenTime.writeShieldState(
            ShieldAppState(
                writtenAt: now,
                day: today,
                reachesToday: tally.reaches,
                resistedToday: tally.resisted,
                recentReaches: recent,
                wellbeing: vitality,
                calm: nil,
                measuredMinutes: screenTimeLedger.measuredMinutes(on: today),
                dailyHourMinutes: gateRules.dailyHourMinutes,
                overLimitOpensToday: screenTimeLedger.overLimitOpens(on: today),
                bedtime: economy.configuration.spending.bedtime,
                tryOpenParentalControlsApp: tryOpenParentalControlsApp
            )
        )
    }

    private func saveScreenTimeLedger() {
        do {
            try ledgerFile?.write(screenTimeLedger)
        } catch {
            Log.persistence.error("Saving the Screen Time ledger failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Passes

    /// Ends a pass early from Pofu and refunds its unused whole minutes.
    @discardableResult
    func endPass(_ pass: Pass) -> Energy {
        now = clock.now
        guard let ending = gatekeeper.endPass(id: pass.id, at: now, state: &state) else { return .zero }
        cancelReminder(for: pass)
        screenTime.restore(passID: pass.id)
        Log.economy.info("Pass ended early; refund \(ending.refund.units, privacy: .private)")
        log(.passEnded(passID: pass.id, refund: ending.refund))
        save()
        return ending.refund
    }

    /// Waits until the newest pass's expiry reminder is scheduled, or
    /// the user has declined notifications.
    func passReminderReady() async {
        await reminderTask?.value
    }

    /// The user tapped the pass-expiry reminder: a sign of life for quiet
    /// time (decision audit C1).
    func passReminderTapped() {
        now = clock.now
        Log.economy.info("Pass reminder tapped")
        gatekeeper.noteUserReturned(at: now, state: &state)
        save()
    }

    /// Withdraws `pass`'s expiry reminder, after any scheduling still in
    /// flight, so a pass that ended early never pings.
    private func cancelReminder(for pass: Pass) {
        let scheduling = reminderTask
        Task {
            await scheduling?.value
            PassExpiryReminder.cancel(passID: pass.id)
        }
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

    /// Sets the daily hour; past it every open starts with a breath.
    func setDailyHour(minutes: Int) {
        profile.dailyHourMinutes = minutes
        screenTime.update(rules: gateRules)
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
        writeShieldState()
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
