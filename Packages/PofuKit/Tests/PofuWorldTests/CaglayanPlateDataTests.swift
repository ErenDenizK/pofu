import Foundation
import PofuCore
import PofuDesignSystem
@testable import PofuWorld
import Testing

@Suite("Çağlayan plate data")
struct CaglayanPlateDataTests {
    @Test func paintsTheNightOfEveryStageBeforeHealing() throws {
        let plate = try #require(HomePlate.caglayanIsland)
        #expect(plate.painted["night"] == [0, 1, 2, 3])
    }

    @Test func everyCaglayanFrameOfTheDemoIsPainted() throws {
        let plate = try #require(HomePlate.caglayanIsland)
        let weathers: [WeatherConditions] = [
            .clear, WeatherConditions(weather: .overcast), WeatherConditions(weather: .mist),
            WeatherConditions(weather: .goldenHaze), WeatherConditions(weather: .clear, rainbow: true),
            WeatherConditions(weather: .lightRain),
        ]
        // The six hours of the demo: morning, day, golden hour, evening, night and bedtime's late hour.
        for stage in 0...4 {
            for hour in [6.0, 9, 12, 18, 22.5, 3] {
                for weather in weathers {
                    let state = HomePlate.caglayanState(in: plate, stage: stage, hour: hour, weather: weather, isBedtime: false)
                    #expect(state != nil, "stage \(stage) at \(hour) in \(weather)")
                }
            }
            #expect(HomePlate.caglayanState(in: plate, stage: stage, hour: 12, weather: .clear, isBedtime: true) != nil, "stage \(stage) at bedtime")
        }
    }

    @Test func theEarlyNightsAreTheirOwnPaintings() throws {
        let plate = try #require(HomePlate.caglayanIsland)
        for stage in 0...1 {
            let state = HomePlate.caglayanState(in: plate, stage: stage, hour: 22.5, weather: .clear, isBedtime: false)
            #expect(state?.light == "night" && state?.stage == stage, "stage \(stage)")
        }
    }
}
