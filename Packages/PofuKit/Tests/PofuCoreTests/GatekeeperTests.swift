import Foundation
import Testing
@testable import PofuCore

@Suite("Gatekeeper")
struct GatekeeperTests {
    let gatekeeper = Gatekeeper(economy: Economy(calendar: .istanbul))
    let noon = instant(2026, 11, 2, 12)

    /// Begins a check-in and requires an intervention.
    func intervention(
        for target: TargetGroupID = testTarget,
        at date: Date,
        in state: inout PofuState
    ) throws -> CheckInAttempt {
        let decision = gatekeeper.beginCheckIn(for: target, at: date, state: &state)
        guard case .intervene(let attempt) = decision else {
            Issue.record("Expected an intervention, got \(decision)")
            throw CancellationError()
        }
        return attempt
    }

    @Test func firstOpenPausesAndGrantsTheAllowance() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        #expect(attempt.rung == .pause)
        #expect(attempt.ladderRung == .pause)
        #expect(attempt.cheapestPrice == 5)
        #expect(state.wallet.balance == 15)
    }

    @Test func proceedingOnAFreeRungGrantsAShortFreePass() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        let record = try gatekeeper.resolve(attempt, with: .proceed, at: noon.adding(minutes: 0.5), state: &state)
        let pass = try #require(record.outcome.pass)
        #expect(pass.source == .free(.pause))
        #expect(pass.expiresAt == noon.adding(minutes: 5.5))
        #expect(state.passes.passes == [pass])
        #expect(state.checkIns == [record])
        #expect(state.wallet.balance == 15)
    }

    @Test func openingDuringAValidPassIsCoveredAndNotAnAttempt() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        let record = try gatekeeper.resolve(attempt, with: .proceed, at: noon, state: &state)
        let ladderBefore = state.ladder

        let pass = try #require(record.outcome.pass)
        let decision = gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(minutes: 3), state: &state)
        #expect(decision == .covered(pass))
        #expect(state.ladder == ladderBefore)
        #expect(state.checkIns.count == 1)
    }

    @Test func aPassCoversOnlyItsOwnTarget() throws {
        var state = PofuState()
        let attempt = try intervention(for: "instagram", at: noon, in: &state)
        try gatekeeper.resolve(attempt, with: .proceed, at: noon, state: &state)
        let other = try intervention(for: "youtube", at: noon.adding(minutes: 1), in: &state)
        #expect(other.rung == .intent)
    }

    @Test func repeatedOpensClimbFromPauseToPay() throws {
        var state = PofuState()
        let first = try intervention(at: noon, in: &state)
        try gatekeeper.resolve(first, with: .proceed, at: noon, state: &state)
        // The free pass lasts 5 minutes; reopen at minute 10.
        let second = try intervention(at: noon.adding(minutes: 10), in: &state)
        #expect(second.rung == .intent)
        try gatekeeper.resolve(second, with: .proceed, at: noon.adding(minutes: 10), state: &state)
        let third = try intervention(at: noon.adding(minutes: 20), in: &state)
        #expect(third.rung == .pay)
    }

    @Test func proceedingForFreeIsNotAvailableOnThePayRung() throws {
        var state = PofuState()
        for minute in [0.0, 1] {
            let attempt = try intervention(at: noon.adding(minutes: minute), in: &state)
            try gatekeeper.resolve(attempt, with: .resist, at: noon.adding(minutes: minute), state: &state)
        }
        let paying = try intervention(at: noon.adding(minutes: 2), in: &state)
        #expect(paying.rung == .pay)
        let error = capturedError {
            try gatekeeper.resolve(paying, with: .proceed, at: noon.adding(minutes: 2), state: &state)
        }
        #expect(error as? CheckInError == .choiceNotAvailable(.proceed, rung: .pay))
        #expect(state.checkIns.count == 2)
    }

    @Test func payingBuysTheChosenWindow() throws {
        var state = PofuState()
        for minute in [0.0, 1] {
            let attempt = try intervention(at: noon.adding(minutes: minute), in: &state)
            try gatekeeper.resolve(attempt, with: .resist, at: noon.adding(minutes: minute), state: &state)
        }
        let paying = try intervention(at: noon.adding(minutes: 2), in: &state)
        let record = try gatekeeper.resolve(paying, with: .pay(minutes: 10), at: noon.adding(minutes: 2), state: &state)
        #expect(record.outcome.pass?.source == .purchased(price: 10))
        #expect(state.wallet.balance == 5)
        #expect(state.passes.hasValidPass(for: testTarget, at: noon.adding(minutes: 11)))
    }

    @Test func payingIsAlsoAllowedOnFreeRungs() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        let record = try gatekeeper.resolve(attempt, with: .pay(minutes: 15), at: noon, state: &state)
        #expect(record.outcome.pass?.expiresAt == noon.adding(minutes: 15))
        #expect(state.wallet.balance == .zero)
    }

    @Test func emptyBalanceOnThePayRungRequiresAFriend() throws {
        var state = PofuState()
        state.wallet.balance = .zero
        state.wallet.lastAllowanceDay = gatekeeper.economy.day(of: noon)
        for minute in [0.0, 1] {
            let attempt = try intervention(at: noon.adding(minutes: minute), in: &state)
            try gatekeeper.resolve(attempt, with: .resist, at: noon.adding(minutes: minute), state: &state)
        }
        let stuck = try intervention(at: noon.adding(minutes: 2), in: &state)
        #expect(stuck.ladderRung == .pay)
        #expect(stuck.rung == .askFriend)

        let payError = capturedError {
            try gatekeeper.resolve(stuck, with: .pay(minutes: 5), at: noon.adding(minutes: 2), state: &state)
        }
        #expect(payError as? CheckInError == .spend(.insufficientBalance(required: 5, available: .zero)))

        let record = try gatekeeper.resolve(stuck, with: .friendApproved(minutes: 10), at: noon.adding(minutes: 3), state: &state)
        guard case .friendApproved(let pass) = record.outcome else {
            Issue.record("Expected a friend approval, got \(record.outcome)")
            return
        }
        #expect(pass.source == .friendApproved)
        #expect(pass.expiresAt == noon.adding(minutes: 13))
        #expect(state.wallet.balance == .zero)
    }

    @Test func friendApprovalIsOnlyForTheAskFriendRung() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        let error = capturedError {
            try gatekeeper.resolve(attempt, with: .friendApproved(minutes: 10), at: noon, state: &state)
        }
        #expect(error as? CheckInError == .choiceNotAvailable(.friendApproved(minutes: 10), rung: .pause))
    }

    @Test func friendApprovalMustUseAnOfferedDuration() throws {
        var state = PofuState()
        state.wallet.balance = .zero
        state.wallet.lastAllowanceDay = gatekeeper.economy.day(of: noon)
        var strict = gatekeeper.economy.configuration
        strict.friction.highestAttemptRung = .askFriend
        let strictGate = Gatekeeper(economy: Economy(configuration: strict, calendar: .istanbul))
        var attempt: CheckInAttempt?
        for minute in 0..<4 {
            if case .intervene(let next) = strictGate.beginCheckIn(for: testTarget, at: noon.adding(minutes: Double(minute)), state: &state) {
                attempt = next
            }
        }
        let asking = try #require(attempt)
        #expect(asking.rung == .askFriend)
        let error = capturedError {
            try strictGate.resolve(asking, with: .friendApproved(minutes: 45), at: noon.adding(minutes: 4), state: &state)
        }
        #expect(error as? CheckInError == .spend(.unsupportedDuration(minutes: 45)))
    }

    @Test func resistingIsAlwaysAvailableAndGrantsNothing() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        let record = try gatekeeper.resolve(attempt, with: .resist, at: noon.adding(minutes: 1), state: &state)
        #expect(record.outcome == .resisted)
        #expect(record.outcome.isResisted)
        #expect(record.id == attempt.id)
        #expect(record.attemptedAt == noon)
        #expect(record.resolvedAt == noon.adding(minutes: 1))
        #expect(state.passes.passes.isEmpty)
    }

    @Test func expiredPassesAreClearedOnCheckIn() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        try gatekeeper.resolve(attempt, with: .proceed, at: noon, state: &state)
        _ = gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(hours: 2), state: &state)
        #expect(state.passes.passes.isEmpty)
    }

    @Test func stateRoundTripsThroughJSON() throws {
        var state = PofuState()
        let attempt = try intervention(at: noon, in: &state)
        try gatekeeper.resolve(attempt, with: .pay(minutes: 5), at: noon, state: &state)
        gatekeeper.economy.earn(session(30, .passive, kind: .walk, endingAt: noon.adding(hours: 1)), into: &state.wallet)
        let decoded = try JSONDecoder().decode(PofuState.self, from: JSONEncoder().encode(state))
        #expect(decoded == state)
    }
}

