import Foundation
import Testing
@testable import PofuCore

/// Quiet-time earning (ADR-0014): seeds for staying away, the bedtime
/// exclusion and the slept-on-it bonus, the daily cap, observation and held
/// seeds, and collecting.
@Suite("Quiet time")
struct QuietTimeTests {
    let accrual = QuietTimeAccrual(calendar: .istanbul)
    let gatekeeper = Gatekeeper(economy: Economy(calendar: .istanbul))
    let noon = instant(2026, 11, 2, 12)

    /// A ledger that heard its first sign of life at `date`.
    func signaled(at date: Date, using accrual: QuietTimeAccrual? = nil) -> QuietTimeLedger {
        var ledger = QuietTimeLedger()
        (accrual ?? self.accrual).recordSignal(at: date, in: &ledger, passes: PassLedger())
        return ledger
    }

    /// An accrual without a bedtime window, so whole days count.
    func withoutBedtime(_ rules: QuietTimeRules = QuietTimeRules()) -> QuietTimeAccrual {
        QuietTimeAccrual(rules: rules, bedtime: DailyWindow(start: LocalTime(hour: 0), end: LocalTime(hour: 0)), calendar: .istanbul)
    }

    /// Begins a check-in and requires an intervention.
    func attempt(at date: Date, in state: inout PofuState) throws -> CheckInAttempt {
        let decision = gatekeeper.beginCheckIn(for: testTarget, at: date, state: &state)
        guard case .intervene(let attempt) = decision else {
            Issue.record("Expected an intervention, got \(decision)")
            throw CancellationError()
        }
        return attempt
    }

    // MARK: - Blocks

    @Test func nothingAccruesBeforeTheFirstSignOfLife() {
        var ledger = QuietTimeLedger()
        let result = accrual.advance(&ledger, to: noon.adding(hours: 5))
        #expect(result == QuietAccrual())
        #expect(ledger.pending == .zero)
        #expect(ledger.accruedThrough == nil)
        #expect(!accrual.isObserving(ledger, at: noon))
        #expect(!accrual.isAwaitingSignOfLife(ledger, at: noon.adding(hours: 100)))
    }

    @Test func oneSeedPerWholeTenQuietMinutes() {
        var ledger = signaled(at: noon)
        #expect(accrual.advance(&ledger, to: noon.adding(minutes: 9.99)).quietSeeds == .zero)
        #expect(accrual.advance(&ledger, to: noon.adding(minutes: 10)).quietSeeds == 1)
        #expect(accrual.advance(&ledger, to: noon.adding(minutes: 59)).quietSeeds == 4)
        #expect(accrual.advance(&ledger, to: noon.adding(hours: 2)).quietSeeds == 7)
        #expect(ledger.pendingQuietSeeds == 12)
        #expect(ledger.quietSeeds(on: accrual.day(of: noon)) == 12)
    }

    @Test(arguments: [UInt64(1), 5, 23, 2_026])
    func advancingInStepsCreditsExactlyWhatOneAdvanceDoes(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        let start = instant(2026, 11, 2, 7, 13)
        let end = start.adding(hours: 70)
        var once = signaled(at: start)
        let total = accrual.advance(&once, to: end)

        var stepped = signaled(at: start)
        var sum = QuietAccrual()
        var cursor = start
        while cursor < end {
            cursor = min(end, cursor.adding(minutes: Double(Int.random(in: 1...300, using: &rng)) + Double.random(in: 0..<1, using: &rng)))
            let step = accrual.advance(&stepped, to: cursor)
            sum.quietSeeds += step.quietSeeds
            sum.forfeitedToCap += step.forfeitedToCap
            sum.sleepBonus += step.sleepBonus
        }
        #expect(sum == total)
        #expect(stepped == once)
    }

    @Test func aClockThatMovesBackwardsChangesNothing() {
        var ledger = signaled(at: noon)
        accrual.advance(&ledger, to: noon.adding(hours: 1))
        let before = ledger
        #expect(accrual.advance(&ledger, to: noon.adding(minutes: 20)) == QuietAccrual())
        // A sign of life older than the last one moves nothing either.
        accrual.recordSignal(at: noon.adding(minutes: -30), in: &ledger, passes: PassLedger())
        #expect(ledger == before)
        #expect(accrual.advance(&ledger, to: noon.adding(hours: 1)) == QuietAccrual())
    }

