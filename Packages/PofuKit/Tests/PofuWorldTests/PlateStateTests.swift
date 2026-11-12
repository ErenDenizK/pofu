import Foundation
import PofuCore
import PofuDesignSystem
@testable import PofuWorld
import Testing

@Suite("Plate states, every hour")
struct PlateStateTests {
    /// A minimal plate: `painted` maps a light to its stages, two day stages at levels 4 and 2.
    static func fixture(painted: [String: [Int]], stageLevels: [Int] = [4, 2]) throws -> PlateIsland {
        let lights = painted.keys.sorted().map { "\"\($0)\"" }.joined(separator: ",")
        let paintedJSON = painted.map { "\"\($0.key)\":\($0.value)" }.joined(separator: ",")
        let json = """
        {"island":"fixture","version":1,"minLevel":2,"plateSize":[1536,1024],"stages":\(stageLevels.count),
         "lights":[\(lights)],"painted":{\(paintedJSON)},"stageLevels":\(stageLevels),
         "islandBox":[10,10,1500,900],"objects":[]}
        """
        return try PlateIsland.decode(Data(json.utf8))
    }

    static func name(_ state: (light: String, stage: Int)?) -> String? {
        state.map { "\($0.light)-\($0.stage)" }
    }

    static func paintedState(_ plate: PlateIsland, _ stage: Int, _ hour: Double, _ weather: WeatherConditions = .clear, bed: Bool = false) -> String? {
        name(HomePlate.paintedState(in: plate, stage: stage, hour: hour, weather: weather, isBedtime: bed))
    }

    static let allWeathers: [WeatherConditions] = [
        .clear, WeatherConditions(weather: .overcast), WeatherConditions(weather: .mist),
        WeatherConditions(weather: .goldenHaze), WeatherConditions(weather: .clear, rainbow: true),
        WeatherConditions(weather: .lightRain),
    ]

    @Test func everyHourHasALight() {
        var hour = 0.0
        while hour <= 24 {
            let light = HomePlate.light(hour: hour, isBedtime: false)
            let want: String = hour < 6 || hour >= 20 ? "night" : hour < 17.5 ? "day" : "golden"
            #expect(light == want, "\(hour)")
            hour += 0.25
        }
        #expect(HomePlate.light(hour: 5.99, isBedtime: false) == "night")
        #expect(HomePlate.light(hour: 6, isBedtime: false) == "day")
        #expect(HomePlate.light(hour: 17.5, isBedtime: false) == "golden")
        #expect(HomePlate.light(hour: 20, isBedtime: false) == "night")
        #expect(HomePlate.light(hour: 12, isBedtime: true) == "night")
    }

