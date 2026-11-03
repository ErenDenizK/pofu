import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("World grade")
struct WorldGradeTests {
    private func close(_ a: GradeRGB, _ b: GradeRGB, _ tolerance: Double = 1e-9) -> Bool {
        abs(a.r - b.r) < tolerance && abs(a.g - b.g) < tolerance && abs(a.b - b.b) < tolerance
    }

    @Test func neutralIsTheIdentity() {
        for c in [GradeRGB(0, 0, 0), GradeRGB(1, 1, 1), GradeRGB(0.2, 0.5, 0.9), GradeRGB(0.81, 0.62, 0.33)] {
            #expect(close(WorldGrade.neutral.apply(c), c))
        }
        #expect(WorldGrade.neutral.isNeutral)
        #expect(!WorldGrade.day.isNeutral)
    }

    @Test func zeroSaturationIsGrey() {
        let out = WorldGrade(saturation: 0).apply(GradeRGB(0.8, 0.4, 0.2))
        #expect(abs(out.r - out.g) < 1e-12 && abs(out.g - out.b) < 1e-12)
    }

    @Test func dayIsMoreVividThanTheFilesButNotNeon() {
        let lawn = GradeRGB(0.55, 0.70, 0.42)
        let out = WorldGrade.day.apply(lawn)
        let spread = { (c: GradeRGB) in max(c.r, c.g, c.b) - min(c.r, c.g, c.b) }
        #expect(spread(out) > spread(lawn))
        #expect(spread(out) < spread(lawn) * 1.4)
    }

    @Test func goldenHourWarmsAndNightCools() {
        let grey = GradeRGB(all: 0.6)
        let golden = WorldGrade.goldenHour.apply(grey)
        #expect(golden.r > golden.b + 0.05)
        let night = WorldGrade.night.apply(grey)
        #expect(night.b > night.r + 0.05)
        #expect(night.g < 0.5)
    }

    private func luma(_ c: GradeRGB) -> Double {
        0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    }

    @Test func unwellDesaturatesButKeepsItsContrast() {
        let c = GradeRGB(0.85, 0.55, 0.35)
        let base = WorldGrade.day
        let unwell = base.layered(with: .unwell, amount: 1)
        let spread = { (c: GradeRGB) in max(c.r, c.g, c.b) - min(c.r, c.g, c.b) }
        #expect(spread(unwell.apply(c)) < spread(base.apply(c)) * 0.75)
        #expect(spread(unwell.apply(c)) > spread(base.apply(c)) * 0.3)
        // Never grey fog: the art's darkest and lightest stay at least as
        // far apart as by day, and the shadows are not lifted.
        let dark = GradeRGB(0.47, 0.42, 0.36), light = GradeRGB(0.93, 0.91, 0.86)
        #expect(luma(unwell.apply(light)) - luma(unwell.apply(dark)) >= luma(base.apply(light)) - luma(base.apply(dark)))
        #expect(luma(unwell.apply(dark)) <= luma(base.apply(dark)))
        // And cooler.
        #expect(unwell.apply(GradeRGB(all: 0.7)).b > unwell.apply(GradeRGB(all: 0.7)).r)
    }

    @Test func nightHasTrueDarksAndNoLiftedBlacks() {
        // The art's darkest values sit near L* 50 (sRGB ~0.47).
        let shadow = GradeRGB(0.47, 0.42, 0.36)
        #expect(luma(WorldGrade.night.apply(shadow)) < 0.08)
        #expect(luma(WorldGrade.night.apply(GradeRGB(all: 0))) == 0)
        // Highlights still read: a cream highlight stays well above the shadow.
        let cream = GradeRGB(0.97, 0.94, 0.88)
        #expect(luma(WorldGrade.night.apply(cream)) - luma(WorldGrade.night.apply(shadow)) > 0.3)
    }

    @Test func theSkyTakesTheGradeWithoutItsLevels() {
        let sky = WorldGrade.night.sky
        #expect(sky.black == 0 && sky.white == 1)
        #expect(sky.gain == WorldGrade.night.gain)
        // A dark night-sky blue is not crushed to black.
        #expect(luma(sky.apply(GradeRGB(0.16, 0.18, 0.36))) > 0.03)
    }

