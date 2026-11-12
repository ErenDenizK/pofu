import Foundation
import PofuCore
import PofuDesignSystem
@testable import PofuWorld
import Testing

/// The one grade for an island under a painted sky (`PaintedSky.islandGrade`): at every hour and in rain
/// the island darkens with the sky behind it, so its island-to-sky light ratio stays within ±10 % of its
/// day's, on the Map, at Koke's stop and at Çağlayan's (measured art: `Plates/painted-light.json`).
@Suite("An island in the hour's light")
struct IslandGradeTests {
    static let data = PaintedLight.shipped

    /// Linear light of a gamma-encoded mean colour.
    static func luminance(_ c: GradeRGB) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }

    static func graded(_ rgb: [Double], _ grade: WorldGrade) -> Double {
        luminance(grade.apply(GradeRGB(rgb[0], rgb[1], rgb[2])))
    }

    @Test func theDataIsShipped() throws {
        #expect(Self.data.state(island: "home", light: "night", stage: 0)?.sky != nil)
        #expect(Self.data.state(island: "caglayan", light: "rain", stage: 4) != nil)
        #expect(Self.data.states["koke"]?.isEmpty == false)
    }

    /// Koke's sprite at every stage under Home's sky, at golden hour and at night (the Map, its stop).
    @Test func kokeSitsInTheHourUnderHomesSky() throws {
        let skyDay = try #require(Self.data.state(island: "home", light: "day", stage: 0)?.sky)
        for (stage, art) in try #require(Self.data.states["koke"]) {
            let day = Self.graded(art.rgb, .neutral) / skyDay
            for (hour, light) in [(18.0, "golden"), (23.0, "night")] {
                var look = WorldLook(hourOverride: hour)
                look.weatherOverride = .clear
                let world = IslandSamples.world(clock: nil, tendedDays: 12, levels: [:], jar: .zero, islands: [.home], islandLevel: 5)
                let sky = try #require(PaintedSky.mapSky(world: world, look: look))
                #expect(sky.light == light)
                let skyL = try #require(Self.data.state(island: "home", light: light, stage: 0)?.sky)
                let ratio = Self.graded(art.rgb, PaintedSky.islandGrade(sky)) / skyL
                #expect(abs(ratio / day - 1) <= 0.10, "koke \(stage) \(light): \(ratio / day)")
            }
        }
    }

    /// Çağlayan's painted island at its own stop (night of every stage, rain) and on the Map at night.
    @Test func caglayanSitsInTheHourAtItsStopAndOnTheMap() throws {
        let island = try #require(HomePlate.caglayanIsland)
        let states = try #require(Self.data.states["caglayan"])
        for (key, art) in states where !key.hasPrefix("day") {
            let parts = key.split(separator: "-")
            let light = String(parts[0]), stage = Int(parts[1])!
            let dayArt = try #require(states["day-\(stage)"])
            let isle = HomePlate(plate: island, light: light, stage: stage)
            // Its stop: its own sky.
            let skyL = try #require(art.sky), skyDay = try #require(dayArt.sky)
            let day = Self.graded(dayArt.rgb, .neutral) / skyDay
            let atStop = Self.graded(art.rgb, PaintedSky.islandGrade(painted: isle, under: nil)) / skyL
            #expect(abs(atStop / day - 1) <= 0.10, "caglayan \(key) at its stop: \(atStop / day)")
        }
        // The Map at night: Home's night sky behind Çağlayan's night art.
        let home = try #require(HomePlate.shipped?.plate)
        let sky = HomePlate(plate: home, light: "night", stage: 0)
        let homeDay = try #require(Self.data.state(island: "home", light: "day", stage: 0)?.sky)
        let homeNight = try #require(Self.data.state(island: "home", light: "night", stage: 0)?.sky)
        for stage in 0...4 {
            guard let art = states["night-\(stage)"], let dayArt = states["day-\(stage)"] else { continue }
            let day = Self.graded(dayArt.rgb, .neutral) / homeDay
            let isle = HomePlate(plate: island, light: "night", stage: stage)
            let onMap = Self.graded(art.rgb, PaintedSky.islandGrade(painted: isle, under: sky)) / homeNight
            #expect(abs(onMap / day - 1) <= 0.10, "caglayan night-\(stage) on the Map: \(onMap / day)")
        }
    }

    @Test func dayIsNeutralAndNothingBrightens() {
        #expect(PaintedSky.islandGrade(light: "day", skyDrop: 1) == .neutral)
        #expect(PaintedSky.islandGrade(light: "rain", skyDrop: 1.2, artDrop: 0.8) == .neutral)
        let g = PaintedSky.islandGrade(light: "rain", skyDrop: 0.5)
        #expect(g.gain.r < 1 && g.gain.g < 1 && g.gain.b < 1)
    }
}
