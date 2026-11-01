import Foundation
import Testing
@testable import PofuCore

@Suite("Check-in routing")
struct CheckInRouterTests {
    let router = CheckInRouter()
    let noon = instant(2026, 11, 2, 12)

    func ledger(with passes: Pass...) -> PassLedger {
        PassLedger(passes: passes)
    }

    @Test func aValidPassPassesThroughSilently() {
        let pass = Pass(target: ProtectedApp.instagram.target, grantedAt: noon, minutes: 10, source: .purchased(price: 10))
        let route = router.route(for: .instagram, at: noon.adding(minutes: 9.9), passes: ledger(with: pass), presenting: nil)
        #expect(route == .passThrough(pass))
        #expect(router.plan(for: route, isForeground: false, canContinueInForeground: true) == .completeSilently(pass))
        #expect(router.plan(for: route, isForeground: true, canContinueInForeground: true) == .completeSilently(pass))
    }

    @Test func aPassWinsEvenOverAHopOnScreen() {
        let pass = Pass(target: ProtectedApp.youtube.target, grantedAt: noon, minutes: 5, source: .free(.pause))
        #expect(router.route(for: .youtube, at: noon, passes: ledger(with: pass), presenting: .youtube) == .passThrough(pass))
    }

    @Test func passesArePerApp() {
        let pass = Pass(target: ProtectedApp.instagram.target, grantedAt: noon, minutes: 10, source: .friendApproved)
        #expect(router.route(for: .tiktok, at: noon, passes: ledger(with: pass), presenting: nil) == .hop)
    }

    @Test func anExpiredPassNoLongerCovers() {
        let pass = Pass(target: ProtectedApp.instagram.target, grantedAt: noon, minutes: 5, source: .emergency)
        #expect(router.route(for: .instagram, at: noon.adding(minutes: 5), passes: ledger(with: pass), presenting: nil) == .hop)
    }

    @Test func aRepeatedFireForTheHopOnScreenIsIgnored() {
        let route = router.route(for: .instagram, at: noon, passes: PassLedger(), presenting: .instagram)
        #expect(route == .alreadyPresenting)
        #expect(router.plan(for: route, isForeground: true, canContinueInForeground: true) == .ignore)
        #expect(router.route(for: .tiktok, at: noon, passes: PassLedger(), presenting: .instagram) == .hop)
    }

    @Test func hopNeedsTheForeground() {
        #expect(router.plan(for: .hop, isForeground: true, canContinueInForeground: false) == .startHop)
        #expect(router.plan(for: .hop, isForeground: false, canContinueInForeground: true) == .continueInForegroundThenStartHop)
        #expect(router.plan(for: .hop, isForeground: false, canContinueInForeground: false) == .cannotStartHop)
    }

    @Test func theGateRecordsPassThroughsAndPrunesOldHistory() throws {
        let gatekeeper = Gatekeeper(economy: Economy(calendar: .istanbul))
        var state = PofuState()
        let longAgo = instant(2026, 9, 1, 12)
        state.checkIns = [
            CheckInRecord(id: UUID(), target: testTarget, attemptedAt: longAgo, resolvedAt: longAgo, rung: .pause, outcome: .resisted)
        ]
        state.passThroughs = [PassThrough(target: testTarget, at: longAgo, passID: UUID())]

        guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: noon, state: &state) else {
            Issue.record("Expected an intervention")
            return
        }
        #expect(state.checkIns.isEmpty)
        #expect(state.passThroughs.isEmpty)

        let record = try gatekeeper.resolve(attempt, with: .proceed, at: noon, state: &state, reason: .bored)
        #expect(record.reason == .bored)
        let pass = try #require(record.outcome.pass)
        #expect(gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(minutes: 2), state: &state) == .covered(pass))
        #expect(state.passThroughs == [PassThrough(target: testTarget, at: noon.adding(minutes: 2), passID: pass.id)])
    }
}

@Suite("Protected apps")
struct ProtectedAppTests {
    @Test func rawValuesAreStableBecauseTheyArePersisted() {
        #expect(ProtectedApp.allCases.map(\.rawValue) == [
            "instagram", "youtube", "tiktok", "x", "snapchat", "reddit", "facebook", "other",
        ])
        #expect(Set(ProtectedApp.allCases.map(\.target)).count == ProtectedApp.allCases.count)
    }

    @Test func everyNamedAppCanBeOpenedByPofu() {
        for app in ProtectedApp.allCases where app != .other {
            #expect(app.brandName != nil)
            #expect(!app.launchURLs.isEmpty)
            #expect(app.universalLink?.scheme == "https")
            #expect(app.canBeOpenedByPofu)
        }
        #expect(ProtectedApp.other.brandName == nil)
        #expect(!ProtectedApp.other.canBeOpenedByPofu)
    }

    @Test func queriedSchemesAreUniqueAndWellFormed() {
        let schemes = ProtectedApp.allQueriedSchemes
        #expect(Set(schemes).count == schemes.count)
        #expect(schemes.count <= 50, "iOS honors at most 50 LSApplicationQueriesSchemes entries")
        for scheme in schemes {
            #expect(scheme == scheme.lowercased())
            #expect(scheme.first?.isLetter == true)
            #expect(scheme.allSatisfy { $0.isLetter || $0.isNumber || "+-.".contains($0) })
        }
        #expect(ProtectedApp.instagram.launchURLs.first?.absoluteString == "instagram://")
        #expect(ProtectedApp.tiktok.urlSchemes.first == "snssdk1233")
    }
}

