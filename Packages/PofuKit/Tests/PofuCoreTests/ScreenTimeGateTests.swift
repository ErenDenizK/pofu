import Foundation
import PofuCore
import Testing

private let instagramApp = ShieldedApp(token: "token-instagram", bundleIdentifier: "com.burbn.instagram", displayName: "Instagram")
private let unknownApp = ShieldedApp(token: "token-unknown")
/// A moment long after every record: time has resolved every reach.
private let farFuture = instant(2030, 1, 1)

@Suite("Screen Time records")
struct ScreenTimeRecordTests {
    @Test func everyKindRoundTrips() throws {
        let at = instant(2026, 11, 14, 9, 30)
        let records = [
            ScreenTimeRecord(at: at, kind: .shieldResisted(app: instagramApp)),
            ScreenTimeRecord(at: at, kind: .openRequested(app: unknownApp)),
            ScreenTimeRecord(at: at, kind: .usageThresholdReached(minutes: 45)),
            ScreenTimeRecord(at: at, kind: .shieldRestored(passID: UUID())),
            ScreenTimeRecord(at: at, kind: .shieldShown(app: instagramApp, scene: .reach)),
            ScreenTimeRecord(at: at, kind: .openRequestCancelled(app: instagramApp)),
            ScreenTimeRecord(at: at, kind: .quickCheckStarted(app: unknownApp, passID: UUID(), until: at.adding(minutes: 3))),
            ScreenTimeRecord(at: at, kind: .passEndedClosed(app: instagramApp)),
        ]
        let data = try JSONEncoder().encode(records)
        #expect(try JSONDecoder().decode([ScreenTimeRecord].self, from: data) == records)
    }

    /// The format extensions write today must stay readable: an extension
    /// from one build and the app from another meet in the App Group.
    @Test func versionOneStaysReadable() throws {
        let json = """
            {"version":1,"id":"4B4C3B0E-7D3B-4C47-9B44-1B0C3E1F2A10","at":815000000,
             "kind":{"shieldResisted":{"app":{"kind":"application","token":"abc","bundleIdentifier":"com.burbn.instagram"}}}}
            """
        let record = try JSONDecoder().decode(ScreenTimeRecord.self, from: Data(json.utf8))
        #expect(record.version == 1)
        #expect(record.at == Date(timeIntervalSinceReferenceDate: 815_000_000))
        #expect(record.kind == .shieldResisted(app: ShieldedApp(token: "abc", bundleIdentifier: "com.burbn.instagram")))
    }

    @Test func newerVersionsAreRefusedNotMisread() {
        let json = """
            {"version":3,"id":"4B4C3B0E-7D3B-4C47-9B44-1B0C3E1F2A10","at":0,"kind":{"somethingNew":{}}}
            """
        #expect(throws: ScreenTimeRecordError.unsupportedVersion(3)) {
            try JSONDecoder().decode(ScreenTimeRecord.self, from: Data(json.utf8))
        }
    }

    @Test func passActivityNamesRoundTrip() {
        let passID = UUID()
        let name = ScreenTimeNames.passActivity(passID)
        #expect(ScreenTimeNames.passID(fromActivity: name) == passID)
        #expect(ScreenTimeNames.passID(fromActivity: "pofu.usage.15") == nil)
        #expect(ScreenTimeNames.passID(fromActivity: "pofu.pass.not-a-uuid") == nil)
    }
}

@Suite("Shielded apps")
struct ShieldedAppTests {
    @Test func knownBundleIdentifiersMapToTheirApps() {
        #expect(ProtectedApp(bundleIdentifier: "com.burbn.instagram") == .instagram)
        #expect(ProtectedApp(bundleIdentifier: "com.google.ios.youtube") == .youtube)
        #expect(ProtectedApp(bundleIdentifier: "com.zhiliaoapp.musically") == .tiktok)
        #expect(ProtectedApp(bundleIdentifier: "COM.BURBN.INSTAGRAM") == .instagram)
        #expect(ProtectedApp(bundleIdentifier: "com.apple.mobilesafari") == nil)
    }