    // MARK: - Opens and resists

    @Test func aResistedAttemptDoesNotBreakQuiet() throws {
        var state = PofuState()
        let first = try attempt(at: noon, in: &state)
        try gatekeeper.resolve(first, with: .resist, at: noon.adding(minutes: 1), state: &state)
        let second = try attempt(at: noon.adding(minutes: 25), in: &state)
        try gatekeeper.resolve(second, with: .resist, at: noon.adding(minutes: 26), state: &state)
        gatekeeper.advanceQuietTime(to: noon.adding(hours: 1), state: &state)
        #expect(state.quietTime.pendingQuietSeeds == 6)
        #expect(state.quietTime.quietSince == noon)
    }

    @Test func anOpenBreaksQuietAndItResumesWhenThePassEnds() throws {
        var state = PofuState()
        let first = try attempt(at: noon, in: &state)
        try gatekeeper.resolve(first, with: .resist, at: noon, state: &state)
        // Opens at 12:25 with a free 5-minute pass: two blocks before it.
        let second = try attempt(at: noon.adding(minutes: 25), in: &state)
        try gatekeeper.resolve(second, with: .proceed, at: noon.adding(minutes: 25), state: &state)
        #expect(state.quietTime.pendingQuietSeeds == 2)
        #expect(state.quietTime.quietSince == noon.adding(minutes: 30))
        #expect(gatekeeper.quietTime.quietStretch(state.quietTime, at: noon.adding(minutes: 28)) == nil)
        // Quiet resumes at 12:30; 13:00 completes three more blocks, the
        // partial block cut by the pass is gone.
        gatekeeper.advanceQuietTime(to: noon.adding(hours: 1), state: &state)
        #expect(state.quietTime.pendingQuietSeeds == 5)
        #expect(gatekeeper.quietTime.quietStretch(state.quietTime, at: noon.adding(hours: 1)) == TimeInterval(1_800))
    }

