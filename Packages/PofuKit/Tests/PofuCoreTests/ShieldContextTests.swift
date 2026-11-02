import Foundation
import PofuCore
import Testing

private let instagram = ShieldedApp(token: "token-instagram", bundleIdentifier: "com.burbn.instagram", displayName: "Instagram")
private let now = instant(2026, 11, 14, 13, 0)
private let today = LocalDay(year: 2026, month: 11, day: 14)

private func inputs(
    appState: ShieldAppState? = ShieldAppState(writtenAt: now.adding(minutes: -30), day: today),
    _ adjust: (inout ShieldContextInputs) -> Void = { _ in }
) -> ShieldContextInputs {
    var inputs = ShieldContextInputs(app: instagram, now: now, calendar: .istanbul, appState: appState, submenuAvailable: true)
    adjust(&inputs)
    return inputs
}

@Suite("Shield context: what the extension knows")
struct ShieldContextInputsTests {
    @Test func theAppsCountsPlusWhatHappenedSince() {
        let state = ShieldAppState(
            writtenAt: now.adding(minutes: -30),
            day: today,
            reachesToday: 6,
            resistedToday: 4,
            recentReaches: [now.adding(minutes: -40), now.adding(minutes: -90)]
        )
        let context = inputs(appState: state) {
            $0.pendingRecords = [
                // Already counted by the app: before it wrote its state.
                ScreenTimeRecord(at: now.adding(minutes: -35), kind: .shieldShown(app: instagram, scene: .reach)),
                ScreenTimeRecord(at: now.adding(minutes: -10), kind: .shieldShown(app: instagram, scene: .reach)),
                ScreenTimeRecord(at: now.adding(minutes: -10), kind: .shieldResisted(app: instagram)),
                ScreenTimeRecord(at: now.adding(minutes: -5), kind: .shieldShown(app: instagram, scene: .waiting)),
            ]
        }.context
        #expect(context.reachesToday == 7)
        #expect(context.resistedToday == 5)
        // -40 and -10 are within the hour, plus this reach.
        #expect(context.reachesThisHour == 3)
    }

    @Test func yesterdaysStateCountsForNothing() {
        let state = ShieldAppState(writtenAt: now.adding(hours: -14), day: today.adding(days: -1), reachesToday: 30, resistedToday: 20, measuredMinutes: 90)
        let context = inputs(appState: state).context
        #expect(context.reachesToday == 0)
        #expect(context.resistedToday == 0)
        #expect(!context.isPastDailyHour)
        #expect(context.reachesThisHour == 1)
    }

    @Test func noStateAtAllStillDrawsAShield() {
        let context = inputs(appState: nil).context
        #expect(context.reachesToday == 0)
        #expect(context.scene == .reach)
        #expect(context.appName == "Instagram")
    }

    @Test func theDailyHourComesFromTheMonitorAtOnce() {
        let state = ShieldAppState(writtenAt: now.adding(minutes: -30), day: today, measuredMinutes: 45, dailyHourMinutes: 60)
        #expect(!inputs(appState: state).context.isPastDailyHour)
        let measured = inputs(appState: state) { $0.measuredUsage = GuardedUsageDay(day: today, measuredMinutes: 60) }.context
        #expect(measured.isPastDailyHour)
        let shortHour = ShieldAppState(writtenAt: now.adding(minutes: -30), day: today, measuredMinutes: 45, dailyHourMinutes: 45)
        #expect(inputs(appState: shortHour).context.isPastDailyHour)
        let yesterday = inputs(appState: state) { $0.measuredUsage = GuardedUsageDay(day: today.adding(days: -1), measuredMinutes: 120) }.context
        #expect(!yesterday.isPastDailyHour)
    }

    @Test func theShieldWaitsForItsOwnRequestOnly() {
        let note = ShieldOpenRequestNote(token: instagram.token, requestedAt: now.adding(minutes: -2), notificationsAllowed: true, breath: false)
        #expect(inputs { $0.openRequest = note }.context.waiting == .notification)
        var off = note
        off.notificationsAllowed = false
        #expect(inputs { $0.openRequest = off }.context.waiting == .byHand)
        var other = note
        other.token = "token-tiktok"
        #expect(inputs { $0.openRequest = other }.context.waiting == nil)
        var old = note
        old.requestedAt = now.adding(minutes: -11)
        #expect(inputs { $0.openRequest = old }.context.waiting == nil)
    }

