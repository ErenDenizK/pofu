import Foundation
import PofuCore
import PofuDesignSystem
@testable import PofuWorld
import Testing

@Suite("Painted sky at the wonder stops")
struct PaintedSkyTests {
    static let world = IslandSamples.world(
        clock: nil, tendedDays: 12, levels: [:], jar: .zero, islands: [.home, .harbor], islandLevel: 5
    )

    static func look(_ hour: Double) -> WorldLook {
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = .clear
        return look
    }

    /// The phones the stop must cover: the reference one, a wide one and the shortest.
    static let screens: [(width: Double, height: Double)] = [(402, 874), (440, 956), (393, 852), (375, 667)]

    @Test func kokeAndTheHarborTakeHomesSkyAtTheHoursLight() throws {
        for island in [IslandID.koke, .harbor] {
            for (hour, light) in [(12.0, "day"), (18.0, "golden"), (23.0, "night"), (6.0, "day")] {
                let sky = try #require(PaintedSky.sky(for: island, world: Self.world, look: Self.look(hour)), "\(island) \(hour)")
                #expect(sky.light == light, "\(island) \(hour)")
                #expect(sky.stage == 0)
                #expect(sky.plate.island == "home")
                #expect(sky.skySet != nil)
            }
            // Bedtime is the night whatever the clock says.
            var bed = Self.world
            bed.isBedtime = true
            #expect(PaintedSky.sky(for: island, world: bed, look: Self.look(12))?.light == "night")
        }
    }

    @Test func weatherDoesNotChangeTheSky() throws {
        var rain = Self.look(12)
        rain.weatherOverride = WeatherConditions(weather: .lightRain)
        #expect(PaintedSky.sky(for: .koke, world: Self.world, look: rain)?.light == "day")
    }

    /// Each stop's sky set covers the whole screen at the stop's camera, below the island layer: the
    /// gradient sky over the screen, and the cloud sea down to its bottom edge.
    @Test(arguments: [IslandID.koke, .harbor])
    func theSkyCoversTheScreenAtTheStop(island: IslandID) throws {
        for light in ["day", "golden", "night"] {
            let hour = ["day": 12.0, "golden": 18.0, "night": 23.0][light]!
            let plate = try #require(PaintedSky.sky(for: island, world: Self.world, look: Self.look(hour)))
            let set = try #require(plate.skySet)
            for screen in Self.screens {
                let stop = try #require(IslandFraming.isleStop(island, width: screen.width, height: screen.height))
                let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
                func rect(_ layer: SkySet.Layer) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
                    let box = plate.worldBox(
                        master: PlateRect(minX: layer.pos.x, minY: layer.pos.y, maxX: layer.pos.x + layer.size.x, maxY: layer.pos.y + layer.size.y),
                        of: set
                    )
                    let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: screen.width)
                    return (a.x, a.y, a.x + box.width * pose.scale, a.y + box.height * pose.scale)
                }
                let sky = try #require(set.layers.first { $0.role == .sky })
                let s = rect(sky)
                #expect(s.minX <= 0 && s.minY <= 0 && s.maxX >= screen.width && s.maxY >= screen.height, "\(island) \(light) sky \(screen)")
                // A drift tile is drawn at -1, 0 and +1 widths: the sea's three copies cover the screen's width.
                let sea = try #require(set.layers.first { $0.role == .tile && $0.asset.contains("-sea-") })
                let r = rect(sea)
                let w = r.maxX - r.minX
                #expect(r.minX - w <= 0 && r.maxX + w >= screen.width, "\(island) \(light) sea width \(screen)")
                #expect(r.minY <= screen.height * 0.75 && r.maxY >= screen.height, "\(island) \(light) sea height \(screen)")
            }
        }
    }

    @Test func theSkyIsOnlyAtTheStop() throws {
        let width = 402.0, height = 874.0
        for island in [IslandID.koke, .harbor] {
            let stop = try #require(IslandFraming.isleStop(island, width: width, height: height))
            let at = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
            #expect(PaintedSky.fade(for: island, pose: at, viewportWidth: width) == 1, "\(island)")
            let other = island == .koke ? IslandID.harbor : .koke
            #expect(PaintedSky.fade(for: other, pose: at, viewportWidth: width) == 0, "\(other) from \(island)")
            #expect(PaintedSky.skies(world: Self.world, look: Self.look(12), pose: at, viewportWidth: width).map(\.island) == [island])
        }
        // The Map and Home show the code sky.
        let map = IslandFraming.mapStop(width: width, height: height)
        let atMap = CameraPose(scale: map.scale, look: map.look, anchorY: map.anchorY)
        #expect(PaintedSky.skies(world: Self.world, look: Self.look(12), pose: atMap, viewportWidth: width).isEmpty)
        let home = IslandFraming.homeStop(width: width)
        let atHome = CameraPose(scale: home.scale, look: home.look, anchorY: home.anchorY)
        #expect(PaintedSky.skies(world: Self.world, look: Self.look(12), pose: atHome, viewportWidth: width).isEmpty)
    }

    @Test func homeAndCaglayanKeepTheirOwnPainting() {
        #expect(PaintedSky.sky(for: .home, world: Self.world, look: Self.look(12)) == nil)
        #expect(PaintedSky.sky(for: .caglayan, world: Self.world, look: Self.look(12)) == nil)
    }

    @Test func noPaintedSkyWithoutPlates() {
        var look = Self.look(12)
        look.homePlates = false
        #expect(PaintedSky.sky(for: .koke, world: Self.world, look: look) == nil)
        #expect(PaintedSky.sky(for: .harbor, world: Self.world, look: look) == nil)
    }
}
