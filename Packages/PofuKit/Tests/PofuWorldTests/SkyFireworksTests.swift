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
                #expect(burst.y >= 0.22 && burst.y <= 0.29, "bursts stay in the sky above the island")
                #expect(burst.x >= 0.36 && burst.x <= 0.64)
                // The ring, with its fall, stays under the screen's top and above the highest far island (0.196 of the height) on a
                // 402 x 874 pt screen, and its sides clear the moon (x 0.2) and the gear (x 0.84).
                let h = 874.0, w = 402.0
                let reach = burst.radius * w
                #expect(burst.y * SkyFireworks.bandShare * h + reach * 1.3 <= 0.19 * h, "the ring's bottom is above the far islands")
                #expect(burst.y * SkyFireworks.bandShare * h - reach >= 0, "the ring's top is on screen")
                #expect(burst.x * w - reach >= 0.2 * w && burst.x * w + reach <= 0.84 * w - 10)
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
