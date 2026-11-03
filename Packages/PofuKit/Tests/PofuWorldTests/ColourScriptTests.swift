import Foundation
import PofuDesignSystem
import Testing
@testable import PofuWorld

@Suite("Colour script")
struct ColourScriptTests {
    /// A colour's hue in degrees and its chroma (HSV-style, enough to
    /// compare a character's hue between cells).
    private func hueAndChroma(_ c: GradeRGB) -> (hue: Double, chroma: Double) {
        let mx = max(c.r, c.g, c.b), mn = min(c.r, c.g, c.b)
        let d = mx - mn
        guard d > 1e-9 else { return (0, 0) }
        var h: Double
        if mx == c.r {
            h = ((c.g - c.b) / d).truncatingRemainder(dividingBy: 6)
        } else if mx == c.g {
            h = (c.b - c.r) / d + 2
        } else {
            h = (c.r - c.g) / d + 4
        }
        h *= 60
        return (h < 0 ? h + 360 : h, d)
    }

    private func luma(_ c: PofuRGB) -> Double {
        0.2126 * c.red + 0.7152 * c.green + 0.0722 * c.blue
    }

    @Test func everyCellIsScripted() {
        for name in ColourCell.Name.allCases {
            #expect(ColourScript.generatedCells[name] != nil, "\(name)")
        }
    }

    @Test func weightsSumToOneThroughTheDay() {
        for minute in stride(from: 0.0, through: 1440, by: 5) {
            let total = ColourScript.weights(minuteOfDay: minute).values.reduce(0, +)
            #expect(abs(total - 1) < 1e-9, "minute \(minute)")
        }
    }

    @Test func theHoursLandOnTheirCells() {
        #expect(ColourScript.weights(minuteOfDay: 6 * 60)[.dawn] == 1)
        #expect(ColourScript.weights(minuteOfDay: 12 * 60)[.day] == 1)
        #expect(ColourScript.weights(minuteOfDay: 18.5 * 60)[.golden] == 1)
        #expect(ColourScript.weights(minuteOfDay: 20 * 60)[.dusk] == 1)
        #expect(ColourScript.weights(minuteOfDay: 23 * 60)[.night] == 1)
    }

    /// The rule for Pofu (pro-game-craft §4.3): he takes the hour's light,
    /// never the grade's saturation cut.
    @Test func pofuIsNeverDesaturatedByTheHour() {
        for name in ColourCell.Name.allCases {
            #expect(ColourScript.cell(name).character.saturation >= 1, "\(name)")
        }
    }

    /// Look round 3: at night Pofu and the residents kept turning lavender
    /// under the world's grade. Their fur keeps its hue under the character
    /// light; the world's own night grade would swing it far toward violet.
    @Test func characterFurKeepsItsHueAtNight() {
        let fur = GradeRGB(0.96, 0.85, 0.74)
        let day = hueAndChroma(ColourScript.cell(.day).character.apply(fur))
        let night = hueAndChroma(ColourScript.cell(.night).character.apply(fur))
        #expect(abs(night.hue - day.hue) < 6)
        #expect(night.chroma > day.chroma * 0.55)
        let world = hueAndChroma(WorldGrade.night.apply(fur))
        #expect(abs(world.hue - day.hue) > 60, "the world's night grade no longer shifts the hue; the test lost its point")
    }

    @Test func unwellPofuIsDesaturatedButReadable() {
        let light = WorldLight.at(hour: 12, wellbeing: 20, calm: 1.4)
        #expect(light.characterGrade.saturation < 1)
        #expect(light.characterGrade.saturation > light.grade.saturation)
        // He keeps his contrast: no lifted blacks, no crushed whites.
        let cream = light.characterGrade.apply(GradeRGB(0.97, 0.93, 0.86))
        let shadow = light.characterGrade.apply(GradeRGB(0.55, 0.42, 0.33))
        #expect(cream.g - shadow.g > 0.35)
    }

    /// The unwell sky is cooler, a little darker and lower in chroma, and
    /// never brighter than the hour's well sky.
    @Test func theUnwellSkyIsNeverBrighter() {
        for minute in stride(from: 0.0, through: 1440, by: 30) {
            let well = SkyModel.palette(minuteOfDay: minute)
            let unwell = SkyModel.palette(minuteOfDay: minute, unwell: 1)
            for (a, b) in [(well.zenith, unwell.zenith), (well.horizon, unwell.horizon), (well.cloudLight, unwell.cloudLight)] {
                #expect(luma(b) <= luma(a) + 1e-9, "minute \(minute)")
            }
        }
        let noon = SkyModel.palette(minuteOfDay: 12 * 60)
        let grey = SkyModel.palette(minuteOfDay: 12 * 60, unwell: 1)
        #expect(luma(grey.horizon) < luma(noon.horizon) * 0.95)
        // Cooler: the horizon's blue leans up against its red.
        #expect(grey.horizon.blue - grey.horizon.red > noon.horizon.blue - noon.horizon.red)
    }

    @Test func theNightSeaIsNeverABlackVoid() {
        let sea = ColourScript.cell(.night).sea
        let graded = WorldGrade.night.sky.apply(sea.light)
        #expect(luma(graded) > 0.2)
    }

    @Test func theSkyIsPreGradedOnTheCPU() {
        let palette = SkyModel.palette(minuteOfDay: 22 * 60)
        let graded = palette.graded(by: .night)
        #expect(graded.zenith == WorldGrade.night.sky.apply(palette.zenith))
        // A neutral grade leaves it as it is.
        #expect(palette.graded(by: .neutral) == palette)
    }
}
