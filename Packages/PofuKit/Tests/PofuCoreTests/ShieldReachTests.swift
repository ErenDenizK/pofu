import Foundation
import PofuCore
import Testing

private let instagram = ShieldedApp(token: "token-instagram", bundleIdentifier: "com.burbn.instagram", displayName: "Instagram")
private let tiktok = ShieldedApp(token: "token-tiktok", bundleIdentifier: "com.zhiliaoapp.musically", displayName: "TikTok")
private let start = instant(2026, 11, 14, 9, 30)

/// The ledger, check-ins, and passes one test drives through ingestion.
private struct Harness {
    let ingestion = ScreenTimeIngestion(calendar: .istanbul)
    var ledger = ScreenTimeLedger()
    var checkIns: [CheckInRecord] = []
    var passes = PassLedger()

    @discardableResult
    mutating func ingest(_ records: [ScreenTimeRecord], at now: Date) -> [LoggedEvent] {
        ingestion.ingest(records, at: now, into: &ledger, checkIns: &checkIns, passes: &passes)
    }

    mutating func settle(at now: Date) {
        ingestion.settle(at: now, ledger: &ledger, checkIns: &checkIns)
    }

    var metrics: ImpulseMetrics {
        ImpulseMetrics.daily(on: LocalDay(containing: start, in: .istanbul), from: checkIns, calendar: .istanbul)
    }

    var resolutions: [ShieldResolution?] {
        checkIns.map(\.shieldResolution)
    }
}

private func shown(_ app: ShieldedApp = instagram, at date: Date, scene: ShieldScene = .reach) -> ScreenTimeRecord {
    ScreenTimeRecord(at: date, kind: .shieldShown(app: app, scene: scene))
}

private func record(_ kind: ScreenTimeRecord.Kind, at date: Date) -> ScreenTimeRecord {
    ScreenTimeRecord(at: date, kind: kind)
}

@Suite("Gate v2 metrics: every reach counts once")
struct ShieldReachTests {
    @Test func aSkipResolvesTheReachItWasTappedOn() {
        var harness = Harness()
        let seen = shown(at: start)
        harness.ingest([seen, record(.shieldResisted(app: instagram), at: start.addingTimeInterval(2))], at: start.addingTimeInterval(5))
        #expect(harness.checkIns.count == 1)
        #expect(harness.checkIns.first?.id == seen.id)
        #expect(harness.checkIns.first?.attemptedAt == start)
        #expect(harness.resolutions == [.skipped])
        #expect(harness.metrics.attempts == 1)
        #expect(harness.metrics.resisted == 1)
        #expect(harness.ledger.pendingReaches.isEmpty)
    }

    @Test func aShieldLeftWithoutATapIsASilentLeaveAfterAMinute() {
        var harness = Harness()
        harness.ingest([shown(at: start)], at: start.addingTimeInterval(59))
        #expect(harness.checkIns.isEmpty)
        #expect(harness.ledger.pendingReaches.count == 1)

        harness.settle(at: start.addingTimeInterval(60))
        #expect(harness.resolutions == [.silentLeave])
        #expect(harness.checkIns.first?.outcome == .resisted)
        #expect(harness.checkIns.first?.channel == .shield)
        #expect(harness.ledger.pendingReaches.isEmpty)
    }

    @Test func aTapLaterInTheSameBatchStillBelongsToItsShield() {
        var harness = Harness()
        // Both records arrive together long after: the tap wins over time.
        harness.ingest([shown(at: start), record(.shieldResisted(app: instagram), at: start.adding(minutes: 3))], at: start.adding(minutes: 30))
        #expect(harness.resolutions == [.skipped])
    }

    @Test func anOpenRequestThatHopAnswersIsCountedByHopAlone() throws {
        var harness = Harness()
        harness.ingest([shown(at: start), record(.openRequested(app: instagram), at: start.addingTimeInterval(3))], at: start.addingTimeInterval(20))
        #expect(harness.checkIns.isEmpty)
        let taken = harness.ledger.takeOpenRequest(at: start.addingTimeInterval(30), maximumAge: 600)
        let request = try #require(taken)
        #expect(request.app == instagram)
        #expect(harness.ledger.pendingReaches.isEmpty)
        // Hop! records its own check-in; nothing is left to resolve.
        harness.settle(at: start.adding(minutes: 30))
        #expect(harness.checkIns.isEmpty)
    }