    @Test func passThroughsDuringAPassChangeNothing() throws {
        var state = PofuState()
        let first = try attempt(at: noon, in: &state)
        try gatekeeper.resolve(first, with: .pay(minutes: 15), at: noon, state: &state)
        var withVisits = state
        _ = gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(minutes: 3), state: &withVisits)
        _ = gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(minutes: 9), state: &withVisits)
        #expect(withVisits.passThroughs.count == 2)
        gatekeeper.advanceQuietTime(to: noon.adding(hours: 1), state: &state)
        gatekeeper.advanceQuietTime(to: noon.adding(hours: 1), state: &withVisits)
        #expect(withVisits.quietTime.quietSince == noon.adding(minutes: 15))
        #expect(withVisits.quietTime.pendingQuietSeeds == state.quietTime.pendingQuietSeeds)
        #expect(state.quietTime.pendingQuietSeeds == 4)
    }

    @Test func endingAPassEarlyResumesQuietAtOnce() throws {
        var state = PofuState()
        let first = try attempt(at: noon, in: &state)
        let record = try gatekeeper.resolve(first, with: .pay(minutes: 15), at: noon, state: &state)
        let pass = try #require(record.outcome.pass)
        gatekeeper.endPass(id: pass.id, at: noon.adding(minutes: 3), state: &state)
        #expect(state.quietTime.quietSince == noon.adding(minutes: 3))
        gatekeeper.advanceQuietTime(to: noon.adding(minutes: 33), state: &state)
        #expect(state.quietTime.pendingQuietSeeds == 3)
    }

    @Test func endingOnePassWhileAnotherRunsWaitsForTheOther() throws {
        var state = PofuState()
        let first = try attempt(at: noon, in: &state)
        let record = try gatekeeper.resolve(first, with: .pay(minutes: 5), at: noon, state: &state)
        let short = try #require(record.outcome.pass)
        let decision = gatekeeper.beginCheckIn(for: "youtube", at: noon.adding(minutes: 1), state: &state)
        guard case .intervene(let other) = decision else {
            Issue.record("Expected an intervention")
            return
        }
        try gatekeeper.resolve(other, with: .pay(minutes: 5), at: noon.adding(minutes: 1), state: &state)
        gatekeeper.endPass(id: short.id, at: noon.adding(minutes: 2), state: &state)
        #expect(state.quietTime.quietSince == noon.adding(minutes: 6))
    }

    @Test func aVoidedPassGivesQuietBackFromItsGrant() throws {
        var state = PofuState()
        let first = try attempt(at: noon, in: &state)
        let record = try gatekeeper.resolve(first, with: .pay(minutes: 10), at: noon.adding(minutes: 12), state: &state)
        let pass = try #require(record.outcome.pass)
        #expect(state.quietTime.quietSince == noon.adding(minutes: 22))
        gatekeeper.voidPass(id: pass.id, state: &state)
        #expect(state.quietTime.quietSince == noon.adding(minutes: 12))
    }

    @Test func theFirstSignOfLifeDuringAPassStartsQuietWhenThePassEnds() {
        var passes = PassLedger()
        passes.grant(Pass(target: testTarget, grantedAt: noon, minutes: 15, source: .friendApproved))
        var ledger = QuietTimeLedger()
        accrual.recordSignal(at: noon.adding(minutes: 1), in: &ledger, passes: passes)
        #expect(ledger.quietSince == noon.adding(minutes: 15))
        #expect(accrual.advance(&ledger, to: noon.adding(minutes: 35)).quietSeeds == 2)
    }

    // MARK: - Bedtime

    @Test func bedtimeDoesNotCountAndAQuietNightEarnsTheBonus() {
        var ledger = signaled(at: instant(2026, 11, 2, 22))
        let result = accrual.advance(&ledger, to: instant(2026, 11, 3, 6, 30))
        // 22:00–23:00 and 06:00–06:30.
        #expect(result.quietSeeds == 9)
        #expect(result.sleepBonus == 10)
        #expect(ledger.pending == 19)
        #expect(ledger.lastSleepBonusDay == LocalDay(year: 2026, month: 11, day: 3))
    }

    @Test func theBonusArrivesOnlyOnceTheWindowHasEnded() {
        var ledger = signaled(at: instant(2026, 11, 2, 22))
        #expect(accrual.advance(&ledger, to: instant(2026, 11, 3, 5, 59)).sleepBonus == .zero)
        #expect(accrual.advance(&ledger, to: instant(2026, 11, 3, 6)).sleepBonus == 10)
        #expect(accrual.advance(&ledger, to: instant(2026, 11, 3, 18)).sleepBonus == .zero)
        #expect(ledger.pendingSleepBonus == 10)
    }

    @Test func blocksStartAfreshWhenBedtimeEnds() {
        // 22:55: half a block before bedtime is lost, 06:00 starts anew.
        var ledger = signaled(at: instant(2026, 11, 2, 22, 55))
        #expect(accrual.advance(&ledger, to: instant(2026, 11, 3, 6, 9)).quietSeeds == .zero)
        #expect(accrual.advance(&ledger, to: instant(2026, 11, 3, 6, 10)).quietSeeds == 1)
    }

    @Test func anOpenDuringTheNightForfeitsTheBonus() throws {
        var state = PofuState()
        let first = try attempt(at: instant(2026, 11, 2, 21), in: &state)
        try gatekeeper.resolve(first, with: .resist, at: instant(2026, 11, 2, 21), state: &state)
        let night = try attempt(at: instant(2026, 11, 3, 2), in: &state)
        try gatekeeper.resolve(night, with: .proceed, at: instant(2026, 11, 3, 2), state: &state)
        let result = gatekeeper.advanceQuietTime(to: instant(2026, 11, 3, 7), state: &state)
        #expect(result.sleepBonus == .zero)
        #expect(result.quietSeeds == 6)
        #expect(state.quietTime.pendingSleepBonus == .zero)
    }

    @Test func aResistDuringTheNightKeepsTheBonus() throws {
        var state = PofuState()
        let first = try attempt(at: instant(2026, 11, 2, 21), in: &state)
        try gatekeeper.resolve(first, with: .resist, at: instant(2026, 11, 2, 21), state: &state)
        let night = try attempt(at: instant(2026, 11, 3, 2), in: &state)
        try gatekeeper.resolve(night, with: .resist, at: instant(2026, 11, 3, 2), state: &state)
        gatekeeper.advanceQuietTime(to: instant(2026, 11, 3, 7), state: &state)
        #expect(state.quietTime.pendingSleepBonus == 10)
    }

    @Test func aPassRunningIntoBedtimeForfeitsTheBonus() throws {
        var state = PofuState()
        let late = try attempt(at: instant(2026, 11, 2, 22, 58), in: &state)
        try gatekeeper.resolve(late, with: .proceed, at: instant(2026, 11, 2, 22, 58), state: &state)
        gatekeeper.advanceQuietTime(to: instant(2026, 11, 3, 7), state: &state)
        #expect(state.quietTime.pendingSleepBonus == .zero)
        // The next night is quiet again.
        gatekeeper.advanceQuietTime(to: instant(2026, 11, 4, 7), state: &state)
        #expect(state.quietTime.pendingSleepBonus == 10)
    }

    @Test func aBedtimeThatDoesNotCrossMidnightWorksToo() {
        let early = QuietTimeAccrual(
            bedtime: DailyWindow(start: LocalTime(hour: 0, minute: 30), end: LocalTime(hour: 7)),
            calendar: .istanbul
        )
        var ledger = signaled(at: instant(2026, 11, 2, 23), using: early)
        let result = early.advance(&ledger, to: instant(2026, 11, 3, 7, 30))
        // 23:00–00:30 and 07:00–07:30.
        #expect(result.quietSeeds == 12)
        #expect(result.sleepBonus == 10)
        #expect(ledger.quietSeeds(on: LocalDay(year: 2026, month: 11, day: 2)) == 6)
        #expect(ledger.quietSeeds(on: LocalDay(year: 2026, month: 11, day: 3)) == 6)
    }

    @Test func bedtimeFollowsDaylightSavingTime() {
        let berlin = QuietTimeAccrual(calendar: .berlin)
        // Clocks go back at 03:00 on 2026-10-25: the night lasts 8 hours.
        let evening = instant(2026, 10, 24, 22, in: .berlin)
        var ledger = signaled(at: evening, using: berlin)
        let result = berlin.advance(&ledger, to: instant(2026, 10, 25, 7, in: .berlin))
        #expect(result.quietSeeds == 12)
        #expect(result.sleepBonus == 10)
    }

    // MARK: - Midnight and the daily cap

    @Test func aStretchCarriesAcrossMidnightAndEachBlockCountsForTheDayItStarted() {
        let allDay = withoutBedtime()
        var ledger = signaled(at: instant(2026, 11, 2, 23, 55), using: allDay)
        allDay.advance(&ledger, to: instant(2026, 11, 3, 0, 25))
        #expect(ledger.quietSeeds(on: LocalDay(year: 2026, month: 11, day: 2)) == 1)
        #expect(ledger.quietSeeds(on: LocalDay(year: 2026, month: 11, day: 3)) == 2)
        #expect(ledger.pendingQuietSeeds == 3)
    }

    @Test func theDailyCapStopsQuietSeedsAndReportsTheRest() {
        let allDay = withoutBedtime()
        var ledger = signaled(at: instant(2026, 11, 2, 0), using: allDay)
        let result = allDay.advance(&ledger, to: instant(2026, 11, 3, 0))
        #expect(result.quietSeeds == 48)
        #expect(result.forfeitedToCap == Energy(96))
        // A new day, a new cap.
        #expect(allDay.advance(&ledger, to: instant(2026, 11, 3, 2)).quietSeeds == 12)
        #expect(ledger.pendingQuietSeeds == 60)
    }

    @Test func theSleepBonusDoesNotUseUpTheCap() {
        let rules = QuietTimeRules(dailyCap: 6)
        let capped = QuietTimeAccrual(rules: rules, calendar: .istanbul)
        var ledger = signaled(at: instant(2026, 11, 2, 21), using: capped)
        let result = capped.advance(&ledger, to: instant(2026, 11, 3, 7))
        #expect(result.quietSeeds == 12)
        #expect(result.sleepBonus == 10)
    }

    // MARK: - Observation and held seeds

    @Test func silenceLongerThanTheWindowStopsAccrualAndHoldsTheSeeds() {
        let allDay = withoutBedtime(QuietTimeRules(dailyCap: 1_000))
        var ledger = signaled(at: noon, using: allDay)
        let threeDaysLater = noon.adding(hours: 72)
        allDay.advance(&ledger, to: noon.adding(hours: 100))
        #expect(ledger.pendingQuietSeeds == 432)
        #expect(allDay.isObserving(ledger, at: threeDaysLater.adding(minutes: -1)))
        #expect(!allDay.isObserving(ledger, at: threeDaysLater))
        #expect(allDay.isAwaitingSignOfLife(ledger, at: threeDaysLater))
        #expect(allDay.isHolding(ledger, at: noon.adding(hours: 100)))

        var wallet = Wallet()
        #expect(allDay.collect(&ledger, into: &wallet, at: noon.adding(hours: 100)) == nil)
        #expect(wallet.balance == .zero)
        #expect(ledger.pendingQuietSeeds == 432)
    }

    @Test func theNextSignOfLifeReleasesHeldSeedsButSilentTimeNeverCounts() {
        let allDay = withoutBedtime(QuietTimeRules(dailyCap: 1_000))
        var ledger = signaled(at: noon, using: allDay)
        let back = noon.adding(hours: 100)
        allDay.recordSignal(at: back, in: &ledger, passes: PassLedger())
        #expect(ledger.observedSince == back)
        #expect(!allDay.isHolding(ledger, at: back))
        #expect(!allDay.isAwaitingSignOfLife(ledger, at: back))
        // Quiet carries on (nothing opened), but counts again only from now.
        #expect(allDay.quietStretch(ledger, at: back) == TimeInterval(360_000))
        #expect(allDay.advance(&ledger, to: back.adding(minutes: 20)).quietSeeds == 2)

        var wallet = Wallet()
        let collected = allDay.collect(&ledger, into: &wallet, at: back.adding(minutes: 20))
        #expect(collected?.quietSeeds == 434)
        #expect(wallet.balance == 434)
        #expect(ledger.pending == .zero)
    }

    @Test func signsOfLifeInsideTheWindowKeepObservationUnbroken() {
        let allDay = withoutBedtime(QuietTimeRules(dailyCap: 1_000))
        var ledger = signaled(at: noon, using: allDay)
        allDay.recordSignal(at: noon.adding(hours: 70), in: &ledger, passes: PassLedger())
        #expect(ledger.observedSince == noon)
        allDay.advance(&ledger, to: noon.adding(hours: 100))
        #expect(ledger.pendingQuietSeeds == 600)
        #expect(allDay.isObserving(ledger, at: noon.adding(hours: 100)))
    }

    @Test func aNightPofuCouldNotWatchEarnsNoBonus() {
        // The only sign of life was at 21:00 on the 2nd: observation lapses
        // at 21:00 on the 5th, so the fourth night is not watched.
        var ledger = signaled(at: instant(2026, 11, 2, 21))
        let result = accrual.advance(&ledger, to: instant(2026, 11, 6, 7))
        #expect(result.sleepBonus == 30)
        #expect(ledger.lastSleepBonusDay == LocalDay(year: 2026, month: 11, day: 5))
    }

    // MARK: - Collecting

    @Test func collectingMovesTheCheeksToTheBalance() throws {
        var state = PofuState()
        let first = try attempt(at: instant(2026, 11, 2, 21), in: &state)
        try gatekeeper.resolve(first, with: .resist, at: instant(2026, 11, 2, 21), state: &state)
        let morning = instant(2026, 11, 3, 8)
        let balanceBefore = state.wallet.balance
        let collection = try #require(gatekeeper.collectQuietSeeds(at: morning, state: &state))
        // The new day's allowance arrives first; 21:00–23:00 and 06:00–08:00
        // are 24 seeds, plus the night.
        #expect(collection == QuietCollection(quietSeeds: 24, sleepBonus: 10))
        #expect(state.wallet.balance == balanceBefore + 15 + 34)
        #expect(state.quietTime.pending == .zero)
        // Quiet seeds are not activity: vitality's activity score is untouched.
        #expect(state.wallet.activityEnergy(on: LocalDay(year: 2026, month: 11, day: 3)) == .zero)
        #expect(gatekeeper.collectQuietSeeds(at: morning, state: &state) == nil)
    }

    @Test func automationRunsAreSignsOfLife() {
        var state = PofuState()
        gatekeeper.noteAutomationRan(at: noon, state: &state)
        #expect(state.quietTime.lastSignalAt == noon)
        #expect(state.quietTime.quietSince == noon)
        #expect(state.checkIns.isEmpty)
    }

    // MARK: - Switches, bootstrap, and coding

    @Test func zeroRulesSwitchQuietEarningOff() {
        let off = QuietTimeAccrual(rules: QuietTimeRules(blockMinutes: 0, sleepBonus: 0), calendar: .istanbul)
        var ledger = signaled(at: instant(2026, 11, 2, 12), using: off)
        #expect(off.advance(&ledger, to: instant(2026, 11, 4, 12)) == QuietAccrual())
    }

    @Test func anEmptyBedtimeHasNoNightsToReward() {
        let allDay = withoutBedtime()
        var ledger = signaled(at: instant(2026, 11, 2, 20), using: allDay)
        #expect(allDay.advance(&ledger, to: instant(2026, 11, 3, 8)).sleepBonus == .zero)
        #expect(allDay.bedtimeIntervals(from: noon, to: noon.adding(hours: 48)).isEmpty)
        #expect(allDay.wakingSegments(from: noon, to: noon.adding(hours: 48)).count == 1)
    }

    @Test func bootstrapStartsFromTheLastSignOfLifeAndTheLastPass() throws {
        var history = PofuState()
        let first = try attempt(at: noon, in: &history)
        try gatekeeper.resolve(first, with: .proceed, at: noon, state: &history)
        var ledger = QuietTimeLedger()
        accrual.bootstrap(&ledger, lastSignal: noon.adding(minutes: 2), checkIns: history.checkIns)
        #expect(ledger.quietSince == noon.adding(minutes: 5))
        #expect(ledger.observedSince == noon.adding(minutes: 2))
        #expect(accrual.advance(&ledger, to: noon.adding(minutes: 35)).quietSeeds == 3)
        // Once the ledger has heard from the automation, bootstrap is a no-op.
        let before = ledger
        accrual.bootstrap(&ledger, lastSignal: noon.adding(hours: 5), checkIns: [])
        #expect(ledger == before)
    }

    @Test func theLedgerRoundTripsAndToleratesMissingFields() throws {
        var ledger = signaled(at: instant(2026, 11, 2, 21))
        accrual.advance(&ledger, to: instant(2026, 11, 3, 7))
        let decoded = try JSONDecoder().decode(QuietTimeLedger.self, from: JSONEncoder().encode(ledger))
        #expect(decoded == ledger)
        #expect(try JSONDecoder().decode(QuietTimeLedger.self, from: Data("{}".utf8)) == QuietTimeLedger())
    }

    @Test func stateWithoutQuietTimeDecodesToAFreshLedger() throws {
        var state = PofuState()
        let first = try attempt(at: noon, in: &state)
        try gatekeeper.resolve(first, with: .resist, at: noon, state: &state)
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        #expect(object["quietTime"] != nil)
        object.removeValue(forKey: "quietTime")
        let decoded = try JSONDecoder().decode(PofuState.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded.quietTime == QuietTimeLedger())
        #expect(decoded.checkIns == state.checkIns)
    }

    @Test func configurationWithoutQuietTimeDecodesWithDefaults() throws {
        let standard = EconomyConfiguration.standard
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(standard)) as? [String: Any])
        object.removeValue(forKey: "quietTime")
        let decoded = try JSONDecoder().decode(EconomyConfiguration.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded == standard)
        #expect(decoded.quietTime == QuietTimeRules())
        #expect(decoded.quietTime.dailyCap == 48)
    }
}
