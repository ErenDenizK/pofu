import Foundation
import Testing
@testable import PofuCompanion

@Suite("Companion motion")
struct CompanionMotionTests {
    /// Runs `motion` for `seconds` at 60 fps and returns every pose.
    func run(_ motion: inout CompanionMotion, seconds: Double) -> [CompanionPose] {
        (0..<Int(seconds * 60)).map { _ in
            motion.step(1.0 / 60)
            return motion.pose
        }
    }

    @Test func idlePofuBreathesInPlace() {
        var motion = CompanionMotion(vitality: 0.8, energy: 0.25)
        let poses = run(&motion, seconds: 8)
        let heights = poses.map(\.scaleY)
        #expect((heights.max() ?? 1) > 1.005, "Pofu visibly breathes in")
        #expect((heights.min() ?? 1) < 0.995, "and out")
        #expect(poses.allSatisfy { $0.hop == 0 }, "idle never leaves the ground")
        #expect(poses.allSatisfy { abs($0.lean) < 0.03 }, "sway stays subtle")
    }

    @Test func idlePofuBlinksEveryFewSeconds() {
        var motion = CompanionMotion(vitality: 1, energy: 0.25)
        let poses = run(&motion, seconds: 20)
        var blinks = 0
        var closed = false
        for pose in poses {
            if pose.lidClosure > 0.9, !closed { blinks += 1 }
            closed = pose.lidClosure > 0.9
        }
        #expect((3...10).contains(blinks))
    }

    @Test func tapSquishesThenSpringsBack() {
        var motion = CompanionMotion(vitality: 0.8, energy: 0.25)
        _ = run(&motion, seconds: 1)
        let before = motion.pose.scaleY
        motion.tap()
        let after = run(&motion, seconds: 0.15)
        #expect((after.map(\.scaleY).min() ?? 1) < before - 0.05, "a tap visibly squishes")
        #expect(after.contains { $0.happiness > 0.3 }, "and makes Pofu squint happily")
        let settled = run(&motion, seconds: 3)
        #expect(abs((settled.last?.scaleY ?? 0) - 1) < 0.04)
        #expect((settled.last?.happiness ?? 1) < 0.05)
    }

    @Test func celebrationIsTwoHopsThatLand() {
        var motion = CompanionMotion(vitality: 0.8, energy: 0.25)
        motion.celebrate()
        let poses = run(&motion, seconds: 2.5)
        var takeoffs = 0
        var wasAirborne = false
        for pose in poses {
            let airborne = pose.hop > 0
            if airborne, !wasAirborne { takeoffs += 1 }
            wasAirborne = airborne
        }
        #expect(takeoffs == 2)
        let peak = poses.map(\.hop).max() ?? 0
        #expect(peak > 0.15 && peak < 0.25, "the first hop rises about a fifth of Pofu's height")
        #expect(poses.last?.hop == 0)
        #expect(poses.contains { $0.happiness > 0.9 })
        #expect(poses.contains { $0.shadowScale < 0.6 }, "the shadow shrinks in the air")
    }

    @Test func reduceMotionCelebratesWithoutHopping() {
        var motion = CompanionMotion(vitality: 0.8, energy: 0.25)
        motion.reduceMotion = true
        motion.celebrate()
        let poses = run(&motion, seconds: 2)
        #expect(poses.allSatisfy { $0.hop == 0 })
        #expect(poses.contains { $0.happiness > 0.9 })
        #expect(poses.allSatisfy { $0.furRipple == 0 })
    }

    @Test func vitalityChangesAreContinuousAndMonotonic() {
        var motion = CompanionMotion(vitality: 1, energy: 0.25)
        motion.vitality = 0
        let poses = run(&motion, seconds: 6)
        let saturations = poses.map(\.saturation)
        for (a, b) in zip(saturations, saturations.dropFirst()) {
            #expect(b <= a + 1e-9, "draining never flickers back")
            #expect(a - b < 0.05, "and never jumps within a frame")
        }
        #expect((saturations.last ?? 1) < 0.3)
        #expect((poses.last?.sadness ?? 0) > 0.9)
    }

    @Test func gainingEnergyFillsTheCheeksWithAGulp() {
        var motion = CompanionMotion(vitality: 0.8, energy: 0)
        _ = run(&motion, seconds: 1)
        motion.energy = 1
        let poses = run(&motion, seconds: 2)
        #expect(poses.contains { $0.cheekPuff > 1 }, "the pouches overshoot a little")
        #expect(abs((poses.last?.cheekPuff ?? 0) - 1) < 0.05)
        #expect(poses.prefix(20).contains { $0.scaleY < 0.97 }, "a little gulp")
    }

    @Test func sameSeedSamePerformance() {
        var a = CompanionMotion(seed: 42)
        var b = CompanionMotion(seed: 42)
        let first = run(&a, seconds: 5)
        let second = run(&b, seconds: 5)
        #expect(first == second)
    }

    @Test func posesStayFiniteUnderAbuse() {
        var motion = CompanionMotion(vitality: .nan, energy: -4)
        motion.vitality = .infinity
        motion.energy = .nan
        for _ in 0..<10 {
            motion.tap()
            motion.celebrate()
        }
        motion.step(1000)
        motion.step(.nan)
        let poses = run(&motion, seconds: 3)
        for pose in poses {
            for value in [pose.scaleX, pose.scaleY, pose.lean, pose.hop, pose.cheekPuff, pose.saturation] {
                #expect(value.isFinite)
            }
        }
    }
}
