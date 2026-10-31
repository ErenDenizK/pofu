import Foundation
import Testing
@testable import PofuCompanion

@Suite("Companion springs")
struct CompanionSpringTests {
    @Test func criticallyDampedSpringSettlesWithoutOvershoot() {
        var spring = CompanionSpring(value: 0, response: 0.5, dampingFraction: 1)
        spring.target = 1
        var peak = 0.0
        for _ in 0..<240 {
            spring.step(1.0 / 120)
            peak = max(peak, spring.value)
        }
        #expect(peak <= 1.0005)
        #expect(spring.isSettled(tolerance: 1e-3))
    }

    @Test func underdampedSpringOvershootsThenSettles() {
        var spring = CompanionSpring(value: 0, response: 0.42, dampingFraction: 0.28)
        spring.target = 1
        var peak = 0.0
        for _ in 0..<120 {
            spring.step(1.0 / 120)
            peak = max(peak, spring.value)
        }
        #expect(peak > 1.2, "a squishy spring should wobble past its target")
        for _ in 0..<600 {
            spring.step(1.0 / 120)
        }
        #expect(abs(spring.value - 1) < 1e-3)
    }

    @Test func aLongHitchStaysStable() {
        var spring = CompanionSpring(value: 0, response: 0.2, dampingFraction: 0.3)
        spring.target = 1
        spring.step(5) // a five-second stall must not explode
        #expect(spring.value.isFinite)
        #expect(abs(spring.value) < 3)
    }

    @Test func invalidDurationsAreIgnored() {
        var spring = CompanionSpring(value: 0.5, response: 0.5, dampingFraction: 1)
        spring.target = 1
        spring.step(.nan)
        spring.step(-1)
        spring.step(0)
        #expect(spring.value == 0.5)
    }
}

@Suite("Breathing and squash")
struct BreathingAndSquashTests {
    @Test func lowVitalityBreathesSlowerAndDeeper() {
        #expect(BreathingCurve.period(vitality: 0) > BreathingCurve.period(vitality: 1))
        #expect(BreathingCurve.amplitude(vitality: 0) > BreathingCurve.amplitude(vitality: 1))
        #expect(BreathingCurve.period(vitality: -3) == BreathingCurve.period(vitality: 0))
        #expect(BreathingCurve.period(vitality: .nan) == BreathingCurve.period(vitality: 0))
    }

    @Test(arguments: stride(from: 0.0, through: 2 * Double.pi, by: Double.pi / 8).map { $0 })
    func breathingStaysWithinAmplitudeAndIsAreaNeutral(phase: Double) {
        let scales = BreathingCurve.scales(phase: phase, vitality: 0.5)
        let amplitude = BreathingCurve.amplitude(vitality: 0.5)
        #expect(abs(scales.y - 1) <= amplitude + 1e-12)
        // Taller means narrower: the body never just inflates uniformly.
        #expect((scales.y - 1) * (scales.x - 1) <= 0)
    }

    @Test func breathStartsAtFullExhale() {
        #expect(BreathingCurve.signal(phase: 0) == -1)
        #expect(abs(BreathingCurve.signal(phase: .pi) - 1) < 1e-12)
    }

    @Test(arguments: [-0.24, -0.1, 0.0, 0.1, 0.2])
    func fullPreservationKeepsArea(squash: Double) {
        let scales = SquashModel.scales(squash: squash, preservation: 1)
        #expect(abs(scales.x * scales.y - 1) < 1e-12)
    }

    @Test func squashIsClampedToWhatTheArtSurvives() {
        #expect(SquashModel.scales(squash: -5).y == 1 + SquashModel.range.lowerBound)
        #expect(SquashModel.scales(squash: 5).y == 1 + SquashModel.range.upperBound)
        let invalid = SquashModel.scales(squash: .nan)
        #expect(invalid.x == 1 && invalid.y == 1)
    }

    @Test func squashedBodiesGetWider() {
        let squashed = SquashModel.scales(squash: -0.2)
        let stretched = SquashModel.scales(squash: 0.2)
        #expect(squashed.x > 1 && squashed.y < 1)
        #expect(stretched.x < 1 && stretched.y > 1)
    }

    @Test func slumpIsGentleAndOnlyAtLowVitality() {
        let full = SquashModel.slump(vitality: 1)
        #expect(full.x == 1 && full.y == 1)
        let low = SquashModel.slump(vitality: 0)
        #expect(low.y >= 0.93 && low.y < 1)
        #expect(low.x > 1)
    }
}

@Suite("Blinks and lids")
struct BlinkAndLidTests {
    @Test func blinkClosesFastHoldsAndOpensSlowly() {
        #expect(BlinkCurve.closure(elapsed: 0) == 0)
        #expect(BlinkCurve.closure(elapsed: BlinkCurve.closeDuration + 0.01) == 1)
        #expect(BlinkCurve.closure(elapsed: BlinkCurve.totalDuration + 0.01) == 0)
        #expect(BlinkCurve.closure(elapsed: -1) == 0)
        #expect(BlinkCurve.openDuration > BlinkCurve.closeDuration)
    }

    @Test func blinkClosureIsMonotonicWhileClosing() {
        var previous = 0.0
        for step in 0...20 {
            let value = BlinkCurve.closure(elapsed: BlinkCurve.closeDuration * Double(step) / 20)
            #expect(value >= previous - 1e-12)
            previous = value
        }
    }

    @Test func openEyesHaveNoLids() {
        let lids = LidModel(closure: 0, happiness: 0, sadness: 0, outerSide: 1)
        for x in stride(from: -0.95, through: 0.95, by: 0.05) {
            let band = lids.openBand(x)
            #expect(band != nil)
            #expect(abs((band?.lowerBound ?? 0) + LidModel.rim(x)) < 1e-9)
            #expect(abs((band?.upperBound ?? 0) - LidModel.rim(x)) < 1e-9)
        }
    }

    @Test func closedEyesAreShutEverywhere() {
        let lids = LidModel(closure: 1, happiness: 0, sadness: 0, outerSide: -1)
        for x in stride(from: -0.95, through: 0.95, by: 0.05) {
            #expect(lids.openBand(x) == nil)
        }
    }

    @Test func happyEyesLeaveAThinArchAtTheTop() {
        let lids = LidModel(closure: 0.1, happiness: 1, sadness: 0, outerSide: 1)
        let band = lids.openBand(0)
        #expect(band != nil)
        if let band {
            #expect(band.upperBound - band.lowerBound < 0.5)
            #expect(band.lowerBound < -0.7, "the sliver sits at the top of the eye: a ^ shape")
        }
    }

    @Test func sadLidsDroopTowardTheOuterCorner() {
        for side in [-1.0, 1.0] {
            let lids = LidModel(closure: 0.4, happiness: 0, sadness: 1, outerSide: side)
            let outer = lids.upper(0.7 * side)
            let inner = lids.upper(-0.7 * side)
            #expect(outer > inner, "y points down, so the outer lid edge is lower")
        }
    }
}
