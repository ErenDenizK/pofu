import Foundation
import PofuDesignSystem
import Testing
@testable import PofuWorld

@Suite("Sky and fog (sky and weather v1 §2.1, §2.3)")
struct SkyAndFogTests {
    private let minutes = stride(from: 0.0, through: 1440, by: 15).map { $0 }

    private func same(_ a: PofuRGB, _ b: PofuRGB) -> Bool {
        abs(a.red - b.red) + abs(a.green - b.green) + abs(a.blue - b.blue) < 1e-9
    }

    // MARK: Depth fog

    @Test func tiersFollowTheTable() {
        #expect(FogModel.amount(tier: .front) == 0)
        #expect(FogModel.amount(tier: .mid) == 0.18)
        #expect(FogModel.amount(tier: .far) == 0.38)
        #expect(FogModel.amount(tier: .farthest) == 0.55)
    }

    @Test func mistAddsFifteenPointsBehindTheFront() {
        #expect(FogModel.amount(tier: .front, mist: 1) == 0)
        #expect(abs(FogModel.amount(tier: .mid, mist: 1) - 0.33) < 1e-9)
        #expect(abs(FogModel.amount(tier: .farthest, mist: 1) - 0.70) < 1e-9)
        #expect(abs(FogModel.amount(tier: .far, mist: 0.5) - 0.455) < 1e-9)
        // Out-of-range mist is clamped.
        #expect(FogModel.amount(tier: .far, mist: 7) == FogModel.amount(tier: .far, mist: 1))
    }

    @Test func distanceInterpolatesAndNeverFallsWithDepth() {
        var previous = -1.0
        for d in stride(from: 0.0, through: 1.0, by: 0.05) {
            let a = FogModel.amount(distance: d)
            #expect(a >= previous - 1e-12)
            previous = a
        }
        #expect(FogModel.amount(distance: 0) == 0)
        #expect(abs(FogModel.amount(distance: 1) - 0.55) < 1e-9)
        #expect(abs(FogModel.amount(distance: 0.7) - 0.38) < 1e-9)
        #expect(FogModel.amount(distance: .nan) == FogModel.amount(distance: 1))
    }

    @Test func shadowsMixAQuarterMore() {
        #expect(abs(FogModel.shadowAmount(0.38) - 0.475) < 1e-9)
        #expect(FogModel.shadowAmount(0.9) <= LookTuning.fogMaximum)
        let h = PofuRGB(hex: 0xDCEAF4)
        let light = PofuRGB(hex: 0xCCAA88), shadow = PofuRGB(hex: 0x445566)
        let fogged = FogModel.fogged(light: light, shadow: shadow, horizon: h, amount: 0.38)
        // The shadow ends up closer to the fog colour than the light does,
        // relative to where each started.
        func gap(_ a: PofuRGB, _ b: PofuRGB) -> Double { abs(a.red - b.red) + abs(a.green - b.green) + abs(a.blue - b.blue) }
        #expect(gap(fogged.shadow, h) / gap(shadow, h) < gap(fogged.light, h) / gap(light, h))
    }

    @Test func fogTakesTheHorizonColourNeverGrey() {
        for minute in minutes {
            let horizon = SkyModel.palette(minuteOfDay: minute).horizon
            let fog = FogModel.colour(horizon: horizon)
            #expect(same(fog, horizon), "minute \(minute)")
            let spread = max(fog.red, fog.green, fog.blue) - min(fog.red, fog.green, fog.blue)
            #expect(spread >= FogModel.minimumChroma, "minute \(minute)")
            // Fully fogged, any colour becomes the horizon.
            let full = FogModel.fogged(PofuRGB(hex: 0x336644), horizon: horizon, amount: 1)
            #expect(same(full, horizon))
        }
        // A washed-out horizon is pulled off neutral instead of going grey.
        let grey = FogModel.colour(horizon: PofuRGB(red: 0.7, green: 0.7, blue: 0.7))
        #expect(max(grey.red, grey.green, grey.blue) - min(grey.red, grey.green, grey.blue) >= FogModel.minimumChroma)
    }

