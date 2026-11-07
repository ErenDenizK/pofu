import Foundation
import PofuDesignSystem
import Testing
@testable import PofuWorld

/// Look pipeline v2, phase 1: the fitted LUTs per layer group and cell, the
/// backdrop's final colours and the night relight.
@Suite("Look pipeline v2")
struct LookLUTTests {
    // MARK: - The LUT blend

    @Test func theBlendFollowsTheColourScriptsCells() throws {
        for hour in stride(from: 0.0, to: 24, by: 0.25) {
            let light = WorldLight.at(hour: hour, wellbeing: 80, calm: 1)
            let blend = try #require(light.grade.lut)
            let total = blend.weights.values.reduce(0, +)
            #expect(abs(total - 1) < 1e-9, "weights sum to 1 at \(hour)")
            #expect(blend.group == .island)
            #expect(light.characterGrade.lut?.group == .characters)
            #expect(light.characterGrade.lut?.weights == blend.weights)
        }
        #expect(WorldLight.at(hour: 22.5, wellbeing: 80, calm: 1).grade.lut?.weights == [.night: 1])
        #expect(WorldLight.at(hour: 12, wellbeing: 80, calm: 1).grade.lut?.weights == [.day: 1])
        #expect(WorldLight.at(hour: 18.5, wellbeing: 80, calm: 1).grade.lut?.weights == [.golden: 1])
    }

    @Test func rainMovesOnlyTheSunLitCellsToTheRainLUT() throws {
        let rain = Atmosphere(conditions: WeatherConditions(weather: .lightRain))
        let noon = WorldLight.at(hour: 12, wellbeing: 80, calm: 1).withAtmosphere(rain)
        #expect(noon.grade.lut?.weights == [.rain: 1])
        #expect(noon.characterGrade.lut?.weights == [.rain: 1])
        let night = WorldLight.at(hour: 23, wellbeing: 80, calm: 1).withAtmosphere(rain)
        #expect(night.grade.lut?.weights == [.night: 1])
        let overcast = WorldLight.at(hour: 12, wellbeing: 80, calm: 1)
            .withAtmosphere(Atmosphere(conditions: WeatherConditions(weather: .overcast)))
        let w = try #require(overcast.grade.lut?.weights)
        #expect(abs((w[.rain] ?? 0) - 0.6) < 1e-9 && abs((w[.day] ?? 0) - 0.4) < 1e-9)
    }

    @Test func theShaderSamplesTheThreeHeaviestLUTs() {
        let blend = LookLUT.Blend(group: .island, weights: [.day: 0.1, .golden: 0.5, .dusk: 0.3, .night: 0.1])
        let top = blend.top3
        #expect(top.map(\.set) == [.golden, .dusk, .day])
        #expect(abs(top.reduce(0) { $0 + $1.weight } - 1) < 1e-9)
        // A blend that does not reach 1 keeps the identity for the rest.
        let half = LookLUT.Blend(group: .island, weights: [.night: 0.5]).top3
        #expect(half.count == 1 && abs(half[0].weight - 0.5) < 1e-9)
        #expect(LookLUT.Blend(group: .island, weights: [:]).top3.isEmpty)
    }

    @Test func theBlendSurvivesAnimationAsAVector() {
        let blend = LookLUT.Blend(group: .characters, cells: [.golden: 0.3, .dusk: 0.7], rain: 0.5)
        let back = LookLUT.Blend(group: .characters, vector: blend.vector)
        for set in LookLUT.Set.allCases {
            #expect(abs((back.weights[set] ?? 0) - (blend.weights[set] ?? 0)) < 1e-4)
        }
        // Golden takes rain, dusk keeps its own.
        #expect(abs((blend.weights[.rain] ?? 0) - 0.15) < 1e-9)
        #expect(abs((blend.weights[.dusk] ?? 0) - 0.7) < 1e-9)
    }

    @Test func gradesMixTheirLUTs() {
        let a = WorldGrade.neutral.with(lut: LookLUT.Blend(group: .island, weights: [.day: 1]))
        let b = WorldGrade.neutral.with(lut: LookLUT.Blend(group: .island, weights: [.night: 1]))
        let m = WorldGrade.mix(a, b, 0.25)
        #expect(m.lut?.weights == [.day: 0.75, .night: 0.25])
        // An overlay keeps the base's LUTs; the sky never takes any.
        #expect(a.layered(with: ColourScript.unwell.grade, amount: 1).lut == a.lut)
        #expect(a.sky.lut == nil)
        #expect(!a.isNeutral)
    }

