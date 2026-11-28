import Testing
@testable import PofuSound

@Suite("The ambience mix per season (island calendar v1, C2)")
struct SeasonAmbienceTests {
    private func mix(_ hour: Int, _ weather: AmbienceWeather = .clear, _ season: AmbienceSeason? = nil, snowing: Bool = false, level: Int = 10) -> AmbienceMix {
        AmbienceMixer.mix(for: AmbienceScene(hour: hour, weather: weather, islandLevel: level, season: season, snowing: snowing))
    }

    @Test func springAndNoSeasonAreTheMixTheIslandShipped() {
        for hour in [6, 12, 21] {
            for weather in AmbienceWeather.allCases {
                #expect(mix(hour, weather, .spring) == mix(hour, weather, nil), "\(hour) \(weather)")
            }
        }
        #expect(mix(12).level(of: .wind) == 0.7)
        #expect(mix(21).level(of: .crickets) == 0.8)
        #expect(mix(12, .overcast).level(of: .wind) == 1.0)
    }

    @Test func summerEveningsAreTheCricketOnes() {
        #expect(mix(21, .clear, .summer).level(of: .crickets) > mix(21, .clear, .spring).level(of: .crickets))
        #expect(mix(21, .clear, .summer).level(of: .crickets) > mix(21, .clear, .autumn).level(of: .crickets))
        #expect(mix(12, .clear, .summer).level(of: .wind) < mix(12, .clear, .spring).level(of: .wind))
    }

    @Test func autumnIsWindierAndThinnerOfCrickets() {
        #expect(mix(12, .clear, .autumn).level(of: .wind) > mix(12, .clear, .spring).level(of: .wind))
        #expect(mix(21, .clear, .autumn).level(of: .crickets) < mix(21, .clear, .spring).level(of: .crickets))
    }

    @Test func winterHasNoCricketsNoGullsAndAHush() {
        for hour in [8, 12, 21] {
            let m = mix(hour, .clear, .winter)
            #expect(m.level(of: .crickets) == 0, "hour \(hour)")
            #expect(!m.gulls)
        }
        #expect(mix(12, .clear, .winter).level(of: .hush) > 0)
        #expect(mix(12, .clear, .winter).level(of: .wind) < mix(12, .clear, .spring).level(of: .wind))
    }

    @Test func snowIsAHushWithALittleWindAndNothingSharp() {
        let snow = mix(14, .overcast, .winter, snowing: true)
        #expect(snow.level(of: .hush) > 0.5)
        #expect(snow.level(of: .rain) == 0 && snow.level(of: .crickets) == 0)
        #expect(snow.level(of: .wind) < 0.2)
        #expect(!snow.gulls)
        #expect(mix(21, .overcast, nil, snowing: true).level(of: .crickets) == 0, "snow in any season")
    }

    @Test func bedtimeIsStillSilentInEverySeasonAndInSnow() {
        for hour in AmbienceMixer.bedtimeHours {
            for season in [nil, AmbienceSeason.spring, .summer, .autumn, .winter] {
                #expect(mix(hour, .clear, season).isSilent)
                #expect(mix(hour, .overcast, season, snowing: true).isSilent)
            }
        }
    }

    @Test func rainAndMistKeepTheirOwnMixInAnySeason() {
        for season in [AmbienceSeason.summer, .autumn, .winter] {
            #expect(mix(14, .lightRain, season).level(of: .rain) == 1)
            #expect(mix(8, .mist, season).level(of: .hush) == 1)
        }
    }

    @Test func seasonNamesMap() {
        #expect(AmbienceSeason(seasonName: "autumn") == .autumn)
        #expect(AmbienceSeason(seasonName: nil) == nil)
        #expect(AmbienceSeason(seasonName: "monsoon") == nil)
    }
}
