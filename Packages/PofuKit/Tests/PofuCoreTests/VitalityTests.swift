import Foundation
import Testing
import PofuCore

@Suite("Vitality")
struct VitalityTests {
    let model = VitalityModel()

    func isClose(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < 1e-9
    }

    @Test(arguments: [(0.0, 1.0), (30.0, 0.75), (60.0, 0.5), (90.0, 0.25), (120.0, 0.0), (600.0, 0.0), (-10.0, 1.0)])
    func usageScoreFallsLinearlyToZeroAtTwiceTheBudget(minutes: Double, expected: Double) {
        #expect(isClose(model.usageScore(distractingMinutes: minutes), expected))
    }

    @Test func resistanceIsTheResistedRatioAndPerfectWithoutAttempts() {
        #expect(model.resistanceScore(ImpulseMetrics()) == 1)
        #expect(model.resistanceScore(ImpulseMetrics(attempts: 4, resisted: 1, proceeded: 3)) == 0.25)
        #expect(model.resistanceScore(ImpulseMetrics(attempts: 3, resisted: 0, proceeded: 3)) == 0)
    }

    @Test(arguments: [(0, 0.0), (30, 0.5), (90, 0.75), (-5, 0.0)])
    func activityScoreHasDiminishingReturns(energy: Int, expected: Double) {
        #expect(isClose(model.activityScore(energy: Energy(energy)), expected))
    }

    @Test func dailyScoreIsTheWeightedMean() {
        let input = VitalityInput(
            distractingMinutes: 60, // U = 0.5
            impulses: ImpulseMetrics(attempts: 4, resisted: 3, proceeded: 1), // R = 0.75
            activityEnergy: 30 // A = 0.5
        )
        // 0.5 × 0.5 + 0.25 × 0.75 + 0.25 × 0.5 = 0.5625
        #expect(isClose(model.dailyScore(input), 0.5625))
    }

    @Test func bestAndWorstDaysHitTheBounds() {
        let perfect = VitalityInput(distractingMinutes: 0, impulses: ImpulseMetrics(), activityEnergy: 1_000_000)
        #expect(model.dailyScore(perfect) > 0.99)
        let worst = VitalityInput(
            distractingMinutes: 600,
            impulses: ImpulseMetrics(attempts: 50, resisted: 0, proceeded: 50),
            activityEnergy: 0
        )
        #expect(model.dailyScore(worst) == 0)
    }

    @Test func emaMovesAFractionOfTheWayEachDay() {
        let worst = VitalityInput(distractingMinutes: 600, impulses: ImpulseMetrics(attempts: 1, proceeded: 1))
        // 1.0 + 0.3 × (0 − 1.0) = 0.7
        #expect(isClose(model.vitality(after: worst, from: 1), 0.7))
        let best = VitalityInput(distractingMinutes: 0, activityEnergy: 1_000_000_000)
        #expect(model.vitality(after: best, from: 0) <= 0.3 + 1e-9)
    }

    @Test func trajectoryConvergesToASteadyHabit() {
        let steady = VitalityInput(
            distractingMinutes: 60,
            impulses: ImpulseMetrics(attempts: 4, resisted: 3, proceeded: 1),
            activityEnergy: 30
        )
        let trajectory = model.trajectory(of: Array(repeating: steady, count: 60))
        #expect(trajectory.count == 60)
        #expect(isClose(trajectory.last ?? 0, 0.5625))
        // Starting at 0.6 and settling at 0.5625, the path never overshoots.
        #expect(trajectory.allSatisfy { $0 >= 0.5625 - 1e-9 && $0 <= 0.6 })
    }

    @Test func oneBadDayCannotWiltAThrivingPofu() {
        let good = VitalityInput(distractingMinutes: 10, impulses: ImpulseMetrics(attempts: 5, resisted: 5), activityEnergy: 60)
        let bad = VitalityInput(distractingMinutes: 300, impulses: ImpulseMetrics(attempts: 20, resisted: 0, proceeded: 20))
        let trajectory = model.trajectory(of: Array(repeating: good, count: 20) + [bad])
        let beforeBadDay = trajectory[19]
        #expect(model.band(for: beforeBadDay) == .thriving)
        #expect(model.band(for: trajectory[20]) != .wilting)
    }

    @Test(arguments: [
        (1.0, VitalityBand.thriving), (0.75, VitalityBand.thriving), (0.7499, VitalityBand.content),
        (0.5, VitalityBand.content), (0.25, VitalityBand.tired), (0.2499, VitalityBand.wilting),
        (0.0, VitalityBand.wilting), (-1.0, VitalityBand.wilting), (2.0, VitalityBand.thriving),
    ])
    func bands(vitality: Double, expected: VitalityBand) {
        #expect(model.band(for: vitality) == expected)
    }

    @Test func degenerateConfigurationsStayInRange() {
        let broken = VitalityModel(rules: VitalityRules(
            dailyBudgetMinutes: 0,
            usageZeroAtBudgetMultiple: -1,
            activityHalfSaturation: -5,
            usageWeight: .nan,
            resistedWeight: -1,
            activityWeight: 0,
            smoothing: 7,
            initialVitality: .infinity
        ))
        let inputs = [
            VitalityInput(distractingMinutes: .nan),
            VitalityInput(distractingMinutes: 50, activityEnergy: 10),
            VitalityInput(distractingMinutes: .infinity, impulses: ImpulseMetrics(attempts: 1, proceeded: 1)),
        ]
        for value in broken.trajectory(of: inputs) {
            #expect(value >= 0 && value <= 1)
        }
    }
}

@Suite("Economy configuration")
struct ConfigurationTests {
    @Test func standardMatchesTheV0Rules() {
        let config = EconomyConfiguration.standard
        #expect(config.dailyAllowance == 15)
        #expect(config.earning.energyPerMinute == 0.5)
        #expect(config.earning.verifiedMultiplier == 1.5)
        #expect(config.earning.honorDailyCap == 120)
        #expect(config.earning.stepsPerEnergy == 500)
        #expect(config.spending.unlockDurations == [5, 10, 15, 30])
        #expect(config.spending.pricePerMinute == 1)
        #expect(config.spending.escalationMultiplier == 1.25)
        #expect(config.spending.escalationWindow == 3 * 3600)
        #expect(config.spending.nightMultiplier == 2)
        #expect(config.spending.bedtime == DailyWindow(start: LocalTime(hour: 23), end: LocalTime(hour: 6)))
        #expect(config.friction.cooldown == 3600)
        #expect(config.friction.highestAttemptRung == .pay)
        #expect(config.friction.freePassMinutes == 5)
        #expect(config.vitality.dailyBudgetMinutes == 60)
        #expect(config.vitality.smoothing == 0.3)
    }

    @Test func roundTripsThroughJSON() throws {
        var config = EconomyConfiguration.standard
        config.dailyAllowance = 20
        config.spending.bedtime = DailyWindow(start: LocalTime(hour: 22, minute: 30), end: LocalTime(hour: 7))
        config.friction.highestAttemptRung = .askFriend
        let data = try JSONEncoder().encode(config)
        #expect(try JSONDecoder().decode(EconomyConfiguration.self, from: data) == config)
    }
}
