import Foundation
import Testing
import PofuDesignSystem

@Suite("Haptics palette")
struct HapticsTests {
    @Test func theTableHasTenFeelings() {
        #expect(PofuHapticName.allCases.count == 10)
        #expect(Set(PofuHapticName.allCases.map(\.rawValue)).count == 10)
    }

    @Test func resistIsTwoRisingSoftTransientsTwelveHundredthsApart() throws {
        guard case .pattern(let transients, let tail) = PofuHapticName.resist.spec else {
            Issue.record("resist is a custom pattern")
            return
        }
        #expect(transients.count == 2)
        #expect(transients[1].time - transients[0].time == 0.12)
        #expect(transients[1].intensity > transients[0].intensity)
        #expect(transients.allSatisfy { $0.sharpness <= 0.4 }, "soft")
        #expect(tail == 0)
    }

    @Test func growthIsThreeRisingTransientsAndASoftTail() {
        guard case .pattern(let transients, let tail) = PofuHapticName.growth.spec else {
            Issue.record("growth is a custom pattern")
            return
        }
        #expect(transients.count == 3)
        #expect(zip(transients, transients.dropFirst()).allSatisfy { $0.intensity < $1.intensity })
        #expect(tail > 0)
    }

    @Test func quietIsNothing() {
        #expect(PofuHapticName.quiet.spec == .none)
    }

    @Test func notEnoughSeedsWarnsAndNeverErrors() {
        #expect(PofuHapticName.warning.spec == .warning)
    }

    @Test func theSimpleFeelingsUseSystemFeedback() {
        #expect(PofuHapticName.tap.spec == .selection)
        #expect(PofuHapticName.land.spec == .impact(.soft, intensity: 0.4))
        #expect(PofuHapticName.edge.spec == .impact(.rigid, intensity: 0.3))
        #expect(PofuHapticName.nudge.spec == .impact(.light, intensity: 0.6))
    }

    @Test func onlyCustomFeelingsUseCoreHaptics() {
        let custom = PofuHapticName.allCases.filter {
            if case .pattern = $0.spec { return true }
            return false
        }
        #expect(Set(custom) == [.resist, .growth, .pouch])
    }

    @Test func seedTicksAreRationedToSixASecond() {
        var limiter = SeedTickLimiter(maxPerSecond: 6)
        // A tick every 10 ms for three seconds.
        let played = (0..<300).filter { limiter.allows(at: Double($0) * 0.01) }
        #expect(played.count <= 18, "\(played.count)")
        for start in stride(from: 0.0, through: 2.0, by: 0.1) {
            let inWindow = played.filter { Double($0) * 0.01 >= start && Double($0) * 0.01 < start + 1 }
            #expect(inWindow.count <= 6, "\(start): \(inWindow.count)")
        }
        #expect(PofuHapticName.seed.spec == .ticks(maxPerSecond: 6, finale: .soft))
    }
}