    @Test func everyKnownAppHasABundleIdentifier() {
        for app in ProtectedApp.allCases where app != .other {
            #expect(!app.bundleIdentifiers.isEmpty, "\(app) has no bundle identifier")
        }
        #expect(ProtectedApp.other.bundleIdentifiers.isEmpty)
        let all = ProtectedApp.allCases.flatMap(\.bundleIdentifiers)
        #expect(Set(all).count == all.count)
    }

    @Test func knownAppsShareTheSoftGatesTarget() {
        #expect(instagramApp.protectedApp == .instagram)
        #expect(instagramApp.target == ProtectedApp.instagram.target)
    }

    @Test func unknownAppsGetATargetOfTheirOwn() {
        let other = ShieldedApp(token: "token-other")
        #expect(unknownApp.protectedApp == .other)
        #expect(unknownApp.target.rawValue.hasPrefix("shield."))
        #expect(unknownApp.target != other.target)
        #expect(unknownApp.target == ShieldedApp(token: "token-unknown").target)
    }

    @Test func tokenKeysAreStableHexOfFixedLength() {
        // FNV-1a 64 of the empty string is its offset basis.
        #expect(ShieldedApp.key(forToken: "") == "cbf29ce484222325")
        #expect(ShieldedApp.key(forToken: "a") == "af63dc4c8601ec8c")
        let key = ShieldedApp.key(forToken: String(repeating: "x", count: 500))
        #expect(key.count == 16)
        #expect(key.allSatisfy { $0.isHexDigit })
    }
}

@Suite("Guarded usage ladder")
struct GuardedUsageLadderTests {
    let ladder = GuardedUsageLadder.standard

    @Test func measuresInQuarterHoursUpToTheBreathLimit() {
        #expect(ladder.stepsMinutes == [15, 30, 45, 60])
        #expect(ladder.breathLimitMinutes == 60)
        #expect(ladder.thresholds.map(\.seconds) == [900, 1_800, 2_700, 3_600])
    }

    @Test func namesRoundTripToMinutes() {
        for minutes in ladder.stepsMinutes {
            #expect(ladder.minutes(forThresholdName: ladder.thresholdName(forMinutes: minutes)) == minutes)
        }
        #expect(ladder.minutes(forThresholdName: "pofu.usage.20") == nil)
        #expect(ladder.minutes(forThresholdName: "pofu.pass.15") == nil)
        #expect(ladder.minutes(forThresholdName: "pofu.usage.") == nil)
    }

    @Test func theBreathLimitIsReachedAtSixtyMeasuredMinutes() {
        #expect(!ladder.isBreathLimitReached(measuredMinutes: 0))
        #expect(!ladder.isBreathLimitReached(measuredMinutes: 45))
        #expect(ladder.isBreathLimitReached(measuredMinutes: 60))
        #expect(ladder.isBreathLimitReached(measuredMinutes: 75))
    }

    @Test func theNextStepIsTheFirstAboveWhatWasMeasured() {
        #expect(ladder.nextStep(after: 0) == 15)
        #expect(ladder.nextStep(after: 15) == 30)
        #expect(ladder.nextStep(after: 59) == 60)
        #expect(ladder.nextStep(after: 60) == nil)
    }

    @Test func stepsAreSortedAndUnique() {
        let custom = GuardedUsageLadder(stepsMinutes: [60, 15, 15, 0, 30], breathLimitMinutes: 30)
        #expect(custom.stepsMinutes == [15, 30, 60])
    }
}

@Suite("Shield restore timing")
struct ShieldRestoreScheduleTests {
    @Test func aShortPassStretchesToFifteenMinutesAndRestoresOnTheWarning() throws {
        let start = instant(2026, 11, 14, 9, 30)
        let plan = try #require(ShieldRestoreSchedule(liftingAt: start, until: start.adding(minutes: 3)))
        #expect(plan.intervalStart == start)
        #expect(plan.intervalEnd == start.adding(minutes: 15))
        #expect(plan.warningLead == TimeInterval(12 * 60))
        #expect(plan.warningComponents == DateComponents(minute: 12))
        #expect(plan.trigger == .intervalWillEndWarning)
        #expect(plan.restoresAt == start.adding(minutes: 3))
    }