@Suite("User profile")
struct UserProfileTests {
    @Test func namesAreTrimmedCappedAndNeverEmpty() {
        #expect(UserProfile.sanitizedName("  Fıstık \n") == "Fıstık")
        #expect(UserProfile.sanitizedName("   ") == "Pofu")
        #expect(UserProfile.sanitizedName("") == "Pofu")
        #expect(UserProfile.sanitizedName(String(repeating: "a", count: 50)).count == UserProfile.maximumNameLength)
        var profile = UserProfile(companionName: "Lokum")
        profile.companionName = "   "
        #expect(profile.companionName == "Pofu")
    }

    @Test func aCheckInVerifiesItsAppAndAddsItWhenMissing() {
        var profile = UserProfile(protectedApps: [.instagram])
        let noon = instant(2026, 11, 2, 12)
        #expect(!profile.isVerified(.instagram))
        profile.recordCheckIn(from: .instagram, at: noon)
        profile.recordCheckIn(from: .youtube, at: noon)
        #expect(profile.isVerified(.instagram))
        #expect(profile.protectedApps == [.instagram, .youtube])
        // An older timestamp never moves the last check-in back.
        profile.recordCheckIn(from: .instagram, at: noon.adding(hours: -1))
        #expect(profile.lastCheckIn[.instagram] == noon)
    }

    @Test func roundTripsAndToleratesUnknownApps() throws {
        let noon = instant(2026, 11, 2, 12)
        let profile = UserProfile(
            companionName: "Mochi",
            protectedApps: [.instagram, .tiktok],
            hasCompletedOnboarding: true,
            lastCheckIn: [.instagram: noon]
        )
        let data = try JSONEncoder().encode(profile)
        #expect(try JSONDecoder().decode(UserProfile.self, from: data) == profile)

        let future = Data(#"{"companionName":"Mochi","protectedApps":["instagram","threads"]}"#.utf8)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: future)
        #expect(decoded.protectedApps == [.instagram])
        #expect(!decoded.hasCompletedOnboarding)

        let empty = try JSONDecoder().decode(UserProfile.self, from: Data("{}".utf8))
        #expect(empty == UserProfile())
    }
}

@Suite("Beads and reaches")
struct BeadsTests {
    let calendar = Calendar.istanbul
    let noon = instant(2026, 11, 2, 12)

    func record(_ minutes: Double, _ outcome: CheckInOutcome) -> CheckInRecord {
        let at = noon.adding(minutes: minutes)
        return CheckInRecord(id: UUID(), target: testTarget, attemptedAt: at, resolvedAt: at, rung: .pause, outcome: outcome)
    }

    @Test func beadsFollowTheOrderOfTheDay() {
        let pass = Pass(target: testTarget, grantedAt: noon, minutes: 5, source: .free(.pause))
        let records = [
            record(30, .resisted),
            record(-30, .proceeded(pass)),
            record(10, .resisted),
            record(-24 * 60, .resisted),
        ]
        let today = LocalDay(containing: noon, in: calendar)
        #expect(ImpulseMetrics.beads(on: today, from: records, calendar: calendar) == [.opened, .skipped, .skipped])
    }

    @Test func reachOrdinalCountsTheLastHour() {
        let records = [record(-90, .resisted), record(-50, .resisted), record(-5, .resisted)]
        #expect(ImpulseMetrics.reachOrdinal(at: noon, from: records) == 3)
        #expect(ImpulseMetrics.reachOrdinal(at: noon, from: []) == 1)
    }

    @Test func theWholeStateRoundTripsThroughJSON() throws {
        let economy = Economy(calendar: calendar)
        let gatekeeper = Gatekeeper(economy: economy)
        var state = PofuState()
        guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: noon, state: &state) else {
            Issue.record("Expected an intervention")
            return
        }
        try gatekeeper.resolve(attempt, with: .pay(minutes: 10), at: noon, state: &state, reason: .habit)
        _ = gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(minutes: 1), state: &state)
        economy.earn(session(25, endingAt: noon.adding(hours: 1)), into: &state.wallet)
        state.vitality.settle(through: economy.day(of: noon), model: VitalityModel()) { _ in VitalityInput() }

        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(PofuState.self, from: data) == state)
        #expect(try JSONDecoder().decode(PofuState.self, from: Data("{}".utf8)) == PofuState())
    }
}