    @Test func anOpenRequestNeverFollowedIsResistedAfterItsLifetime() {
        var harness = Harness()
        harness.ingest([shown(at: start), record(.openRequested(app: instagram), at: start.addingTimeInterval(3))], at: start.addingTimeInterval(20))
        harness.settle(at: start.addingTimeInterval(3 + 600))
        #expect(harness.checkIns.isEmpty)
        harness.settle(at: start.addingTimeInterval(3 + 601))
        #expect(harness.resolutions == [.abandonedRequest])
        #expect(harness.metrics.resisted == 1)
        #expect(harness.ledger.openRequest == nil)
        #expect(harness.ledger.pendingReaches.isEmpty)
    }

    @Test func aRequestWithoutAShownRecordIsStillOneReach() {
        var harness = Harness()
        harness.ingest([record(.openRequested(app: instagram), at: start)], at: start.adding(minutes: 11))
        #expect(harness.resolutions == [.abandonedRequest])
        #expect(harness.metrics.attempts == 1)
    }

    @Test func skippingWhileWaitingCancelsTheRequestAndResists() {
        var harness = Harness()
        harness.ingest(
            [
                shown(at: start),
                record(.openRequested(app: instagram), at: start.addingTimeInterval(3)),
                shown(at: start.addingTimeInterval(4), scene: .waiting),
                record(.openRequestCancelled(app: instagram), at: start.addingTimeInterval(9)),
            ],
            at: start.addingTimeInterval(10)
        )
        #expect(harness.resolutions == [.requestCancelled])
        #expect(harness.ledger.openRequest == nil)
        #expect(harness.metrics.attempts == 1)
        #expect(harness.metrics.resisted == 1)
    }

    @Test func theWaitingRedrawIsNotANewReach() {
        var harness = Harness()
        harness.ingest(
            [
                shown(at: start),
                record(.openRequested(app: instagram), at: start.addingTimeInterval(3)),
                shown(at: start.adding(minutes: 1), scene: .waiting),
            ],
            at: start.adding(minutes: 2)
        )
        #expect(harness.ledger.pendingReaches.count == 1)
    }

    @Test func theShieldThatReturnsAtAPassEndIsNotAReach() {
        var harness = Harness()
        harness.ingest(
            [
                shown(at: start, scene: .passEnded),
                record(.passEndedClosed(app: instagram), at: start.addingTimeInterval(2)),
                shown(tiktok, at: start.adding(minutes: 1), scene: .passEnded),
            ],
            at: start.adding(minutes: 5)
        )
        // "Bitti, kapat" is not a skip, and leaving it is not a silent leave.
        #expect(harness.checkIns.isEmpty)
        #expect(harness.metrics.attempts == 0)
    }

    @Test func aBreathShieldIsAReach() {
        var harness = Harness()
        harness.ingest([shown(at: start, scene: .breath)], at: start.adding(minutes: 2))
        #expect(harness.resolutions == [.silentLeave])
    }

    @Test func redrawsWithinTenSecondsAreOneReach() {
        var harness = Harness()
        harness.ingest([shown(at: start), shown(at: start.addingTimeInterval(9))], at: start.addingTimeInterval(9))
        #expect(harness.ledger.pendingReaches.count == 1)
        harness.ingest([shown(at: start.addingTimeInterval(20))], at: start.addingTimeInterval(20))
        #expect(harness.ledger.pendingReaches.count == 2)
        harness.settle(at: start.adding(minutes: 5))
        #expect(harness.metrics.attempts == 2)
    }

    @Test func aShieldAndAHopForTheSameOpenCountOnce() {
        var harness = Harness()
        // Hop! (the soft gate) already met this open.
        harness.checkIns.append(
            CheckInRecord(id: UUID(), target: instagram.target, attemptedAt: start, resolvedAt: start.addingTimeInterval(4), rung: .pause, outcome: .resisted)
        )
        harness.ingest([shown(at: start.addingTimeInterval(2))], at: start.adding(minutes: 5))
        #expect(harness.metrics.attempts == 1)
    }