    @Test func aFifteenMinutePassRestoresAtTheIntervalEnd() throws {
        let start = instant(2026, 11, 14, 9, 30)
        let plan = try #require(ShieldRestoreSchedule(liftingAt: start, until: start.adding(minutes: 15)))
        #expect(plan.intervalEnd == start.adding(minutes: 15))
        #expect(plan.warningLead == nil)
        #expect(plan.warningComponents == nil)
        #expect(plan.trigger == .intervalDidEnd)
        #expect(plan.restoresAt == start.adding(minutes: 15))
    }

    @Test func aLongPassUsesItsOwnLength() throws {
        let start = instant(2026, 11, 14, 9, 30)
        let plan = try #require(ShieldRestoreSchedule(liftingAt: start, until: start.adding(minutes: 45)))
        #expect(plan.intervalEnd == start.adding(minutes: 45))
        #expect(plan.trigger == .intervalDidEnd)
    }

    @Test func secondsRoundSoTheShieldNeverReturnsEarly() throws {
        let start = instant(2026, 11, 14, 9, 30, 40)
        let expiry = start.adding(minutes: 5)
        let plan = try #require(ShieldRestoreSchedule(liftingAt: start, until: expiry))
        #expect(plan.intervalStart == instant(2026, 11, 14, 9, 30))
        #expect(plan.restoresAt == instant(2026, 11, 14, 9, 36))
        #expect(plan.warningLead == TimeInterval(9 * 60))
    }

    @Test func theShieldReturnsWithinAMinuteAfterAnyPass() throws {
        let base = instant(2026, 11, 14, 22, 0)
        for offset in stride(from: 0.0, through: 7_200, by: 37) {
            for minutes in [1, 3, 5, 14, 15, 16, 30, 60] {
                let start = base.addingTimeInterval(offset)
                let expiry = start.adding(minutes: Double(minutes))
                let plan = try #require(ShieldRestoreSchedule(liftingAt: start, until: expiry))
                #expect(plan.restoresAt >= expiry)
                #expect(plan.restoresAt.timeIntervalSince(expiry) < 60)
                #expect(plan.intervalEnd.timeIntervalSince(plan.intervalStart) >= ShieldRestoreSchedule.minimumInterval)
                #expect(plan.intervalStart <= start)
            }
        }
    }

    @Test func anEndedPassHasNoSchedule() {
        let start = instant(2026, 11, 14, 9, 30)
        #expect(ShieldRestoreSchedule(liftingAt: start, until: start) == nil)
        #expect(ShieldRestoreSchedule(liftingAt: start, until: start.adding(minutes: -1)) == nil)
    }

    @Test func componentsAreLocalAndMayCrossMidnight() throws {
        let start = instant(2026, 11, 14, 23, 55)
        let plan = try #require(ShieldRestoreSchedule(liftingAt: start, until: start.adding(minutes: 3)))
        let components = plan.intervalComponents(in: .istanbul)
        #expect(components.start == DateComponents(hour: 23, minute: 55, second: 0))
        #expect(components.end == DateComponents(hour: 0, minute: 10, second: 0))
    }
}

@Suite("Shield lifts")
struct ShieldLiftTests {
    @Test func aLiftIsActiveLikeAPass() {
        let start = instant(2026, 11, 14, 9, 30)
        let lift = ShieldLift(passID: UUID(), app: instagramApp, from: start, until: start.adding(minutes: 5))
        #expect(!lift.isActive(at: start.adding(minutes: -1)))
        #expect(lift.isActive(at: start))
        #expect(lift.isActive(at: start.adding(minutes: 4.9)))
        #expect(!lift.isActive(at: start.adding(minutes: 5)))
    }

    @Test func exemptTokensGroupByKindAndSkipTheEndedPass() {
        let start = instant(2026, 11, 14, 9, 30)
        let social = ShieldedApp(kind: .category, token: "category-social")
        let first = ShieldLift(passID: UUID(), app: instagramApp, from: start, until: start.adding(minutes: 5))
        let second = ShieldLift(passID: UUID(), app: social, from: start, until: start.adding(minutes: 15))
        let lifts = [first, second]
        let now = start.adding(minutes: 1)
        #expect(lifts.exemptTokens(at: now) == [.application: ["token-instagram"], .category: ["category-social"]])
        #expect(lifts.exemptTokens(at: now, excluding: first.passID) == [.category: ["category-social"]])
        #expect(lifts.exemptTokens(at: start.adding(minutes: 10)) == [.category: ["category-social"]])
    }
}