@Suite("Impulse metrics")
struct ImpulseMetricsTests {
    func record(_ outcome: CheckInOutcome, at date: Date) -> CheckInRecord {
        CheckInRecord(id: UUID(), target: testTarget, attemptedAt: date, resolvedAt: date, rung: .pause, outcome: outcome)
    }

    @Test func noAttemptsHasNoRatio() {
        let metrics = ImpulseMetrics()
        #expect(metrics.attempts == 0)
        #expect(metrics.resistedRatio == nil)
    }

    @Test func countsEveryOutcome() {
        let pass = Pass(target: testTarget, grantedAt: .distantPast, minutes: 5, source: .free(.pause))
        var metrics = ImpulseMetrics()
        metrics.record(.resisted)
        metrics.record(.resisted)
        metrics.record(.resisted)
        metrics.record(.proceeded(pass))
        metrics.record(.friendApproved(pass))
        #expect(metrics == ImpulseMetrics(attempts: 5, resisted: 3, proceeded: 1, friendApproved: 1))
        #expect(metrics.opened == 2)
        #expect(metrics.resistedRatio == 0.6)
    }

    @Test func dailyMetricsUseTheLocalDayOfTheAttempt() {
        let pass = Pass(target: testTarget, grantedAt: .distantPast, minutes: 5, source: .free(.pause))
        let records = [
            record(.resisted, at: instant(2026, 11, 2, 23, 59)),
            record(.proceeded(pass), at: instant(2026, 11, 3, 0, 0)),
            record(.resisted, at: instant(2026, 11, 3, 22)),
            record(.resisted, at: instant(2026, 11, 4, 1)),
        ]
        let nov3 = ImpulseMetrics.daily(on: LocalDay(year: 2026, month: 11, day: 3), from: records, calendar: .istanbul)
        #expect(nov3 == ImpulseMetrics(attempts: 2, resisted: 1, proceeded: 1))
        #expect(nov3.resistedRatio == 0.5)
        let nov2 = ImpulseMetrics.daily(on: LocalDay(year: 2026, month: 11, day: 2), from: records, calendar: .istanbul)
        #expect(nov2.resistedRatio == 1)
    }
}