    @Test func aHopRecordedAfterTheShieldWasIngestedStillCountsOnce() {
        var harness = Harness()
        harness.ingest([shown(at: start)], at: start.addingTimeInterval(1))
        harness.checkIns.append(
            CheckInRecord(id: UUID(), target: instagram.target, attemptedAt: start.addingTimeInterval(3), resolvedAt: start.addingTimeInterval(8), rung: .pause, outcome: .resisted)
        )
        harness.settle(at: start.adding(minutes: 5))
        #expect(harness.metrics.attempts == 1)
        #expect(harness.ledger.pendingReaches.isEmpty)
    }

    @Test func aQuickCheckIsAnOpenWithAPass() throws {
        var harness = Harness()
        let passID = UUID()
        let until = start.adding(minutes: 3)
        harness.ingest(
            [shown(at: start), record(.quickCheckStarted(app: instagram, passID: passID, until: until), at: start.addingTimeInterval(2))],
            at: start.addingTimeInterval(10)
        )
        #expect(harness.resolutions == [.quickCheck])
        #expect(harness.metrics.attempts == 1)
        #expect(harness.metrics.resisted == 0)
        #expect(harness.metrics.proceeded == 1)
        let pass = try #require(harness.passes.validPass(for: ProtectedApp.instagram.target, at: start.adding(minutes: 1)))
        #expect(pass.id == passID)
        #expect(pass.expiresAt == until)
        // The returning shield and its "Bitti, kapat" add nothing.
        harness.ingest([shown(at: until.addingTimeInterval(30), scene: .passEnded), record(.passEndedClosed(app: instagram), at: until.addingTimeInterval(35))], at: until.adding(minutes: 5))
        #expect(harness.metrics.attempts == 1)
    }

    @Test func aSkipWithoutAShownRecordIsStillCounted() {
        var harness = Harness()
        harness.ingest([record(.shieldResisted(app: instagram), at: start)], at: start)
        #expect(harness.resolutions == [.skipped])
    }

    @Test func eachAppKeepsItsOwnReach() {
        var harness = Harness()
        harness.ingest(
            [shown(at: start), shown(tiktok, at: start.addingTimeInterval(1)), record(.shieldResisted(app: tiktok), at: start.addingTimeInterval(3))],
            at: start.addingTimeInterval(5)
        )
        #expect(harness.checkIns.map(\.target) == [tiktok.target])
        #expect(harness.ledger.pendingReaches.map(\.app) == [instagram])
    }

    @Test func aDayOfReachesAddsUp() {
        var harness = Harness()
        var records: [ScreenTimeRecord] = []
        // 1: skip. 2: silent leave. 3: request, abandoned. 4: quick check.
        // 5: request, cancelled. 6: expiry shield closed (not a reach).
        records.append(shown(at: start))
        records.append(record(.shieldResisted(app: instagram), at: start.addingTimeInterval(1)))
        records.append(shown(at: start.adding(minutes: 10)))
        records.append(shown(at: start.adding(minutes: 20)))
        records.append(record(.openRequested(app: instagram), at: start.adding(minutes: 20).addingTimeInterval(2)))
        records.append(shown(tiktok, at: start.adding(minutes: 40)))
        records.append(record(.quickCheckStarted(app: tiktok, passID: UUID(), until: start.adding(minutes: 43)), at: start.adding(minutes: 40).addingTimeInterval(2)))
        records.append(shown(tiktok, at: start.adding(minutes: 43).addingTimeInterval(20), scene: .passEnded))
        records.append(record(.passEndedClosed(app: tiktok), at: start.adding(minutes: 43).addingTimeInterval(25)))
        records.append(shown(at: start.adding(minutes: 60)))
        records.append(record(.openRequested(app: instagram), at: start.adding(minutes: 60).addingTimeInterval(2)))
        records.append(record(.openRequestCancelled(app: instagram), at: start.adding(minutes: 60).addingTimeInterval(8)))
        harness.ingest(records, at: start.adding(minutes: 120))

        #expect(harness.metrics.attempts == 5)
        #expect(harness.metrics.resisted == 4)
        #expect(harness.metrics.proceeded == 1)
        #expect(Set(harness.resolutions.compactMap { $0 }) == Set(ShieldResolution.allCases))
        let readout = GateReadout.days(endingOn: LocalDay(containing: start, in: .istanbul), count: 1, from: harness.checkIns, calendar: .istanbul)
        let today = readout.first
        #expect(today?.reaches == 5)
        #expect(today?.shieldSkips == 1)
        #expect(today?.silentLeaves == 1)
        #expect(today?.abandonedRequests == 1)
        #expect(today?.cancelledRequests == 1)
        #expect(today?.quickChecks == 1)
        #expect(today?.resistedByTap == 2)
    }