    @Test func levelsLayerByTheStronger() {
        let g = WorldGrade.night.layered(with: .unwell, amount: 1)
        #expect(g.black == WorldGrade.night.black)
        #expect(WorldGrade.day.layered(with: .unwell, amount: 1).black == WorldGrade.unwell.black)
        #expect(abs(WorldGrade.mix(.day, .night, 0.5).black - WorldGrade.night.black / 2) < 1e-12)
    }

    @Test func mixHitsBothEnds() {
        #expect(WorldGrade.mix(.day, .night, 0) == .day)
        #expect(WorldGrade.mix(.day, .night, 1) == .night)
        let mid = WorldGrade.mix(.neutral, .day, 0.5)
        #expect(abs(mid.saturation - (1 + (WorldGrade.day.saturation - 1) / 2)) < 1e-12)
    }

    @Test func anOverlayOnNeutralIsItself() {
        let g = WorldGrade.neutral.layered(with: .calmGlow, amount: 1)
        #expect(close(g.apply(GradeRGB(0.4, 0.5, 0.6)), WorldGrade.calmGlow.apply(GradeRGB(0.4, 0.5, 0.6)), 1e-9))
        #expect(WorldGrade.day.layered(with: .unwell, amount: 0) == .day)
    }
}

@Suite("World light")
struct WorldLightTests {
    @Test func phaseWeightsSumToOne() {
        for hour in stride(from: 0.0, through: 24.0, by: 0.25) {
            let w = WorldLight.phaseWeights(hour: hour)
            #expect(abs(w.day + w.golden + w.night - 1) < 1e-9, "hour \(hour)")
        }
    }

    @Test func theHoursLandOnTheirPhases() {
        #expect(WorldLight.phaseWeights(hour: 12).day == 1)
        #expect(WorldLight.phaseWeights(hour: 18.5).golden == 1)
        #expect(WorldLight.phaseWeights(hour: 23).night == 1)
        #expect(WorldLight.phaseWeights(hour: 3).night == 1)
    }

    @Test func noonIsTheDayGrade() {
        let light = WorldLight.at(hour: 12, wellbeing: 78, calm: 1.4)
        #expect(light.grade == .day)
        #expect(light.shafts == 0)
        #expect(light.fireflies == 0)
        #expect(light.pollen > 0.9)
    }

    @Test func goldenHourHasShaftsAndNightHasFireflies() {
        let golden = WorldLight.at(hour: 18.5, wellbeing: 78, calm: 1.4)
        #expect(golden.grade == .goldenHour)
        #expect(golden.shafts > 0.9)
        let night = WorldLight.at(hour: 22, wellbeing: 78, calm: 1.4)
        #expect(night.grade == .night)
        #expect(night.fireflies > 0.9)
        #expect(night.shafts == 0)
    }

    @Test func bedtimeIsAlwaysNight() {
        let light = WorldLight.at(hour: 12, wellbeing: 78, calm: 1.4, isBedtime: true)
        #expect(light.night == 1)
    }

    @Test func lowWellbeingLayersTheUnwellGrade() {
        #expect(WorldLight.at(hour: 12, wellbeing: 78, calm: 1.4).unwell == 0)
        let low = WorldLight.at(hour: 12, wellbeing: 25, calm: 1.4)
        #expect(low.unwell == 1)
        #expect(low.grade == WorldGrade.day.layered(with: .unwell, amount: 1))
        #expect(low.grade.saturation < WorldGrade.day.saturation)
    }

    @Test func highCalmGlows() {
        #expect(WorldLight.at(hour: 12, wellbeing: 90, calm: 1.4).calmGlow == 0)
        #expect(WorldLight.at(hour: 12, wellbeing: 90, calm: 2.0).calmGlow > 0.999)
        // An unwell Pofu does not glow.
        #expect(WorldLight.at(hour: 12, wellbeing: 20, calm: 2.0).calmGlow == 0)
    }

