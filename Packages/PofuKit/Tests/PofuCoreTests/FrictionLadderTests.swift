import Foundation
import Testing
import PofuCore

@Suite("Friction ladder")
struct FrictionLadderTests {
    let rules = FrictionRules()
    let start = instant(2026, 11, 2, 10)

    @Test func rungsAreOrdered() {
        #expect(FrictionRung.allCases == [.pause, .intent])
        #expect(FrictionRung.pause < .intent)
        #expect(FrictionRung.pause.next == .intent)
        #expect(FrictionRung.intent.next == .intent)
    }

    @Test func recordsFromBeforeThePayRungLeftDecodeAsIntent() throws {
        for legacy in ["2", "3"] {
            let rung = try JSONDecoder().decode(FrictionRung.self, from: Data(legacy.utf8))
            #expect(rung == .intent)
        }
        #expect(try JSONDecoder().decode(FrictionRung.self, from: Data("0".utf8)) == .pause)
    }

    @Test func firstAttemptPauses() {
        var ladder = FrictionLadder()
        let rung = ladder.registerAttempt(at: start, rules: rules)
        #expect(rung == .pause)
        #expect(ladder.lastAttemptAt == start)
    }

    @Test func attemptsInsideTheCooldownClimbUpToIntent() {
        var ladder = FrictionLadder()
        var rungs: [FrictionRung] = []
        for minute in [0.0, 10, 20, 30, 40] {
            rungs.append(ladder.registerAttempt(at: start.adding(minutes: minute), rules: rules))
        }
        #expect(rungs == [.pause, .intent, .intent, .intent, .intent])
    }

    @Test func cooldownIsMeasuredFromTheLastAttempt() {
        var ladder = FrictionLadder()
        ladder.registerAttempt(at: start, rules: rules)
        // 50 minutes later: still inside the cooldown.
        let second = ladder.registerAttempt(at: start.adding(minutes: 50), rules: rules)
        // 100 minutes after the first, but only 50 after the second.
        let third = ladder.registerAttempt(at: start.adding(minutes: 100), rules: rules)
        #expect(second == .intent)
        #expect(third == .intent)
    }

    @Test func aHealthyGapResetsToPause() {
        var ladder = FrictionLadder()
        ladder.registerAttempt(at: start, rules: rules)
        ladder.registerAttempt(at: start.adding(minutes: 5), rules: rules)
        ladder.registerAttempt(at: start.adding(minutes: 10), rules: rules)
        let afterGap = ladder.registerAttempt(at: start.adding(minutes: 75), rules: rules)
        #expect(afterGap == .pause)
    }

    @Test func cooldownBoundaryIsExclusive() {
        var ladder = FrictionLadder()
        ladder.registerAttempt(at: start, rules: rules)
        #expect(ladder.rung(forAttemptAt: start.addingTimeInterval(3_599), rules: rules) == .intent)
        #expect(ladder.rung(forAttemptAt: start.addingTimeInterval(3_600), rules: rules) == .pause)
    }

    @Test func previewDoesNotRecord() {
        var ladder = FrictionLadder()
        ladder.registerAttempt(at: start, rules: rules)
        _ = ladder.rung(forAttemptAt: start.adding(minutes: 1), rules: rules)
        #expect(ladder.lastAttemptAt == start)
        #expect(ladder.lastRung == .pause)
    }

    @Test func clockMovingBackwardsCountsAsInsideTheCooldown() {
        var ladder = FrictionLadder()
        ladder.registerAttempt(at: start, rules: rules)
        let rung = ladder.registerAttempt(at: start.adding(hours: -5), rules: rules)
        #expect(rung == .intent)
    }

    @Test func theDefaultLadderTopsOutAtIntent() {
        #expect(FrictionRules().highestAttemptRung == .intent)
    }