    /// Every LUT the runtime can ask for is baked: a 17³ strip, (17·17) × 18
    /// pixels, its first row the 0.5 grey the shader calibrates with.
    @Test func everyLUTIsInTheCatalog() throws {
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        for group in LookLUT.Group.allCases {
            for set in LookLUT.Set.allCases {
                let name = LookLUT.assetName(group, set)
                let png = catalog.appendingPathComponent("\(name).imageset/\(name).png")
                let data = try Data(contentsOf: png)
                // PNG IHDR: width and height, big-endian, at bytes 16 and 20.
                func be32(_ at: Int) -> Int { data[at..<at + 4].reduce(0) { $0 << 8 | Int($1) } }
                #expect(be32(16) == LookLUT.size * LookLUT.size, "\(name) width")
                #expect(be32(20) == LookLUT.size + 1, "\(name) height")
            }
        }
    }

    // MARK: - The backdrop

    @Test func theBackdropTakesOnlyTheOverlays() {
        let night = WorldLight.at(hour: 22.5, wellbeing: 80, calm: 1)
        #expect(night.backdropGrade.isNeutral)
        let unwell = WorldLight.at(hour: 22.5, wellbeing: 20, calm: 1)
        #expect(!unwell.backdropGrade.isNeutral)
        let rain = WorldLight.at(hour: 12, wellbeing: 80, calm: 1)
            .withAtmosphere(Atmosphere(conditions: WeatherConditions(weather: .lightRain)))
        #expect(!rain.backdropGrade.isNeutral && rain.backdropGrade.lut == nil)
    }

    /// The liked nights (Gezgin f2, Revontuli): a dark, saturated
    /// blue-violet zenith (L* 25 to 36), lighter toward the horizon, and a
    /// warm white cloud sea (L* 78 to 90), never the lavender wash.
    @Test func theNightSkyIsDeepAndTheSeaWarmWhite() {
        let palette = SkyModel.palette(minuteOfDay: 22.5 * 60)
        let zenith = SkyModel.lightness(palette.zenith)
        #expect(zenith >= 24 && zenith <= 36)
        #expect(palette.zenith.blue > palette.zenith.red + 0.15)
        #expect(SkyModel.lightness(palette.horizon) > zenith + 12)
        let sea = ColourScript.cell(.night).sea
        #expect(SkyModel.lightness(sea.light) >= 78 && SkyModel.lightness(sea.light) <= 92)
        #expect(sea.light.red >= sea.light.blue, "the sea's light side is warm")
    }

    /// The golden sky leans pink (I1 summer evening), not lilac.
    @Test func theGoldenSkyIsPink() {
        let sky = ColourScript.cell(.golden).sky
        #expect(sky.zenith.red >= sky.zenith.blue)
        #expect(sky.horizon.red > sky.horizon.blue + 0.15)
    }

    // MARK: - The night relight

    @Test func theNightIsLitFromItsSources() throws {
        let world = IslandSamples.grownIsland(wellbeing: 78)
        let noon = WorldLight.at(hour: 12, wellbeing: 78, calm: 1)
        #expect(RelightRig.night(light: noon, field: LightField.make(world: world, light: noon)) == nil)
        let night = WorldLight.at(hour: 22.5, wellbeing: 78, calm: 1)
        let rig = try #require(RelightRig.night(light: night, field: LightField.make(world: world, light: night)))
        #expect(rig.strength == 1)
        #expect(rig.practicals.count >= 3, "the lamps, the tea stall, the door and the lantern light the night")
        let dusk = WorldLight.at(hour: 20, wellbeing: 78, calm: 1)
        let duskRig = RelightRig.night(light: dusk, field: LightField.make(world: world, light: dusk))
        #expect((duskRig?.strength ?? 0) > 0 && (duskRig?.strength ?? 1) < 1)
    }

    @Test func eachSpriteTakesItsNearestSources() {
        func point(_ x: Double, _ r: Double) -> RelightRig.Point {
            RelightRig.Point(x: x, y: 0, height: 1, radius: r, colour: GradeRGB(all: 1))
        }
        let picked = RelightRig.nearest([point(100, 50), point(10, 50), point(30, 50), point(5, 2)], to: (0, 0))
        #expect(picked.map(\.x) == [10, 30])
        #expect(RelightRig.nearest([point(100, 50)], to: (0, 0)).isEmpty, "out of reach")
    }

    @Test func pofuAndTheResidentsHaveNormals() {
        #expect(GraphicsSpike.litSprites.isSuperset(of: ["pofu", "mochi", "findik", "mochi-sleepy", "findik-sleepy", "tea-stall-3"]))
    }
}