    @Test func cardsAreLowInClearWeatherAndMistRaisesThem() {
        #expect(FogModel.cardOpacity(mist: 0) <= 0.35)
        #expect(FogModel.cardOpacity(mist: 1) > FogModel.cardOpacity(mist: 0))
        #expect((2...4).contains(FogCardLayout.cards.count))
        #expect(FogCardLayout.cards.filter { $0.layer == .front }.count == 1)
        #expect(FogCardLayout.cards.contains { $0.layer == .behind })
        let speeds = Set(FogCardLayout.cards.map(\.speed))
        #expect(speeds.isSuperset(of: [1, 2, 3.5]))
    }

    // MARK: Sky

    @Test func cosineEaseIsFlatAtTheEnds() {
        #expect(SkyModel.ease(0) == 0)
        #expect(SkyModel.ease(1) == 1)
        #expect(abs(SkyModel.ease(0.5) - 0.5) < 1e-12)
        // Slower than linear near the ends, faster in the middle.
        #expect(SkyModel.ease(0.1) < 0.1)
        #expect(SkyModel.ease(0.9) > 0.9)
        #expect(SkyModel.ease(0.5 + 0.05) - SkyModel.ease(0.5 - 0.05) > 0.1)
    }

    @Test func nightZenithIsNeverBlack() {
        for minute in minutes {
            for unwell in [0.0, 0.5, 1.0] {
                let l = SkyModel.lightness(SkyModel.palette(minuteOfDay: minute, unwell: unwell).zenith)
                #expect(l >= LookTuning.nightZenithFloor - 0.05, "minute \(minute) unwell \(unwell): L* \(l)")
            }
        }
        let bedtime = SkyModel.palette(minuteOfDay: 12 * 60, isBedtime: true).zenith
        #expect(SkyModel.lightness(bedtime) >= LookTuning.nightZenithFloor - 0.05)
        // The floor lifts a black zenith and leaves a bright one alone.
        let black = SkyModel.lifted(PofuRGB(red: 0, green: 0, blue: 0), toLightness: 12)
        #expect(abs(SkyModel.lightness(black) - 12) < 0.1)
        let bright = PofuRGB(hex: 0x8CC4F2)
        #expect(SkyModel.lifted(bright, toLightness: 12) == bright)
    }

    @Test func starsTwinkleDeterministically() {
        let stars = SkyModel.stars
        #expect((30...40).contains(stars.count))
        for star in stars {
            #expect(LookTuning.starTwinkleHz.contains(star.hz))
            #expect(star.y >= 0 && star.y <= 0.42 && star.x >= 0 && star.x <= 1)
            for t in [0.0, 1.3, 7.9, 120] {
                let a = SkyModel.twinkle(star, time: t)
                #expect(a == SkyModel.twinkle(star, time: t))
                #expect(a > 0 && a <= 1)
            }
        }
        // They do move over a few seconds, and repeat each period.
        let star = stars[0]
        let values = stride(from: 0.0, to: 10, by: 0.5).map { SkyModel.twinkle(star, time: $0) }
        #expect((values.max() ?? 0) - (values.min() ?? 0) > 0.02)
        let period = 1 / star.hz
        #expect(abs(SkyModel.twinkle(star, time: 2) - SkyModel.twinkle(star, time: 2 + period)) < 1e-9)
        // The same list every launch.
        #expect(SkyModel.stars == stars)
    }

    @Test func paletteBlendHasNoCornerAtACell() {
        // Eased: the change of the zenith near a keyframe is far smaller
        // than in the middle of the blend.
        guard let key = ColourScript.schedule.first(where: { $0.cell == .day }) else { return }
        let start = key.minute
        func step(_ m: Double) -> Double {
            let a = SkyModel.palette(minuteOfDay: m).zenith, b = SkyModel.palette(minuteOfDay: m + 1).zenith
            return abs(a.red - b.red) + abs(a.green - b.green) + abs(a.blue - b.blue)
        }
        let edge = step(start - 29), middle = step(start - 15)
        #expect(edge < middle)
    }