    @Test func aPassThatJustEndedIsSpokenOfForTwoMinutes() {
        #expect(inputs { $0.endedPass = (end: now.adding(minutes: -1), minutes: 15) }.context.endedPassMinutes == 15)
        #expect(inputs { $0.endedPass = (end: now.adding(minutes: -3), minutes: 15) }.context.endedPassMinutes == nil)
    }

    @Test func theChainRuleWaitsTwentyMinutesAfterAQuickCheck() {
        #expect(inputs().context.quickCheckAllowed)
        #expect(!inputs { $0.lastQuickCheckEnd = now.adding(minutes: -19) }.context.quickCheckAllowed)
        #expect(!inputs { $0.lastQuickCheckEnd = now.adding(minutes: 2) }.context.quickCheckAllowed)
        #expect(inputs { $0.lastQuickCheckEnd = now.adding(minutes: -20) }.context.quickCheckAllowed)
    }

    @Test func bedtimeComesFromTheAppsWindow() {
        let late = ShieldContextInputs(
            app: instagram,
            now: instant(2026, 11, 14, 23, 30),
            calendar: .istanbul,
            appState: ShieldAppState(writtenAt: now, day: today),
            submenuAvailable: true
        )
        #expect(late.context.isBedtime)
        #expect(late.context.hour == 23)
        #expect(!inputs().context.isBedtime)
    }

    @Test func theMemorysJealousBudgetIsForToday() {
        var memory = ShieldMemory()
        let jealous = ShieldCopy.make(context: ShieldContext(appName: "Instagram", reachesThisHour: 3), language: .turkish)
        #expect(jealous.line == .jealous)
        memory.note(jealous, for: instagram.tokenKey, at: now, on: today)
        #expect(memory.jealousLinesToday == 1)
        #expect(memory.lastWasJealous)
        let context = inputs { $0.memory = memory }.context
        #expect(context.lastWasJealous)
        #expect(context.lastTitle == jealous.title)
        // A new day resets the budget.
        let tomorrow = ShieldContextInputs(
            app: instagram,
            now: now.adding(hours: 24),
            calendar: .istanbul,
            appState: nil,
            memory: memory,
            submenuAvailable: true
        ).context
        #expect(tomorrow.jealousLinesToday == 0)
        #expect(!tomorrow.lastWasJealous)
    }
}

@Suite("Shield memory")
struct ShieldMemoryTests {
    @Test func aRedrawWithinSecondsIsTheSameShield() {
        var memory = ShieldMemory()
        let copy = ShieldCopy.make(context: ShieldContext(appName: "Instagram"), language: .turkish)
        memory.note(copy, for: "key", at: now, on: today)
        #expect(memory.recent(for: "key", scene: .reach, at: now.addingTimeInterval(9), window: 10) == copy)
        #expect(memory.recent(for: "key", scene: .reach, at: now.addingTimeInterval(10), window: 10) == nil)
        #expect(memory.recent(for: "key", scene: .waiting, at: now.addingTimeInterval(1), window: 10) == nil)
        #expect(memory.recent(for: "other", scene: .reach, at: now.addingTimeInterval(1), window: 10) == nil)
        #expect(memory.lastShown(for: "key", at: now.adding(minutes: 29), within: 30 * 60) == copy)
        #expect(memory.lastShown(for: "key", at: now.adding(minutes: 31), within: 30 * 60) == nil)
    }

    @Test func waitingShieldsDoNotBreakTheJealousRun() {
        var memory = ShieldMemory()
        let jealous = ShieldCopy.make(context: ShieldContext(reachesThisHour: 3), language: .english)
        let waiting = ShieldCopy.make(context: ShieldContext(waiting: .notification), language: .english)
        let kind = ShieldCopy.make(context: ShieldContext(), language: .english)
        memory.note(jealous, for: "a", at: now, on: today)
        memory.note(waiting, for: "a", at: now.addingTimeInterval(5), on: today)
        #expect(memory.lastWasJealous)
        memory.note(kind, for: "a", at: now.addingTimeInterval(60), on: today)
        #expect(!memory.lastWasJealous)
        #expect(memory.jealousLinesToday == 1)
    }

    @Test func theMemoryRoundTrips() throws {
        var memory = ShieldMemory()
        memory.note(ShieldCopy.make(context: ShieldContext(), language: .turkish), for: "a", at: now, on: today)
        let decoded = try JSONDecoder().decode(ShieldMemory.self, from: JSONEncoder().encode(memory))
        #expect(decoded == memory)
    }
}