    @Test func theMorningJumpLandsOnTheDay() {
        let calendar = Calendar(identifier: .gregorian)
        let time = RehearsalTime(bedtime: SpendingRules().bedtime, calendar: calendar)
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 23, minute: 30))!
        let landing = time.destination(of: .morning, from: start)
        let hour = SkyModel.minuteOfDay(landing, calendar: calendar) / 60
        #expect(HomePlate.light(hour: hour, isBedtime: false) == "day")
    }

    @Test func theNightJumpLandsOnTheNight() {
        let calendar = Calendar(identifier: .gregorian)
        let time = RehearsalTime(bedtime: SpendingRules().bedtime, calendar: calendar)
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 9))!
        let landing = time.destination(of: .night, from: start)
        let hour = SkyModel.minuteOfDay(landing, calendar: calendar) / 60
        // The landing is the start of bedtime: night by the window, whatever the hour band says.
        #expect(HomePlate.light(hour: hour, isBedtime: true) == "night")
        #expect(time.bedtime.contains(landing, in: calendar))
    }

    @Test func goldenBorrowsTheNightThenTheDay() throws {
        let both = try Self.fixture(painted: ["day": [0, 1], "night": [0]])
        #expect(Self.paintedState(both, 0, 18) == "night-0")
        let dayOnly = try Self.fixture(painted: ["day": [0, 1], "night": [0]])
        // Stage 1 has no golden and no night: the day.
        #expect(Self.paintedState(dayOnly, 1, 18) == "day-1")
        let painted = try Self.fixture(painted: ["day": [0], "golden": [0], "night": [0]])
        #expect(Self.paintedState(painted, 0, 18) == "golden-0")
    }

    @Test func nightBorrowsGoldenAndNeverTheDay() throws {
        let goldenOnly = try Self.fixture(painted: ["day": [0, 1], "golden": [0]])
        #expect(Self.paintedState(goldenOnly, 0, 22.5) == "golden-0")
        #expect(Self.paintedState(goldenOnly, 0, 3) == "golden-0")
        #expect(Self.paintedState(goldenOnly, 0, 12, bed: true) == "golden-0")
        #expect(Self.paintedState(goldenOnly, 1, 22.5) == nil)
        let dayOnly = try Self.fixture(painted: ["day": [0, 1]])
        #expect(Self.paintedState(dayOnly, 0, 22.5) == nil)
        #expect(Self.paintedState(dayOnly, 0, 18) == "day-0")
    }

    @Test func everyWeatherShowsTheHoursPainting() throws {
        let plate = try Self.fixture(painted: ["day": [0], "golden": [0], "night": [0]])
        for hour in [3.0, 6.5, 12, 18, 22.5] {
            let clear = Self.paintedState(plate, 0, hour)
            #expect(clear != nil)
            for weather in [WeatherConditions(weather: .overcast), WeatherConditions(weather: .mist),
                            WeatherConditions(weather: .goldenHaze), WeatherConditions(weather: .clear, rainbow: true)] {
                #expect(Self.paintedState(plate, 0, hour, weather) == clear, "\(hour) \(weather)")
            }
            // With no painted rain, light rain keeps the hour's painting too.
            #expect(Self.paintedState(plate, 0, hour, WeatherConditions(weather: .lightRain)) == clear)
        }
    }

    @Test func paintedRainWinsByDayAndNeverAtNight() throws {
        let plate = try Self.fixture(painted: ["day": [0], "golden": [0], "night": [0], "rain": [0]])
        let rain = WeatherConditions(weather: .lightRain)
        #expect(Self.paintedState(plate, 0, 12, rain) == "rain-0")
        #expect(Self.paintedState(plate, 0, 18, rain) == "rain-0")
        #expect(Self.paintedState(plate, 0, 22.5, rain) == "night-0")
        #expect(Self.paintedState(plate, 0, 12, bed: true) == "night-0")
        #expect(Self.paintedState(plate, 0, 12, WeatherConditions(weather: .overcast)) == "day-0")
    }

    @Test func homeDaysAtLevelsTwoToTenAreAlwaysPainted() throws {
        let plate = try #require(HomePlate.shipped).plate
        for level in 2...10 {
            var hour = 6.0
            while hour <= 17.25 {
                for weather in Self.allWeathers where weather.weather != .lightRain {
                    let state = HomePlate.state(in: plate, islandLevel: level, hour: hour, weather: weather, isBedtime: false)
                    #expect(state?.light == "day", "level \(level) at \(hour)")
                }
                hour += 0.25
            }
        }
    }

    @Test func homeFinalLevelKeepsItsGoldenAndNight() throws {
        let plate = try #require(HomePlate.shipped).plate
        #expect(Self.name(HomePlate.state(in: plate, islandLevel: 10, hour: 18, weather: .clear, isBedtime: false)) == "golden-0")
        #expect(Self.name(HomePlate.state(in: plate, islandLevel: 10, hour: 22.5, weather: .clear, isBedtime: false)) == "night-0")
    }

    @Test func caglayanIsPaintedAtEveryStageByDayAndGolden() throws {
        let island = try #require(HomePlate.caglayanIsland)
        for stage in 0...4 {
            var hour = 6.0
            while hour <= 19.75 {
                for weather in Self.allWeathers {
                    let state = HomePlate.caglayanState(in: island, stage: stage, hour: hour, weather: weather, isBedtime: false)
                    #expect(state != nil, "stage \(stage) at \(hour)")
                }
                hour += 0.25
            }
        }
    }

    @Test func caglayanHealedNightBorrowsGolden() throws {
        let island = try #require(HomePlate.caglayanIsland)
        #expect(Self.name(HomePlate.caglayanState(in: island, stage: 4, hour: 22.5, weather: .clear, isBedtime: false)) == "golden-4")
    }
}
