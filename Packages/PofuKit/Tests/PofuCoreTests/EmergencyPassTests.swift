import Foundation
import Testing
@testable import PofuCore

@Suite("Emergency pass")
struct EmergencyPassTests {
    let economy = Economy(calendar: .istanbul)
    var gatekeeper: Gatekeeper { Gatekeeper(economy: economy) }
    let noon = instant(2026, 11, 2, 12)

    /// Climbs the ladder to the `pay` rung with two quick skips.
    func payAttempt(at date: Date, in state: inout PofuState, gatekeeper: Gatekeeper) throws -> CheckInAttempt {
        for offset in 0..<2 {
            let at = date.adding(minutes: Double(offset))
            guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: at, state: &state) else {
                Issue.record("Expected an intervention")
                throw CancellationError()
            }
            try gatekeeper.resolve(attempt, with: .resist, at: at, state: &state)
        }
        guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: date.adding(minutes: 2), state: &state) else {
            Issue.record("Expected an intervention")
            throw CancellationError()
        }
        return attempt
    }

    @Test func isFreeShortAndDoesNotEscalatePrices() throws {
        var state = PofuState()
        let attempt = try payAttempt(at: noon, in: &state, gatekeeper: gatekeeper)
        #expect(attempt.rung == .pay)
        let at = noon.adding(minutes: 2)

        let record = try gatekeeper.resolve(attempt, with: .emergency, at: at, state: &state)
        let pass = try #require(record.outcome.pass)
        #expect(pass.source == .emergency)
        #expect(pass.durationMinutes == 3)
        #expect(pass.expiresAt == at.adding(minutes: 3))
        #expect(state.wallet.balance == 15)
        #expect(state.wallet.unlockPurchases.isEmpty)
        #expect(try economy.quote(minutes: 10, at: at, for: state.wallet).escalationSteps == 0)
        #expect(state.passes.hasValidPass(for: testTarget, at: at.adding(minutes: 2.9)))
        #expect(!state.passes.hasValidPass(for: testTarget, at: at.adding(minutes: 3)))
    }

    @Test func worksOncePerLocalDay() throws {
        var state = PofuState()
        let first = try payAttempt(at: noon, in: &state, gatekeeper: gatekeeper)
        try gatekeeper.resolve(first, with: .emergency, at: noon.adding(minutes: 2), state: &state)
        let recorded = state.checkIns.count

        // Later the same day, the ladder is back on the pay rung.
        let second = try payAttempt(at: noon.adding(hours: 3), in: &state, gatekeeper: gatekeeper)
        let error = capturedError {
            try gatekeeper.resolve(second, with: .emergency, at: noon.adding(hours: 3), state: &state)
        }
        #expect(error as? CheckInError == .emergencyPassUsed(nextAvailable: LocalDay(year: 2026, month: 11, day: 3)))
        #expect(state.checkIns.count == recorded + 2)

        // The next morning it is back.
        let tomorrow = instant(2026, 11, 3, 8)
        let third = try payAttempt(at: tomorrow, in: &state, gatekeeper: gatekeeper)
        let record = try gatekeeper.resolve(third, with: .emergency, at: tomorrow, state: &state)
        #expect(record.outcome.pass?.source == .emergency)
    }

    @Test func isNotOfferedOnFreeRungs() throws {
        var state = PofuState()
        guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: noon, state: &state) else {
            Issue.record("Expected an intervention")
            return
        }
        #expect(attempt.rung == .pause)
        let error = capturedError {
            try gatekeeper.resolve(attempt, with: .emergency, at: noon, state: &state)
        }
        #expect(error as? CheckInError == .choiceNotAvailable(.emergency, rung: .pause))
        #expect(state.wallet.lastEmergencyPassDay == nil)
    }

    @Test func isTheWayOutWhenOnlyAFriendCouldHelp() throws {
        let broke = Economy(configuration: EconomyConfiguration(dailyAllowance: 0), calendar: .istanbul)
        let gatekeeper = Gatekeeper(economy: broke)
        var state = PofuState()
        let attempt = try payAttempt(at: noon, in: &state, gatekeeper: gatekeeper)
        #expect(attempt.rung == .askFriend)
        let record = try gatekeeper.resolve(attempt, with: .emergency, at: noon.adding(minutes: 2), state: &state)
        #expect(record.outcome.pass?.source == .emergency)
        #expect(state.wallet.balance == 0)
    }

    @Test func neverWorksTwiceWhenTheClockMovesBackwards() {
        var wallet = Wallet()
        let tomorrow = instant(2026, 11, 3, 9)
        #expect(economy.grantEmergencyPass(for: testTarget, at: tomorrow, from: &wallet) != nil)
        #expect(economy.grantEmergencyPass(for: testTarget, at: noon, from: &wallet) == nil)
        #expect(economy.nextEmergencyPassDay(for: wallet, at: noon) == LocalDay(year: 2026, month: 11, day: 4))
    }

    @Test func canBeSwitchedOff() {
        let off = Economy(
            configuration: EconomyConfiguration(friction: FrictionRules(emergencyPassMinutes: 0)),
            calendar: .istanbul
        )
        var wallet = Wallet()
        #expect(!off.isEmergencyPassAvailable(in: wallet, at: noon))
        #expect(off.grantEmergencyPass(for: testTarget, at: noon, from: &wallet) == nil)
    }

    @Test func availabilityCrossesMidnightInLocalTime() {
        var wallet = Wallet()
        let lateNight = instant(2026, 11, 2, 23, 59)
        #expect(economy.grantEmergencyPass(for: testTarget, at: lateNight, from: &wallet) != nil)
        #expect(!economy.isEmergencyPassAvailable(in: wallet, at: instant(2026, 11, 2, 23, 59, 59)))
        #expect(economy.isEmergencyPassAvailable(in: wallet, at: instant(2026, 11, 3, 0, 0)))
    }
}
