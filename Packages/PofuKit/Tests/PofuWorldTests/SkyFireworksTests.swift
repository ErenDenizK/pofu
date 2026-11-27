import Testing
@testable import PofuWorld

@Suite("New Year's fireworks (C3)")
struct SkyFireworksTests {
    @Test func theyAreCalmAndFew() {
        var peak = 0.0
        for step in 0..<2000 {
            let t = Double(step) * 0.05
            let bursts = SkyFireworks.bursts(at: t)
            #expect(bursts.count <= 2)
            #expect(Set(bursts.map(\.slot)).count == bursts.count)
            for burst in bursts {
                #expect(burst.y >= 0.26 && burst.y <= 0.36, "bursts stay in the sky above the island")
                #expect(burst.x >= 0.30 && burst.x <= 0.66)
                peak = max(peak, SkyFireworks.strength(age: burst.age))
            }
        }
        #expect(peak <= SkyFireworks.peak && peak > 0.5)
    }

    @Test func noSparkFlashesOnOrOff() {
        #expect(SkyFireworks.strength(age: 0) == 0)
        #expect(SkyFireworks.strength(age: 1) == 0)
        // Strength never jumps by more than a fifth of the peak between frames at 30 Hz.
        var last = 0.0
        for step in 0...90 {
            let now = SkyFireworks.strength(age: Double(step) / 90)
            #expect(abs(now - last) < SkyFireworks.peak * 0.2)
            last = now
        }
    }

    @Test func theStillFramesHoldABurstAtEveryTimeOfTheSheet() {
        for t in [0.0, 0.5, 1.0, 1.5, 2.0] {
            let seen = SkyFireworks.bursts(at: t).map { SkyFireworks.strength(age: $0.age) }.max() ?? 0
            #expect(seen > 0.15, "the frame at \(t) s shows a burst you can see")
        }
    }

    @Test func aBurstIsTheSameEveryTimeItIsAsked() {
        #expect(SkyFireworks.bursts(at: 7.3) == SkyFireworks.bursts(at: 7.3))
    }
}