    @Test func theSnapshotsClockDrivesTheHour() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Istanbul"))
        let noon = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12)))
        let world = IslandSamples.dayThree(clock: noon)
        #expect(WorldLight.resolve(world: world, calendar: calendar).day == 1)
        #expect(WorldLight.resolve(world: world, calendar: calendar, hourOverride: 22).night == 1)
    }

    @Test func emittersGlowAtNightNotAtNoon() throws {
        let window = try #require(IslandLayout.emitters.first { $0.station == nil })
        #expect(window.strength(in: .at(hour: 12, wellbeing: 78, calm: 1.4)) == 0)
        #expect(window.strength(in: .at(hour: 22, wellbeing: 78, calm: 1.4)) > 0.8)
        // Unwell, the window stays lit by day: care is still here.
        #expect(window.strength(in: .at(hour: 12, wellbeing: 20, calm: 1.4)) > 0.15)
    }
}

@Suite("Look tuning")
struct LookTuningTests {
    @Test func tiltShiftIsStrongestAtTheIslandAndOffOnTheMap() {
        #expect(LookTuning.tiltShift(z: 0) == 1)
        #expect(abs(LookTuning.tiltShift(z: 1) - 1.7) < 1e-12)
        #expect(abs(LookTuning.tiltShift(z: 2) - 1.3) < 1e-12)
    }

    @Test func tiltShiftKeepsTheFocusPlaneSharp() {
        let lens = Lens.island.tiltShifted(by: 1.7)
        #expect(lens.blurLevel(depth: lens.focus) == 0)
        #expect(lens.blurLevel(depth: 120) > Lens.island.blurLevel(depth: 120))
        // The map's lens has no gain and stays sharp.
        #expect(Lens.map.tiltShifted(by: 1.7).blurLevel(depth: 200) == 0)
    }

    @Test func theSoftLockSetFallsBackWhereNothingWasBaked() {
        #expect(WorldArt.key("cay-1", art: .softLock) == "cay-1--softlock")
        // The large plate has no soft-lock bake.
        #expect(WorldArt.key("island-main-band2", art: .softLock) == "island-main-band2")
        #expect(WorldArt.key("mochi", art: .softLock) == "mochi")
        #expect(WorldArt.key("cay-1", art: .lockLight) == "cay-1")
    }

    @Test func theCompareSetsKeepTheirBakes() {
        // The large plate was corrected toward the approved island; its raw
        // colour is kept to compare.
        #expect(WorldArt.key("island-main-band2", art: .unharmonized) == "island-main-band2--unharmonized")
        // The rose copper is in its material's range: no correction, so no
        // uncorrected bake (look round 3).
        #expect(WorldArt.key("cay-1", art: .unharmonized) == "cay-1")
        #expect(WorldArt.key("cay-1", art: .round2Copper) == "cay-1--round2")
        // The founder's plate choice (look round 4): v2 beside the shipped v3.
        #expect(WorldArt.key("island-main-band1", art: .plateV2) == "island-main-band1--v2")
        #expect(WorldArt.key("cay-1", art: .plateV2) == "cay-1")
    }

    @Test func theLitFlameShowsAtNightOnly() {
        #expect(IslandLayout.litOverlay(.teaStall, level: 1) == "cay-1-glow")
        #expect(IslandLayout.litOverlay(.teaStall, level: 3) == nil)
        #expect(IslandLayout.litOverlayStrength(in: .at(hour: 12, wellbeing: 78, calm: 1.4)) == 0)
        #expect(IslandLayout.litOverlayStrength(in: .at(hour: 22, wellbeing: 78, calm: 1.4)) > 0.99)
    }

    @Test func theTuningLabTuningDefaultsChangeNothing() {
        #expect(LookTuning.tiltShift(z: 1, island: WorldTuning.standard.tiltShiftIsland, home: WorldTuning.standard.tiltShiftHome) == LookTuning.tiltShift(z: 1))
        #expect(CameraSprings.standard.travel == SpringSpec(duration: WorldSprings.camera.duration, bounce: WorldSprings.camera.bounce))
        let motion = CameraMotion(lookX: 120, lookY: 0, logScale: 0)
        let one = DepthMotion.shift(point: .zero, depth: 80, focus: 0, look: .zero, motion: motion)
        let two = DepthMotion.shift(point: .zero, depth: 80, focus: 0, look: .zero, motion: motion.parallax(2))
        #expect(abs(two.x - 2 * one.x) < 1e-9)
    }
}