    // MARK: Clouds

    @Test func cloudLayersMoveAtOneAndAThird() {
        #expect(SkyCloudLayer.allCases.count == 3)
        let p = SkyCloudLayer.allCases.map(\.parallax)
        #expect(abs(p[1] / p[0] - 1.8) < 1e-9)
        #expect(abs(p[2] / p[0] - 3) < 1e-9)
        for layer in SkyCloudLayer.allCases {
            #expect(!layer.clouds.isEmpty)
            for cloud in layer.clouds {
                #expect(cloud.speed > 0 && cloud.speed < LookTuning.cloudMaxSpeed, "\(cloud.seed)")
                #expect(WorldArt.sprite(cloud.art) != nil, "\(cloud.art)")
            }
        }
        let seeds = SkyCloudLayer.allCases.flatMap(\.clouds).map(\.seed)
        #expect(Set(seeds).count == seeds.count)
    }

    @Test func cloudTintLitSideShadeAndGlow() {
        let noon = SkyModel.palette(minuteOfDay: 12 * 60)
        for layer in SkyCloudLayer.allCases {
            let tint = CloudTint(palette: noon, layer: layer)
            #expect(same(tint.lit, noon.cloudLight))
            // The shade is the zenith darkened 15 to 25 L*.
            let drop = SkyModel.lightness(noon.zenith) - SkyModel.lightness(tint.shade)
            #expect(drop >= 14.5 && drop <= 25.5, "\(layer) \(drop)")
            #expect(tint.underglow == 0)
        }
        // Nearer clouds are darker underneath.
        let tints = SkyCloudLayer.allCases.map { CloudTint(palette: noon, layer: $0) }
        #expect(SkyModel.lightness(tints[2].shade) < SkyModel.lightness(tints[0].shade))
        // The low sun lights the undersides; full night does not.
        let golden = SkyModel.palette(minuteOfDay: 18 * 60 + 30)
        let night = SkyModel.palette(minuteOfDay: 23 * 60)
        #expect(CloudTint(palette: golden, layer: .mid).underglow > 0.3)
        #expect(CloudTint(palette: night, layer: .mid).underglow < 0.05)
        // The glow pulls the shade toward the horizon colour.
        let dark = SkyModel.darkened(golden.zenith, byLightness: 20)
        let lit = CloudTint(palette: golden, layer: .mid).shade
        func gap(_ a: PofuRGB, _ b: PofuRGB) -> Double { abs(a.red - b.red) + abs(a.green - b.green) + abs(a.blue - b.blue) }
        #expect(gap(lit, golden.horizon) < gap(dark, golden.horizon))
    }

    @Test func tintQuantisingHoldsStillForSmallDrift() {
        let a = CloudTint(palette: SkyModel.palette(minuteOfDay: 12 * 60), layer: .far).quantised()
        let b = CloudTint(palette: SkyModel.palette(minuteOfDay: 12 * 60 + 1), layer: .far).quantised()
        #expect(a == b)
    }

    // MARK: Koke

    @Test func kokeStageZeroIsFoggedWarmLitAndCool() {
        let zero = KokeStageLook(stage: 0)
        #expect(zero.isActive && zero.fog > 0)
        #expect(zero.shaftAlpha >= 0.08 && zero.shaftAlpha <= 0.18)
        #expect(zero.coolTint.blue >= zero.coolTint.red)
        // It fades over stages 1 and 2 and is gone from stage 3.
        let looks = (0...4).map { KokeStageLook(stage: $0) }
        for (a, b) in zip(looks, looks.dropFirst()) {
            #expect(b.fog <= a.fog && b.cardOpacity <= a.cardOpacity && b.coolAmount <= a.coolAmount && b.shaftAlpha <= a.shaftAlpha)
        }
        #expect(!looks[3].isActive && !looks[4].isActive)
        #expect(looks[3].shaftAlpha == 0)
        #expect(KokeStageLook(stage: 99) == looks[4])
        #expect(KokeStageLook(stage: -1) == looks[0])
    }
}