    @Test func highestAttemptRungIsConfigurable() {
        var gentle = FrictionRules()
        gentle.highestAttemptRung = .pause
        var calm = FrictionLadder()
        let calmRungs = (0..<3).map { calm.registerAttempt(at: start.adding(minutes: Double($0)), rules: gentle) }
        #expect(calmRungs == [.pause, .pause, .pause])
    }

    @Test func codableRoundTrip() throws {
        var ladder = FrictionLadder()
        ladder.registerAttempt(at: start, rules: rules)
        ladder.registerAttempt(at: start.adding(minutes: 1), rules: rules)
        let decoded = try JSONDecoder().decode(FrictionLadder.self, from: JSONEncoder().encode(ladder))
        #expect(decoded == ladder)
    }
}

@Suite("Passes")
struct PassTests {
    let now = instant(2026, 11, 2, 14)

    @Test func validityIsHalfOpen() {
        let pass = Pass(target: testTarget, grantedAt: now, minutes: 10, source: .free(.pause))
        #expect(!pass.isValid(at: now.addingTimeInterval(-1)))
        #expect(pass.isValid(at: now))
        #expect(pass.isValid(at: now.adding(minutes: 10).addingTimeInterval(-1)))
        #expect(!pass.isValid(at: now.adding(minutes: 10)))
        #expect(pass.remaining(at: now.adding(minutes: 4)) == 360)
        #expect(pass.remaining(at: now.adding(minutes: 11)) == 0)
    }

    @Test func ledgerAnswersPerTargetAndTime() {
        var ledger = PassLedger()
        ledger.grant(Pass(target: "instagram", grantedAt: now, minutes: 10, source: .purchased(price: 10)))
        #expect(ledger.hasValidPass(for: "instagram", at: now.adding(minutes: 5)))
        #expect(!ledger.hasValidPass(for: "youtube", at: now.adding(minutes: 5)))
        #expect(!ledger.hasValidPass(for: "instagram", at: now.adding(minutes: 10)))
    }

    @Test func ledgerPrefersTheLongestValidPass() {
        let short = Pass(target: testTarget, grantedAt: now, minutes: 5, source: .free(.intent))
        let long = Pass(target: testTarget, grantedAt: now.adding(minutes: 1), minutes: 30, source: .friendApproved)
        let ledger = PassLedger(passes: [short, long])
        #expect(ledger.validPass(for: testTarget, at: now.adding(minutes: 2)) == long)
        #expect(ledger.validPass(for: testTarget, at: now) == short)
    }

    @Test func removeExpiredKeepsCurrentAndFuturePasses() {
        let expired = Pass(target: testTarget, grantedAt: now.adding(minutes: -20), minutes: 10, source: .free(.pause))
        let current = Pass(target: testTarget, grantedAt: now, minutes: 10, source: .free(.pause))
        let future = Pass(target: testTarget, grantedAt: now.adding(minutes: 60), minutes: 10, source: .friendApproved)
        var ledger = PassLedger(passes: [expired, current, future])
        ledger.removeExpired(at: now)
        #expect(ledger.passes == [current, future])
    }

    @Test func revokeEndsEveryPassForATarget() {
        var ledger = PassLedger()
        ledger.grant(Pass(target: "instagram", grantedAt: now, minutes: 10, source: .free(.pause)))
        ledger.grant(Pass(target: "youtube", grantedAt: now, minutes: 10, source: .free(.pause)))
        ledger.revokeAll(for: "instagram")
        #expect(ledger.passes.map(\.target) == ["youtube"])
    }

    @Test func codableRoundTrip() throws {
        let ledger = PassLedger(passes: [
            Pass(target: testTarget, grantedAt: now, minutes: 5, source: .free(.intent)),
            Pass(target: testTarget, grantedAt: now, minutes: 10, source: .purchased(price: 13)),
            Pass(target: testTarget, grantedAt: now, minutes: 15, source: .friendApproved),
        ])
        let decoded = try JSONDecoder().decode(PassLedger.self, from: JSONEncoder().encode(ledger))
        #expect(decoded == ledger)
    }
}
