import Foundation
import Testing
@testable import PofuCore

@Suite("Honor sessions in progress")
struct ActiveSessionTests {
    let economy = Economy(calendar: .istanbul)
    let start = instant(2026, 11, 2, 9)

    @Test func aCompletedTimerEarnsItsPlannedMinutes() {
        let running = ActiveSession(kind: .focus, startedAt: start, plannedMinutes: 25)
        #expect(!running.isComplete(at: start.adding(minutes: 24.9)))
        #expect(running.isComplete(at: start.adding(minutes: 25)))
        // Opened hours later: credited up to the planned end only.
        let session = running.completed(at: start.adding(hours: 5))
        #expect(session.wholeMinutes == 25)
        #expect(session.verification == .honor)
        var wallet = Wallet()
        #expect(economy.earn(session, into: &wallet).earned == 12)
    }

    @Test func endingEarlyKeepsTheWholeMinutesSoFar() {
        let running = ActiveSession(kind: .study, startedAt: start, plannedMinutes: 45)
        let session = running.completed(at: start.adding(minutes: 12.7))
        #expect(session.wholeMinutes == 12)
        #expect(economy.grossEnergy(for: session) == 6)
        #expect(running.remaining(at: start.adding(minutes: 12.7)) > 0)
        #expect(running.remaining(at: start.adding(hours: 1)) == 0)
    }

    @Test func aClockBeforeTheStartEarnsNothing() {
        let running = ActiveSession(kind: .focus, startedAt: start, plannedMinutes: 25)
        #expect(running.completed(at: start.adding(minutes: -10)).wholeMinutes == 0)
        #expect(ActiveSession(kind: .focus, startedAt: start, plannedMinutes: -5).plannedMinutes == 0)
    }
}
