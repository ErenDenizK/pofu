import Foundation
import PofuCore
import PofuDesignSystem
import Testing
@testable import PofuWorld

@Suite("Weather and the screen haze (sky and weather v1 §2.2, §2.2b)")
struct WeatherTests {
    private func day(_ n: Int) -> LocalDay {
        LocalDay(year: 2026, month: 1, day: 1).adding(days: n)
    }

    private let starts = (0 ..< 120).map { LocalDay(year: 2026, month: 1, day: 1).adding(days: $0 * 3) }

    private func slots(from start: LocalDay, days: Int) -> [(WeatherHalf, LocalDay, Weather)] {
        (0 ..< days).flatMap { n in
            [WeatherHalf.morning, .afternoon].map { half in
                (half, start.adding(days: n), WeatherForecast.weather(on: start.adding(days: n), half: half, start: start))
            }
        }
    }

    // MARK: The bag

    @Test func theFirstFourteenDaysHoldEveryWeatherForAnyStartDate() {
        for start in starts {
            let seen = Set(slots(from: start, days: 14).map(\.2))
            #expect(seen == Set(Weather.allCases), "start \(start)")
        }
    }

    @Test func aBagHoldsTheSharesAndRespectsTheHours() {
        for start in starts {
            for index in 0 ..< 4 {
                let bag = WeatherForecast.bag(index, start: start)
                #expect(bag.count == 28)
                for (weather, count) in WeatherForecast.bagCounts {
                    #expect(bag.filter { $0 == weather }.count == count)
                }
                for (i, weather) in bag.enumerated() {
                    if weather == .mist { #expect(i % 2 == 0, "mist is a morning") }
                    if weather == .goldenHaze { #expect(i % 2 == 1, "golden haze is an afternoon") }
                    if weather == .lightRain, i + 1 < bag.count { #expect(bag[i + 1] != .lightRain) }
                }
            }
        }
    }

    @Test func theSameDateGivesTheSameWeatherEveryLaunch() {
        let start = LocalDay(year: 2026, month: 11, day: 6)
        for n in 0 ..< 60 {
            for hour in stride(from: 0.0, to: 24, by: 0.5) {
                let a = WeatherForecast.conditions(on: start.adding(days: n), hour: hour, start: start)
                let b = WeatherForecast.conditions(on: start.adding(days: n), hour: hour, start: start)
                #expect(a == b)
            }
        }
        #expect(WeatherForecast.bag(2, start: start) == WeatherForecast.bag(2, start: start))
    }

    @Test func differentStartsShuffleDifferently() {
        let orders = Set(starts.map { WeatherForecast.bag(0, start: $0) })
        #expect(orders.count > starts.count / 2)
    }

    @Test func laterBagsKeepTheShares() {
        let start = LocalDay(year: 2026, month: 11, day: 6)
        var counts: [Weather: Int] = [:]
        for n in 0 ..< 14 * 20 {
            for half in [WeatherHalf.morning, .afternoon] {
                counts[WeatherForecast.weather(on: start.adding(days: n), half: half, start: start), default: 0] += 1
            }
        }
        let total = Double(14 * 20 * 2)
        #expect(abs(Double(counts[.clear] ?? 0) / total - 0.57) < 0.02)
        #expect(abs(Double(counts[.overcast] ?? 0) / total - 0.21) < 0.02)
        #expect((counts[.lightRain] ?? 0) > 0 && (counts[.mist] ?? 0) > 0 && (counts[.goldenHaze] ?? 0) > 0)
    }

    // MARK: Hours, the rainbow

    @Test func mistIsMorningAndGoldenHazeIsGoldenHourOnly() {
        for start in starts.prefix(40) {
            for n in 0 ..< 28 {
                for hour in stride(from: 0.0, to: 24, by: 0.25) {
                    let c = WeatherForecast.conditions(on: start.adding(days: n), hour: hour, start: start)
                    if c.weather == .mist { #expect(hour >= 4.5 && hour < 10.5) }
                    if c.weather == .goldenHaze { #expect(hour >= 17.5 && hour < 19.5) }
                    if c.weather == .lightRain { #expect(hour >= 4 && hour < 17) }
                }
            }
        }
    }

    @Test func aRainbowComesOnlyWithinAnHourAfterRainByDay() {
        for start in starts.prefix(60) {
            var rainbows = 0
            for n in 0 ..< 14 {
                let d = start.adding(days: n)
                var wasRaining = false
                var lastRain = -100.0
                for hour in stride(from: 0.0, to: 24, by: 0.25) {
                    let c = WeatherForecast.conditions(on: d, hour: hour, start: start)
                    if c.weather == .lightRain { lastRain = hour; wasRaining = true }
                    if c.rainbow {
                        rainbows += 1
                        #expect(wasRaining, "a rainbow follows rain the same day")
                        #expect(hour - lastRain <= 1.25)
                        #expect(hour >= 6 && hour < 19, "by day")
                        #expect(c.weather == .clear)
                    }
                }
            }
            #expect(rainbows > 0, "every first fortnight has a rainbow (start \(start))")
        }
    }

    @Test func noRainbowWithoutRain() {
        let start = LocalDay(year: 2026, month: 5, day: 1)
        for n in 0 ..< 200 {
            let d = start.adding(days: n)
            for hour in stride(from: 6.0, to: 19, by: 0.5) {
                let c = WeatherForecast.conditions(on: d, hour: hour, start: start)
                if c.rainbow {
                    let half: WeatherHalf = hour < 13 ? .morning : .afternoon
                    #expect(WeatherForecast.weather(on: d, half: half, start: start) == .lightRain)
                }
            }
        }
    }

    // MARK: Seasons

    @Test func seasonsFollowTheNorthernCalendar() {
        let expected: [Int: Season] = [
            12: .winter, 1: .winter, 2: .winter, 3: .spring, 4: .spring, 5: .spring,
            6: .summer, 7: .summer, 8: .summer, 9: .autumn, 10: .autumn, 11: .autumn,
        ]
        for (month, season) in expected {
            #expect(Season.of(month: month) == season)
        }
        #expect(Season.of(LocalDay(year: 2026, month: 11, day: 6)) == .autumn)
    }

    @Test func dayNumbersCountDays() {
        #expect(WeatherForecast.dayNumber(LocalDay(year: 1970, month: 1, day: 1)) == 0)
        #expect(WeatherForecast.dayNumber(LocalDay(year: 2026, month: 3, day: 1)) - WeatherForecast.dayNumber(LocalDay(year: 2026, month: 2, day: 28)) == 1)
        #expect(WeatherForecast.dayNumber(LocalDay(year: 2028, month: 3, day: 1)) - WeatherForecast.dayNumber(LocalDay(year: 2028, month: 2, day: 28)) == 2)
    }

    // MARK: Light rows

    private func lightness(_ rgb: GradeRGB) -> Double {
        SkyModel.lightness(PofuRGB(red: rgb.r, green: rgb.g, blue: rgb.b))
    }

    @Test func rainKeepsTheGroundBrightEnough() {
        let rain = ColourScript.weather(named: "lightRain")
        // A mid lawn green, gamma-encoded, through the day's cell and the rain.
        let lawn = GradeRGB(0.52, 0.66, 0.38)
        let day = ColourScript.cell(.day).grade
        let wet = day.layered(with: rain.grade, amount: 1)
        #expect(lightness(wet.apply(lawn)) >= 55)
        #expect(rain.keyIntensity == 0.5 && rain.fillIntensity == 1.1)
    }

    @Test func theRowsFollowTheSpec() {
        let over = ColourScript.weather(named: "overcast")
        #expect(over.keyIntensity == 0.7 && over.fillIntensity == 1.05)
        #expect(over.grade.saturation == 0.9 && over.grade.contrast == 0.8)
        let rain = ColourScript.weather(named: "lightRain")
        #expect(rain.grade.saturation == 0.82 && rain.grade.contrast == 0.8)
        let mist = ColourScript.weather(named: "mist")
        #expect(mist.keyIntensity == 0.85 && mist.fogExtra == LookTuning.fogMistExtra)
        #expect(ColourScript.weather(named: "goldenHaze").grade.saturation == 1.08)
        #expect(Weather.clear.state == nil)
    }

    @Test func mistFeedsTheFogModelAndRainKeepsAPracticalLit() {
        #expect(Atmosphere(conditions: WeatherConditions(weather: .mist)).mist == 1)
        #expect(Atmosphere(conditions: WeatherConditions(weather: .clear)).mist == 0)
        let noon = WorldLight.at(hour: 12, wellbeing: 80, calm: 1)
        let wet = noon.withAtmosphere(Atmosphere(conditions: WeatherConditions(weather: .lightRain)))
        #expect(wet.practicals.window >= 0.85)
        #expect(wet.grade != noon.grade)
    }

    // MARK: The screen haze is the player's, never weather

    @Test func theHazeFollowsWellbeingAsTheUnwellStateDoes() {
        for wellbeing in stride(from: 0.0, through: 100, by: 5) {
            let light = WorldLight.at(hour: 12, wellbeing: wellbeing, calm: 1)
            #expect(abs(ScreenHaze.amount(wellbeing: wellbeing) - light.unwell) < 1e-9)
        }
        #expect(ScreenHaze.amount(wellbeing: 56) == 0)
        #expect(ScreenHaze.amount(wellbeing: 30) == 1)
    }

    @Test func theHazeNeverUsesWeather() {
        // The haze reads wellbeing only: its amount has no weather input, and
        // the same wellbeing lights the same haze under every weather.
        let noon = WorldLight.at(hour: 12, wellbeing: 30, calm: 1)
        let haze = ScreenHaze.amount(wellbeing: 30)
        for weather in Weather.allCases {
            let a = Atmosphere(conditions: WeatherConditions(weather: weather), haze: haze)
            #expect(a.haze == haze)
        }
        #expect(noon.unwell == haze)
    }

    @Test func theHazeIsLilacAndMistIsPeach() {
        let haze = ScreenHaze.colour
        let mist = ColourScript.weather(named: "mist").skyToward
        #expect(haze.blue > haze.red && haze.blue > haze.green)
        #expect(mist.red > mist.blue)
    }

    @Test func aResistedReachPartsTheHazeALittleThenItCloses() {
        #expect(ScreenHaze.parting(secondsSince: nil) == 0)
        #expect(ScreenHaze.parting(secondsSince: 0) == 0)
        #expect(ScreenHaze.parting(secondsSince: 5) == 1)
        #expect(ScreenHaze.parting(secondsSince: 600) == 0)
        let open = ScreenHaze.parted(0.8, parting: 1)
        #expect(open < 0.8 && open > 0.8 * 0.5, "a little, not all of it")
        #expect(ScreenHaze.parted(0.8, parting: 0) == 0.8)
    }

    @Test func theHazeKeepsValueContrast() {
        let day = WorldLight.at(hour: 12, wellbeing: 30, calm: 1)
        let hazy = day.withAtmosphere(Atmosphere(haze: 1))
        let dark = GradeRGB(0.18, 0.2, 0.26), light = GradeRGB(0.9, 0.88, 0.8)
        let spread = lightness(hazy.grade.apply(light)) - lightness(hazy.grade.apply(dark))
        #expect(spread > 45, "values stay apart under the haze")
        #expect(hazy.practicals.window > 0.4, "practicals dim but never go out")
    }
}

@Suite("Island stops carry no veil (ADR-0021)")
struct IslandStopVeilTests {
    private let fixtureClock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    /// The cause of the pale Çağlayan stops: the fixtures' date rolls
    /// overcast at noon and at night, and the overcast row lifts the island.
    @Test func theFixtureDateIsOvercastSoShotsMustPinTheWeather() {
        let world = IslandSamples.grownIsland(clock: fixtureClock)
        for hour in [12.0, 23.0] {
            let seeded = WeatherForecast.conditions(clock: world.clock, firstDay: world.firstDay, hour: hour, calendar: .current)
            #expect(seeded.weather != .clear, "hour \(hour): if this is clear the pin is no longer needed")
        }
    }

    @Test func theIslandStopLookPinsAClearSky() {
        for hour in [12.0, 23.0] {
            let look = WorldLook.islandStop(hour: hour)
            #expect(look.hourOverride == hour)
            #expect(look.weatherOverride?.weather == .clear)
            #expect(look.weatherOverride?.rainbow == false)
        }
    }

    /// A clear sky adds no weather layer to the island's grade: the grade is
    /// the hour's own, with no rain LUT weight and no contrast loss.
    @Test func aClearSkyLeavesTheIslandGradeAtTheHoursOwn() {
        for hour in [12.0, 23.0] {
            let base = WorldLight.at(hour: hour, wellbeing: 78, calm: 0)
            let clear = base.withAtmosphere(Atmosphere(conditions: WorldLook.islandStop(hour: hour).weatherOverride ?? .clear, haze: 0))
            #expect(clear.grade == base.grade)
            #expect(clear.grade.lut?.weights[.rain] == nil)
        }
    }
}

@Suite("The island is graded once under rain and overcast")
struct IslandWeatherGradeTests {
    @Test func overcastNoonTakesTheRainLUTAloneNotTheRowToo() {
        let base = WorldLight.at(hour: 12, wellbeing: 78, calm: 0)
        let overcast = base.withAtmosphere(Atmosphere(conditions: WeatherConditions(weather: .overcast), haze: 0))
        #expect(overcast.grade.lut?.weights[.rain] ?? 0 > 0.5)
        // No contrast, gain or saturation from the overcast row on top of the LUT.
        #expect(overcast.grade.contrast == base.grade.contrast)
        #expect(overcast.grade.gain == base.grade.gain)
        #expect(overcast.grade.saturation == base.grade.saturation)
    }

    @Test func rainNoonAlsoTakesTheLUTAlone() {
        let base = WorldLight.at(hour: 12, wellbeing: 78, calm: 0)
        let rain = base.withAtmosphere(Atmosphere(conditions: WeatherConditions(weather: .lightRain), haze: 0))
        #expect(rain.grade.contrast == base.grade.contrast)
        #expect(rain.grade.saturation == base.grade.saturation)
    }

    @Test func nightKeepsTheRowBecauseTheLUTDoesNotTakeRainThen() {
        let base = WorldLight.at(hour: 23, wellbeing: 78, calm: 0)
        let overcast = base.withAtmosphere(Atmosphere(conditions: WeatherConditions(weather: .overcast), haze: 0))
        #expect(overcast.grade.lut?.weights[.rain] == nil)
        #expect(overcast.grade.contrast < base.grade.contrast)
    }

    @Test func mistStillTakesTheRow() {
        let base = WorldLight.at(hour: 12, wellbeing: 78, calm: 0)
        let mist = base.withAtmosphere(Atmosphere(conditions: WeatherConditions(weather: .mist), haze: 0))
        #expect(mist.grade.contrast < base.grade.contrast)
    }

    @Test func theNightIslandKeepsItsChroma() {
        #expect(WorldLight.at(hour: 23, wellbeing: 78, calm: 0).grade.saturation >= 1.2)
    }

    @Test func damlaStaysInFocusWithTheLawn() {
        #expect(CaglayanLayout.damlaBoxHeight >= 30)
    }
}
