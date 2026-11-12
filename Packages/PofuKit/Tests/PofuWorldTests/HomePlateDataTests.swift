import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// What the shipped `plate-home.json` paints (docs/design/demo-one-world-v1.md, PR 2): the night
/// and the day of every level from 1, and that the Rehearsal
/// tester's twenty-one days find a painting at every hour the panel lands on.
struct HomePlateDataTests {
    var plate: PlateIsland {
        get throws { try #require(HomePlate.shipped, "the package ships Plates/plate-home.json").plate }
    }

    @Test func paintsTheNightOfEveryLevel() throws {
        let plate = try plate
        #expect(plate.painted["night"] == Array(0...9))
        // The night stage is the level's own: stage s is `stageLevels[s]` for every light.
        #expect(plate.stageLevels == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1])
        for level in 1...10 {
            let stage = try #require(plate.dayStage(islandLevel: level))
            #expect(plate.paints(light: "night", stage: stage), "the night of level \(level)")
        }
    }

    @Test func paintsTheDayOfEveryLevelFromOne() throws {
        let plate = try plate
        #expect(plate.painted["day"] == Array(0...9))
        #expect(plate.stageLevels.last == 1)
        #expect(plate.minLevel == 1)
        #expect(plate.dayStage(islandLevel: 1) == 9)
        #expect(plate.dayStage(islandLevel: 0) == nil)
    }

    @Test func lowLevelNightsHaveNoLampPool() throws {
        let plate = try plate
        // The lamps open at level 6 (`HomeFixtures.lampsOpenAtLevel`): below it no lamp is lit, so
        // the night plate gives a character no lamp pool.
        for level in 1...5 {
            let stage = try #require(plate.dayStage(islandLevel: level))
            #expect(plate.harmony(light: "night", stage: stage).pool == 0, "level \(level)")
        }
        for level in 6...10 {
            let stage = try #require(plate.dayStage(islandLevel: level))
            #expect(plate.harmony(light: "night", stage: stage).pool > 0, "level \(level)")
        }
    }

    @Test func aNightPaintsOnlyWhatItsLevelHas() throws {
        let plate = try plate
        // IL2's night: the tea stall and the pond are there, the windmill is not; IL1's day has no
        // tea stall and paints the garden.
        let two = HomePlate(plate: plate, light: "night", stage: 8)
        #expect(two.objects.contains { $0.id == "teaStall" })
        #expect(!two.objects.contains { $0.id == "windmill" })
        let one = HomePlate(plate: plate, light: "day", stage: 9)
        #expect(!one.objects.contains { $0.id == "teaStall" })
        #expect(!one.objects.contains { $0.id == "wheel" })
        #expect(one.objects.contains { $0.id == "garden" })
        #expect(one.objects.contains { $0.id == "door" })
    }

    /// The tester's island level on each of the 21 days (Rehearsal: one resisted reach a day).
    static let testerLevels = [1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7]

    /// The hours the panel and a real evening land on: "Morning" 06:00, "Next day" 09:00, noon,
    /// golden hour 18:00, the gap before night 19:45, and "Night" at bedtime (23:00).
    static let hours: [(hour: Double, bedtime: Bool)] = [(6, false), (9, false), (12, false), (18, false), (19.75, false), (23, true)]

    static let weathers: [WeatherConditions] =
        Weather.allCases.map { WeatherConditions(weather: $0) } + [WeatherConditions(weather: .clear, rainbow: true)]

    @Test func theTestersTwentyOneDaysArePainted() throws {
        let plate = try plate
        for (day, level) in Self.testerLevels.enumerated() {
            for (hour, bedtime) in Self.hours {
                for weather in Self.weathers {
                    let state = HomePlate.state(in: plate, islandLevel: level, hour: hour, weather: weather, isBedtime: bedtime)
                    #expect(state != nil, "day \(day + 1), level \(level), \(hour) h, \(weather.weather), rainbow \(weather.rainbow)")
                }
            }
        }
    }

    @Test func theTestersFirstEveningIsPainted() throws {
        let plate = try plate
        // Day 1's 18:00, 19:45 and 23:00 are the painted night of level 1 (art job A1).
        for (hour, bedtime) in Self.hours where hour >= 18 || bedtime {
            let state = HomePlate.state(in: plate, islandLevel: 1, hour: hour, weather: .clear, isBedtime: bedtime)
            #expect(state != nil, "IL1 at \(hour) h")
        }
        let night = HomePlate(plate: plate, light: "night", stage: 9)
        #expect(night.objects.contains { $0.id == "garden" })
        #expect(!night.objects.contains { $0.id == "teaStall" })
    }
}
