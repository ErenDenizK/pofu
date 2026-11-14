import Foundation
import PofuCore
import PofuDesignSystem
@testable import PofuWorld
import Testing

@Suite("Çağlayan plate data")
struct CaglayanPlateDataTests {
    @Test func paintsTheNightOfEveryStage() throws {
        let plate = try #require(HomePlate.caglayanIsland)
        #expect(plate.painted["night"] == [0, 1, 2, 3, 4])
    }

    /// Every painted state is drawn full frame: its island layer over a sky set of its own light (ADR-0025), so no
    /// state shows the landscape plate as a band between flat fills.
    @Test func everyPaintedStateHasASkySetOfItsOwnLight() throws {
        let plate = try #require(HomePlate.caglayanIsland)
        let frame = try #require(SkySetFile.shipped("caglayan")?.lights["day-4"]?.plateFrame)
        var islands: Set<String> = []
        for (light, stages) in plate.painted {
            for stage in stages {
                let state = HomePlate(plate: plate, light: light, stage: stage, placement: CaglayanLayout.placement)
                let set = try #require(state.skySet, "\(light) \(stage)")
                #expect(set.light == light, "\(light) \(stage)")
                #expect(set.plateFrame == frame, "\(light) \(stage): placed by the island")
                #expect(PlateMath.budgetOK(set), "\(light) \(stage): \(set.textureBytes) bytes")
                let top = try #require(set.layers.last)
                #expect(top.role == .island, "\(light) \(stage)")
                islands.insert(top.asset)
            }
        }
        #expect(islands.count == plate.painted.values.map(\.count).reduce(0, +), "each state cuts its own island layer")
        #expect(SkySet.shipped(island: "caglayan", light: "night", stage: 4)?.layers.contains { $0.role == .stars } == true)
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