    @Test func overLimitOpensCountPerDay() {
        var ledger = ScreenTimeLedger()
        let day = LocalDay(year: 2026, month: 11, day: 14)
        let first = ledger.noteOverLimitOpen(on: day)
        let second = ledger.noteOverLimitOpen(on: day)
        let nextDay = ledger.noteOverLimitOpen(on: day.adding(days: 1))
        #expect(first == 1)
        #expect(second == 2)
        #expect(nextDay == 1)
        #expect(ledger.overLimitOpens(on: day) == 0)
    }
}

@Suite("Gate v2 rules")
struct ScreenTimeGateRulesTests {
    @Test func theDefaultsAreTheSpecs() {
        let rules = ScreenTimeGateRules.standard
        #expect(rules.dailyHourMinutes == 60)
        #expect(rules.quickCheckMinutes == 3)
        #expect(rules.quickCheckChainInterval == 20 * 60)
        #expect(rules.openRequestLifetime == 10 * 60)
        #expect(rules.silentLeaveDelay == 60)
        #expect(rules.reachDeduplicationWindow == 10)
        #expect(rules.softGateOverlapWindow == 5)
        #expect(EconomyConfiguration.standard.gate == rules)
    }

    @Test func theLadderReachesTheChosenDailyHour() {
        #expect(GuardedUsageLadder.standard.stepsMinutes == [15, 30, 45, 60])
        #expect(ScreenTimeGateRules.standard.withDailyHour(50).ladder.stepsMinutes == [15, 30, 45, 50])
        #expect(ScreenTimeGateRules.standard.withDailyHour(15).ladder.stepsMinutes == [15])
        let long = ScreenTimeGateRules.standard.withDailyHour(180).ladder
        #expect(long.stepsMinutes.count == 12)
        #expect(long.breathLimitMinutes == 180)
        #expect(long.isBreathLimitReached(measuredMinutes: 180))
        #expect(!long.isBreathLimitReached(measuredMinutes: 165))
    }

    @Test func theDailyHourIsClamped() {
        #expect(ScreenTimeGateRules.standard.withDailyHour(5).dailyHourMinutes == 15)
        #expect(ScreenTimeGateRules.standard.withDailyHour(500).dailyHourMinutes == 180)
        #expect(ScreenTimeGateRules.standard.withDailyHour(nil).dailyHourMinutes == 60)
        var profile = UserProfile()
        profile.dailyHourMinutes = 999
        #expect(profile.dailyHourMinutes == 180)
    }

    @Test func theDailyHourRoundTripsInTheProfile() throws {
        let profile = UserProfile(dailyHourMinutes: 90)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: JSONEncoder().encode(profile))
        #expect(decoded.dailyHourMinutes == 90)
        let old = try JSONDecoder().decode(UserProfile.self, from: Data(#"{"companionName":"Pofu"}"#.utf8))
        #expect(old.dailyHourMinutes == nil)
    }

    @Test func theMonitorReadsAnyStep() {
        #expect(GuardedUsageLadder.parseMinutes(fromThresholdName: "pofu.usage.105") == 105)
        #expect(GuardedUsageLadder.parseMinutes(fromThresholdName: "pofu.usage.0") == nil)
        #expect(GuardedUsageLadder.parseMinutes(fromThresholdName: "pofu.pass.15") == nil)
    }

    @Test func theBreathGetsLongFromTheFourthOpen() {
        let rules = ScreenTimeGateRules.standard
        #expect(rules.breathSeconds(forOverLimitOpen: 1) == 5)
        #expect(rules.breathSeconds(forOverLimitOpen: 3) == 5)
        #expect(rules.breathSeconds(forOverLimitOpen: 4) == 10)
    }

    @Test func aConfigurationWithoutGateRulesLoads() throws {
        var data = try JSONEncoder().encode(EconomyConfiguration.standard)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["gate"] = nil
        data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(EconomyConfiguration.self, from: data)
        #expect(decoded.gate == .standard)
    }
}
