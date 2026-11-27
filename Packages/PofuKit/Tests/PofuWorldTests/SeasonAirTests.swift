import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("The season's air (island calendar v1, C2)")
struct SeasonAirTests {
    private let starts = (0 ..< 60).map { LocalDay(year: 2026, month: 3, day: 1).adding(days: $0 * 5) }

    // MARK: The weather's odds per season

    @Test func springKeepsTheShippedBagAndNeverSnows() {
        for start in starts {
            for index in 0 ..< 3 {
                #expect(WeatherForecast.bag(index, start: start).allSatisfy { $0 != .snow })
            }
            for n in 0 ..< 40 {
                for half in [WeatherHalf.morning, .afternoon] {
                    let day = start.adding(days: n)
                    let shipped = WeatherForecast.weather(on: day, half: half, start: start)
                    #expect(WeatherForecast.weather(on: day, half: half, start: start, season: .spring) == shipped)
                    #expect(WeatherForecast.weather(on: day, half: half, start: start, season: nil) == shipped)
                }
            }
        }
    }

    @Test func everySeasonBagHoldsItsCountsAndFillsTheWeek() {
        for season in [Season.summer, .autumn, .winter] {
            let counts = WeatherForecast.seasonCounts(season) ?? [:]
            #expect(counts.values.reduce(0, +) == WeatherForecast.seasonBagSlots, "\(season)")
            for start in starts {
                for block in 0 ..< 4 {
                    let bag = WeatherForecast.seasonBag(block: block, season: season, start: start)
                    #expect(bag.count == WeatherForecast.seasonBagSlots)
                    for weather in Weather.allCases {
                        #expect(bag.filter { $0 == weather }.count == (counts[weather] ?? 0), "\(season) \(weather)")
                    }
                    for (i, weather) in bag.enumerated() {
                        if weather == .mist { #expect(i % 2 == 0, "mist is a morning") }
                        if weather == .goldenHaze { #expect(i % 2 == 1, "golden haze is an afternoon") }
                        if weather == .lightRain, i + 1 < bag.count { #expect(bag[i + 1] != .lightRain) }
                    }
                }
            }
        }
    }

    @Test func onlyWinterSnowsAndOnlyAutumnAndSummerRain() {
        #expect(WeatherForecast.seasonCounts(.winter)?[.snow] ?? 0 > 0)
        #expect(WeatherForecast.seasonCounts(.winter)?[.lightRain] == nil)
        for season in [Season.summer, .autumn] {
            #expect(WeatherForecast.seasonCounts(season)?[.snow] == nil, "\(season)")
            #expect(WeatherForecast.seasonCounts(season)?[.lightRain] ?? 0 > 0, "\(season)")
        }
        #expect(WeatherForecast.seasonCounts(.autumn)?[.lightRain] ?? 0 > WeatherForecast.seasonCounts(.summer)?[.lightRain] ?? 0)
        #expect(WeatherForecast.seasonCounts(.summer)?[.clear] ?? 0 > WeatherForecast.seasonCounts(.autumn)?[.clear] ?? 0)
    }

    @Test func aWinterWeekSnowsAndTheSameDayGivesTheSameSky() {
        let start = LocalDay(year: 2026, month: 11, day: 6)
        var snowed = 0
        for week in 0 ..< 8 {
            var seen = Set<Weather>()
            for n in 0 ..< 7 {
                let day = start.adding(days: week * 7 + n)
                for hour in stride(from: 0.0, to: 24, by: 1) {
                    let a = WeatherForecast.conditions(on: day, hour: hour, start: start, season: .winter)
                    #expect(a == WeatherForecast.conditions(on: day, hour: hour, start: start, season: .winter))
                    #expect(!a.rainbow && !a.wet, "snow leaves no rainbow and no puddles")
                    seen.insert(a.weather)
                    if a.weather == .snow { #expect(hour >= 4 && hour < 23, "no snow in the deepest hours") }
                }
            }
            if seen.contains(.snow) { snowed += 1 }
            #expect(!seen.contains(.lightRain), "winter has no rain")
        }
        #expect(snowed == 8, "every winter week snows")
    }

    // MARK: The weather itself

    @Test func snowIsAnOvercastSkyThatIsNotRain() {
        #expect(Weather.snow.isSnowing && !Weather.snow.isRaining)
        #expect(Weather.snow.stateName == Weather.overcast.stateName)
        #expect(Weather.snow.mist == 0)
        let snowing = WeatherConditions(weather: .snow)
        #expect(!snowing.wet && !snowing.rainbow)
        #expect(!Atmosphere(conditions: snowing).isClear)
        let noon = WorldLight.at(hour: 12, wellbeing: 80, calm: 1, isBedtime: false)
        let lit = noon.withAtmosphere(Atmosphere(conditions: snowing))
        #expect(lit.pollen == 0)
        #expect(lit.shafts < noon.shafts + 0.001)
    }

    // MARK: The air

    @Test func theAirIsLeavesInAutumnAndSnowWhereItSnows() {
        #expect(SeasonAir.plan(season: .autumn, weather: .clear).leaves == SeasonAir.leafCount)
        #expect(SeasonAir.plan(season: .autumn, weather: .clear).flakes == 0)
        #expect(SeasonAir.plan(season: .autumn, weather: .lightRain).leaves < SeasonAir.leafCount)
        #expect(SeasonAir.plan(season: .winter, weather: .snow).flakes == SeasonAir.flakeCount)
        #expect(SeasonAir.plan(season: .winter, weather: .snow).leaves == 0)
        #expect(SeasonAir.plan(season: .summer, weather: .snow).flakes > 0, "a special day may snow in any season")
        for season in [nil, Season.spring, .summer, .winter] {
            #expect(SeasonAir.plan(season: season, weather: .clear).isEmpty, "\(String(describing: season))")
        }
        #expect(SeasonAir.plan(season: .autumn, weather: .snow).leaves == 0)
    }

    @Test func offUnderReduceMotionAndLowPowerAsRainIs() {
        #expect(SeasonAir.draws(reduceMotion: false, lowPower: false))
        #expect(!SeasonAir.draws(reduceMotion: true, lowPower: false))
        #expect(!SeasonAir.draws(reduceMotion: false, lowPower: true))
        #expect(SeasonAir.moves(still: false, ambientPaused: false, reduceMotion: false, lowPower: false))
        #expect(!SeasonAir.moves(still: true, ambientPaused: false, reduceMotion: false, lowPower: false))
        #expect(!SeasonAir.moves(still: false, ambientPaused: true, reduceMotion: false, lowPower: false), "the ambient tier's pause")
        #expect(!SeasonAir.moves(still: false, ambientPaused: false, reduceMotion: true, lowPower: false))
        #expect(!SeasonAir.moves(still: false, ambientPaused: false, reduceMotion: false, lowPower: true))
    }

    @Test func theAirIsPausedWhenTheFramePolicyPausesTheAmbientTier() {
        let policy = FramePolicy.standard
        let ambient = policy.directive(for: .ambient)
        #expect(!ambient.isPaused)
        #expect(SeasonAir.moves(still: false, ambientPaused: ambient.isPaused, reduceMotion: false, lowPower: false))
        let lowPower = policy.directive(for: .ambient, conditions: FrameConditions(lowPower: true))
        #expect(lowPower.isPaused)
        #expect(!SeasonAir.moves(still: false, ambientPaused: lowPower.isPaused, reduceMotion: false, lowPower: false))
        let settled = policy.directive(for: .settled)
        #expect(!SeasonAir.moves(still: false, ambientPaused: settled.isPaused, reduceMotion: false, lowPower: false))
    }

    @Test func particlesStayInsideTheScreenAndNeverFormAGrid() {
        let width = 402.0, height = 874.0
        for time in [0.0, 3.7, 41.0, 600.0] {
            var cells = Set<[Int]>()
            for i in 0 ..< SeasonAir.flakeCount {
                let f = SeasonAir.flake(i, time: time, width: width, height: height)
                #expect(f.y >= -SeasonAir.margin - 0.001 && f.y <= height + SeasonAir.margin + 0.001)
                #expect(f.radius >= 1.3 && f.radius <= 3.5)
                #expect(f.opacity >= 0 && f.opacity <= 0.9)
                cells.insert([Int(f.x / 20), Int(f.y / 20)])
            }
            // 36 flakes over 20 x 43 cells: spread, not stacked and not in rows.
            #expect(cells.count >= SeasonAir.flakeCount - 6)
            let rows = Set((0 ..< SeasonAir.flakeCount).map { Int(SeasonAir.flake($0, time: time, width: width, height: height).y / 6) })
            #expect(rows.count > SeasonAir.flakeCount / 2, "no rows of flakes")
            for i in 0 ..< SeasonAir.leafCount {
                let l = SeasonAir.leaf(i, time: time, width: width, height: height)
                #expect(l.y >= -SeasonAir.margin - 0.001 && l.y <= height + SeasonAir.margin + 0.001)
                #expect(l.tip >= 0.55 && l.tip <= 1.0001)
                #expect((0 ..< 3).contains(l.variant))
                #expect(l.length >= 10 && l.length <= 14)
            }
        }
    }

    @Test func particlesFallAndAreFadedAtTheEdges() {
        let width = 402.0, height = 874.0
        for i in 0 ..< SeasonAir.flakeCount {
            let a = SeasonAir.flake(i, time: 10, width: width, height: height)
            let b = SeasonAir.flake(i, time: 10.5, width: width, height: height)
            if b.y > a.y { #expect(b.y - a.y < 25, "calm: under 50 pt a second") }
            #expect(SeasonAir.flake(i, time: 10, width: width, height: height) == a, "the same time is the same frame")
        }
        #expect(SeasonAir.ramp(-SeasonAir.margin, height: height) == 0)
        #expect(SeasonAir.ramp(height / 2, height: height) == 1)
    }

    // MARK: The light

    @Test func springAndNoSeasonAreReturnedAsTheyAre() {
        let night = WorldLight.at(hour: 23, wellbeing: 80, calm: 1, isBedtime: false)
        #expect(night.withSeason(nil) == night)
        #expect(night.withSeason(.spring) == night)
        #expect(night.fireflies > 0)
    }

    @Test func firefliesKeepToSpringAndSummer() {
        let night = WorldLight.at(hour: 23, wellbeing: 80, calm: 1, isBedtime: false)
        #expect(night.withSeason(.summer).fireflies == night.fireflies)
        #expect(night.withSeason(.autumn).fireflies == 0)
        #expect(night.withSeason(.winter).fireflies == 0)
        let noon = WorldLight.at(hour: 12, wellbeing: 80, calm: 1, isBedtime: false)
        #expect(noon.withSeason(.autumn).pollen == 0)
        #expect(noon.withSeason(.summer).pollen == noon.pollen)
    }

    @Test func theTintIsAHairNotAFilter() {
        for season in Season.allCases {
            let t = SeasonAir.tint(season)
            for c in [t.r, t.g, t.b] { #expect(abs(c - 1) <= 0.04, "\(season)") }
        }
        #expect(SeasonAir.tint(.autumn).r > SeasonAir.tint(.autumn).b, "autumn is warmer")
        #expect(SeasonAir.tint(.winter).b > SeasonAir.tint(.winter).r, "winter is cooler")
        #expect(SeasonAir.tint(.spring) == .one && SeasonAir.tint(.summer) == .one)
    }

    @Test func aLookWithTheAirOffFollowsNoSeason() {
        var look = WorldLook()
        look.seasonOverride = .autumn
        #expect(look.seasonAir)
        var world = IslandSamples.dayThree()
        world.season = .winter
        #expect(look.airSeason(world) == .autumn, "the override wins")
        look.seasonOverride = nil
        #expect(look.airSeason(world) == .winter, "else the island year's")
        look.seasonOverride = .autumn
        look.seasonAir = false
        #expect(look.airSeason(world) == nil)
    }
}