@Suite("Screen Time ingestion")
struct ScreenTimeIngestionTests {
    let ingestion = ScreenTimeIngestion(calendar: .istanbul)

    @Test func aSkipAtTheShieldIsAnImpulseResisted() {
        let at = instant(2026, 11, 14, 9, 30)
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        let record = ScreenTimeRecord(at: at, kind: .shieldResisted(app: instagramApp))
        let events = ingestion.ingest([record], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)

        #expect(checkIns.count == 1)
        #expect(checkIns.first?.outcome == .resisted)
        #expect(checkIns.first?.channel == .shield)
        #expect(checkIns.first?.target == ProtectedApp.instagram.target)
        #expect(events.map(\.event) == [.shieldResisted(target: ProtectedApp.instagram.target)])
        let metrics = ImpulseMetrics.daily(on: LocalDay(containing: at, in: .istanbul), from: checkIns, calendar: .istanbul)
        #expect(metrics.attempts == 1)
        #expect(metrics.resisted == 1)
    }

    @Test func recordsAreTakenInOnce() {
        let record = ScreenTimeRecord(at: instant(2026, 11, 14, 9, 30), kind: .shieldResisted(app: instagramApp))
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        ingestion.ingest([record, record], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        ingestion.ingest([record], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        #expect(checkIns.count == 1)
    }

    @Test func rememberedIDsAreBounded() {
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        let records = (0..<300).map { index in
            ScreenTimeRecord(at: instant(2026, 11, 14, 9).addingTimeInterval(Double(index)), kind: .usageThresholdReached(minutes: 15))
        }
        ingestion.ingest(records, at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        #expect(ledger.ingestedIDs.count == ScreenTimeLedger.rememberedRecordCount)
        #expect(ledger.ingestedIDs.last == records.last?.id)
    }

    @Test func measuredMinutesKeepTheDaysHighestStep() {
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        let day = LocalDay(year: 2026, month: 11, day: 14)
        ingestion.ingest(
            [
                ScreenTimeRecord(at: instant(2026, 11, 14, 11), kind: .usageThresholdReached(minutes: 30)),
                ScreenTimeRecord(at: instant(2026, 11, 14, 9), kind: .usageThresholdReached(minutes: 15)),
            ],
            at: farFuture,
            into: &ledger,
            checkIns: &checkIns,
            passes: &passes
        )
        #expect(ledger.measuredMinutes(on: day) == 30)
        // A record that arrives late for an earlier step does not lower it.
        ingestion.ingest([ScreenTimeRecord(at: instant(2026, 11, 14, 12), kind: .usageThresholdReached(minutes: 15))], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        #expect(ledger.measuredMinutes(on: day) == 30)
        #expect(checkIns.isEmpty)
    }

    @Test func aNewDayStartsFromItsOwnMeasurement() {
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        ingestion.ingest([ScreenTimeRecord(at: instant(2026, 11, 14, 23), kind: .usageThresholdReached(minutes: 60))], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        ingestion.ingest([ScreenTimeRecord(at: instant(2026, 11, 15, 8), kind: .usageThresholdReached(minutes: 15))], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        #expect(ledger.measuredMinutes(on: LocalDay(year: 2026, month: 11, day: 15)) == 15)
        #expect(ledger.measuredMinutes(on: LocalDay(year: 2026, month: 11, day: 14)) == 0)
        // Yesterday's late record does not overwrite today.
        ingestion.ingest([ScreenTimeRecord(at: instant(2026, 11, 14, 23, 30), kind: .usageThresholdReached(minutes: 45))], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        #expect(ledger.measuredMinutes(on: LocalDay(year: 2026, month: 11, day: 15)) == 15)
        #expect(GuardedUsageLadder.standard.isBreathLimitReached(measuredMinutes: ledger.measuredMinutes(on: LocalDay(year: 2026, month: 11, day: 15))) == false)
    }

    @Test func theNewestOpenRequestWaitsForPofu() throws {
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        let first = instant(2026, 11, 14, 9, 30)
        ingestion.ingest(
            [
                ScreenTimeRecord(at: first.adding(minutes: 1), kind: .openRequested(app: unknownApp)),
                ScreenTimeRecord(at: first, kind: .openRequested(app: instagramApp)),
            ],
            at: first.adding(minutes: 2),
            into: &ledger,
            checkIns: &checkIns,
            passes: &passes
        )
        let taken = ledger.takeOpenRequest(at: first.adding(minutes: 3), maximumAge: 600)
        let request = try #require(taken)
        #expect(request.app == unknownApp)
        #expect(ledger.openRequest == nil)
        #expect(checkIns.isEmpty)
    }

    @Test func aStaleOpenRequestIsNotAnsweredButCountedAsAbandoned() {
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        let at = instant(2026, 11, 14, 9, 30)
        ingestion.ingest([ScreenTimeRecord(at: at, kind: .openRequested(app: instagramApp))], at: at.adding(minutes: 1), into: &ledger, checkIns: &checkIns, passes: &passes)
        #expect(ledger.takeOpenRequest(at: at.adding(minutes: 11), maximumAge: 600) == nil)
        ingestion.settle(at: at.adding(minutes: 11), ledger: &ledger, checkIns: &checkIns)
        #expect(ledger.openRequest == nil)
        #expect(checkIns.map(\.shieldResolution) == [.abandonedRequest])
    }

    @Test func restoresAreLogged() {
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        let passID = UUID()
        let events = ingestion.ingest([ScreenTimeRecord(at: instant(2026, 11, 14, 9), kind: .shieldRestored(passID: passID))], at: farFuture, into: &ledger, checkIns: &checkIns, passes: &passes)
        #expect(events.map(\.event) == [.shieldRestored(passID: passID)])
    }

    @Test func theLedgerRoundTrips() throws {
        var ledger = ScreenTimeLedger()
        var checkIns: [CheckInRecord] = []
        var passes = PassLedger()
        ingestion.ingest(
            [
                ScreenTimeRecord(at: instant(2026, 11, 14, 9), kind: .usageThresholdReached(minutes: 15)),
                ScreenTimeRecord(at: instant(2026, 11, 14, 9, 5), kind: .openRequested(app: instagramApp)),
            ],
            at: instant(2026, 11, 14, 9, 6),
            into: &ledger,
            checkIns: &checkIns,
            passes: &passes
        )
        ledger.noteOverLimitOpen(on: LocalDay(year: 2026, month: 11, day: 14))
        #expect(!ledger.pendingReaches.isEmpty)
        let decoded = try JSONDecoder().decode(ScreenTimeLedger.self, from: JSONEncoder().encode(ledger))
        #expect(decoded == ledger)
    }

    @Test func aLedgerFromBeforeGateV2Loads() throws {
        let json = """
            {"ingestedIDs":[],"usage":{"day":{"year":2026,"month":11,"day":14},"measuredMinutes":30}}
            """
        let ledger = try JSONDecoder().decode(ScreenTimeLedger.self, from: Data(json.utf8))
        #expect(ledger.pendingReaches.isEmpty)
        #expect(ledger.openRequest == nil)
        #expect(ledger.overLimitOpens(on: LocalDay(year: 2026, month: 11, day: 14)) == 0)
    }

    @Test func checkInsFromBeforeTheShieldReadAsHop() throws {
        let record = CheckInRecord(
            id: UUID(),
            target: "instagram",
            attemptedAt: instant(2026, 11, 14, 9),
            resolvedAt: instant(2026, 11, 14, 9, 1),
            rung: .pause,
            outcome: .resisted
        )
        let data = try JSONEncoder().encode(record)
        #expect(!String(decoding: data, as: UTF8.self).contains("channel"))
        let decoded = try JSONDecoder().decode(CheckInRecord.self, from: data)
        #expect(decoded.channel == nil)
        #expect(decoded.resolvedChannel == .softGate)
    }
}
