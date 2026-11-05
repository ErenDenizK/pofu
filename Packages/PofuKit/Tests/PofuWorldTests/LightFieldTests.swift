import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Light field")
struct LightFieldTests {
    private func world(calm: Double = 1.5, level: Int = 8) -> WorldSnapshot {
        var w = IslandSamples.grownIsland()
        w.calm = calm
        w.islandLevel = level
        return w
    }

    private func field(hour: Double, calm: Double = 1.5, level: Int = 8, guest: Bool = false) -> LightField {
        let w = world(calm: calm, level: level)
        return LightField.make(world: w, light: WorldLight.at(hour: hour, wellbeing: 78, calm: calm), guestNight: guest)
    }

    private func source(_ id: String, x: Double, y: Double = 0, strength: Double = 1, reach: Double = 60) -> LightSource {
        LightSource(id: id, kind: .lamp, point: WorldPoint(x: x, y: y), height: 0, colour: GradeRGB(1, 0.8, 0.5),
                    reach: reach, shape: .round, strength: strength)
    }

    private func bare(_ sources: [LightSource]) -> LightField {
        LightField(sources: sources, ambientFloor: 0.14, moonRim: 0.5, moonColour: GradeRGB(0.7, 0.7, 0.8))
    }

    @Test func thePoolsAreOffByDay() {
        #expect(field(hour: 12).isDark)
    }

    @Test func theLanternBurnsAtNightWithTheDoorAndTheEmber() {
        let ids = Set(field(hour: 22).sources.map(\.id))
        #expect(ids.contains("lantern"))
        #expect(ids.contains("window-pofu"))
        #expect(ids.contains("ember"))
    }

    @Test func sampleTakesTheNearestOfEquallyStrongSources() {
        let f = bare([source("far", x: 40), source("near", x: 10)])
        let s = f.sample(WorldPoint(x: 0, y: 0))
        #expect(s.sourceID == "near")
        #expect(s.directionX > 0.99)
    }

    @Test func aStrongerSourceBeatsANearerWeakOne() {
        let f = bare([source("weak", x: 8, strength: 0.1), source("strong", x: 20, strength: 1.0)])
        #expect(f.sample(.zero).sourceID == "strong")
    }

    @Test func outOfReachSamplesNothingButKeepsTheFloor() {
        let f = bare([source("lamp", x: 200)])
        let s = f.sample(.zero)
        #expect(s.sourceID == nil)
        #expect(s.strength == 0)
        #expect(s.ambient == 0.14)
        #expect(s.moonRim == 0.5)
    }

    @Test func aRaisedSourceLightsFromAbove() {
        var high = source("high", x: 0, y: 20)
        high.height = 40
        let s = bare([high]).sample(.zero)
        #expect(s.directionY < 0.5)
    }

    @Test func theLanternBrightensMonotonicallyWithCalm() {
        var last = -1.0
        for calm in stride(from: 1.0, through: 2.0, by: 0.1) {
            let k = LightField.lanternStrength(calm: calm)
            #expect(k > last)
            last = k
        }
        #expect(abs(LightField.lanternStrength(calm: 1) - 0.4) < 1e-9)
        #expect(abs(LightField.lanternStrength(calm: 2) - 1.0) < 1e-9)
        #expect(LightField.lanternStrength(calm: 5) == LightField.lanternStrength(calm: 2))
        #expect(LightField.lanternStrength(calm: .nan) == LightField.lanternStrength(calm: 1))
    }

    @Test func theLanternInTheFieldFollowsCalm() {
        func lantern(_ calm: Double) -> Double {
            field(hour: 22, calm: calm).sources.first { $0.id == "lantern" }?.strength ?? 0
        }
        #expect(lantern(1.0) < lantern(1.5))
        #expect(lantern(1.5) < lantern(2.0))
    }

    @Test func aCharacterByTheLanternIsLitByIt() {
        let f = field(hour: 22)
        let beside = WorldPoint(x: HomeSlots.lantern.x - 10, y: IslandLayout.pofu.y)
        let s = f.sample(beside)
        #expect(s.sourceID == "lantern")
        #expect(s.strength > 0.2)
    }

    @Test func aResidentFarFromEveryLightStillHasTheFloor() {
        let f = field(hour: 23)
        let s = f.sample(WorldPoint(x: 700, y: 300))
        #expect(s.sourceID == nil)
        #expect(s.ambient >= 0.1)
        #expect(s.moonRim > 0)
    }

    @Test func theBakeKeyChangesOnlyWithASourceOrABucket() {
        let a = bare([source("a", x: 0, strength: 0.80), source("b", x: 50, strength: 0.50)])
        // The same strength within a bucket (1/16 = 0.0625): same key.
        var small = a
        small.sources[0].strength = 0.81
        #expect(a.bakeKey == small.bakeKey)
        // A bucket step: a new key.
        var big = a
        big.sources[0].strength = 0.90
        #expect(a.bakeKey != big.bakeKey)
        // A source removed: a new key.
        #expect(a.bakeKey != bare([a.sources[0]]).bakeKey)
        // Order changes nothing.
        #expect(a.bakeKey == bare(a.sources.reversed()).bakeKey)
    }

    @Test func theGuestRoomLightsOnlyOnAVisitNight() {
        #expect(!field(hour: 22).sources.contains { $0.id == "window-guest" })
        #expect(field(hour: 22, guest: true).sources.contains { $0.id == "window-guest" })
    }

    @Test func theIslandLevelOpensTheDoorsAndLamps() {
        let early = Set(field(hour: 22, level: 1).sources.map(\.id))
        let late = Set(field(hour: 22, level: 8).sources.map(\.id))
        #expect(!early.contains("lamp-1") && late.contains("lamp-1"))
        #expect(!early.contains("window-mochi") && late.contains("window-mochi"))
    }

    @Test func duskLightsLessThanNight() {
        let dusk = field(hour: 20).sources.first { $0.id == "lantern" }?.strength ?? 0
        let night = field(hour: 22).sources.first { $0.id == "lantern" }?.strength ?? 0
        #expect(dusk > 0 && dusk <= night)
    }

    @Test func theColourScriptCarriesTheGains() {
        #expect(ColourScript.cell(.day).poolGain == 0)
        #expect(ColourScript.cell(.night).poolGain == 1)
        #expect(ColourScript.cell(.night).ambientFloor >= 0.1)
        for name in ColourCell.Name.allCases {
            #expect(ColourScript.cell(name).ambientFloor <= 0.3, "\(name) floor is a floor, not a light")
        }
    }

    @Test func nightShrinksTheCharacterLiftButKeepsTheHue() {
        let night = WorldLight.at(hour: 22, wellbeing: 78, calm: 1.5).characterGrade
        let cell = ColourScript.cell(.night).character
        #expect(night.gain.r < cell.gain.r)
        #expect(abs(night.gain.r / night.gain.b - cell.gain.r / cell.gain.b) < 1e-9)
        #expect(night.saturation >= 1)
    }
}
