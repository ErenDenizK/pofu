import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The season as a third key on the painted state (season-system-v1 D3, D4): spring's key is today's, a state the data does
/// not list is spring's for every piece, a listed one names none of spring's assets, and a season not `complete` stays
/// spring unless Rehearsal forces it. No season data ships in S1, so these tests give the shipped plate a season.
struct SeasonStateTests {
    private var home: PlateIsland {
        get throws { try #require(HomePlate.shipped?.plate) }
    }

    /// Every state the shipped plate paints: 26.
    private func states(_ plate: PlateIsland) -> [(light: String, stage: Int)] {
        plate.lights.flatMap { light in (plate.painted[light] ?? []).map { (light: light, stage: $0) } }
    }

    /// The shipped plate with autumn listed at day stage 3 (the tea stall stands over a base there) and night stage 0.
    private func autumn(complete: Bool = false) throws -> PlateIsland {
        var plate = try home
        plate.seasons["autumn"] = SeasonStates(complete: complete, states: ["day": [3], "night": [0]])
        plate.stations["teaStall"]?.lights["autumn-day"] = [3]
        return plate
    }

    private func world(level: Int, season: Season?) -> WorldSnapshot {
        var world = IslandSamples.world(clock: nil, tendedDays: 30, levels: [.teaStall: 3], jar: .zero, islands: [.home], islandLevel: level)
        world.season = season
        return world
    }

    private func look(_ season: Season? = nil) -> WorldLook {
        var look = WorldLook.islandStop(hour: 12)
        look.seasonOverride = season
        return look
    }

    /// What a state draws, by piece: plate, base, island cut, Map cut, backdrop, every occluder, the tea stall's look.
    private func names(_ home: HomePlate) -> [String] {
        let plate = home.plate
        var out = [
            plate.plateArt(light: home.key, stage: home.stage), plate.drawnPlateArt(light: home.key, stage: home.stage),
            plate.islandArt(light: home.key, stage: home.stage), plate.mapIslandArt(light: home.key, stage: home.stage),
            plate.backdropArt(light: home.key, stage: home.stage),
        ]
        out += plate.objects.filter(\.occluder).map { plate.occluderArt(id: $0.id, light: home.key, stage: home.stage) }
        out += [plate.lookArt(station: "teaStall", level: 3, light: home.key, stage: home.stage) ?? "none"]
        return out
    }

    @Test func springsKeyIsTodaysForAll26States() throws {
        let plate = try home
        let all = states(plate)
        #expect(all.count == 26)
        for state in all {
            #expect(PlateIsland.key(season: .spring, light: state.light) == state.light)
            let spring = HomePlate(plate: plate, light: state.light, stage: state.stage)
            #expect(spring.season == .spring && spring.key == state.light)
            #expect(plate.plateArt(light: spring.key, stage: state.stage) == "world-home-plate-\(state.light)-\(state.stage)")
            #expect(plate.drawnPlateArt(light: spring.key, stage: state.stage) == plate.drawnPlateArt(light: state.light, stage: state.stage))
            #expect(plate.mapIslandArt(light: spring.key, stage: state.stage) == "world-home-mapisle-\(state.light)-\(state.stage)")
            #expect(plate.occluderArt(id: "windmill", light: spring.key, stage: state.stage) == "world-home-occ-windmill-\(state.light)-\(state.stage)")
            #expect(spring.harmony == plate.harmony(light: state.light, stage: state.stage))
        }
        #expect(PlateIsland.key(season: .autumn, light: "night") == "autumn-night")
        #expect(StationLooks.lookLight(for: "autumn-golden") == "autumn-day" && StationLooks.lookLight(for: "golden") == "day")
    }

    @Test func anUnlistedStateResolvesToSpringForEveryPiece() throws {
        let plate = try autumn()
        let shipped = try #require(HomePlate.shipped)
        // Stage 4 (level 6) day is not listed: asked for autumn, the whole state is spring.
        let spring = try #require(HomePlate.resolve(shipped, world: world(level: 6, season: nil), look: look()))
        let asked = try #require(HomePlate.resolve(HomePlate(plate: plate), world: world(level: 6, season: .autumn), look: look(.autumn)))
        #expect(asked.stage == 4 && asked.season == .spring && asked.key == "day")
        #expect(names(asked) == names(spring))
        #expect(plate.season(.autumn, light: "golden", stage: 3, forced: true) == .spring)
        #expect(plate.season(.winter, light: "day", stage: 3, forced: true) == .spring)
        #expect(plate.season(.summer, light: "day", stage: 3, forced: true) == .spring)
    }

    @Test func aListedStateNamesNoneOfSpringsAssets() throws {
        let plate = try autumn()
        let spring = HomePlate(plate: plate, light: "day", stage: 3)
        let listed = try #require(HomePlate.resolve(HomePlate(plate: plate), world: world(level: 7, season: .autumn), look: look(.autumn)))
        #expect(listed.season == .autumn && listed.light == "day" && listed.key == "autumn-day")
        let springNames = names(spring), seasonNames = names(listed)
        #expect(springNames.count == seasonNames.count)
        for (a, b) in zip(springNames, seasonNames) { #expect(a != b, "\(a)") }
        #expect(seasonNames.contains("world-home-base-autumn-day-3") && seasonNames.contains("world-home-look-teaStall-3-autumn-day"))
        // Night has no looks and no base: its plate is drawn, still the season's.
        let night = HomePlate(plate: plate, light: "night", stage: 0, season: .autumn)
        #expect(plate.drawnPlateArt(light: night.key, stage: 0) == "world-home-plate-autumn-night-0")
    }

    @Test func anIncompleteSeasonIsSpringUnlessRehearsalForcesIt() throws {
        let incomplete = HomePlate(plate: try autumn(complete: false))
        let complete = HomePlate(plate: try autumn(complete: true))
        let w = world(level: 7, season: .autumn)
        #expect(try #require(HomePlate.resolve(incomplete, world: w, look: look())).season == .spring)
        #expect(try #require(HomePlate.resolve(incomplete, world: w, look: look(.autumn))).season == .autumn)
        #expect(try #require(HomePlate.resolve(complete, world: w, look: look())).season == .autumn)
        // Spring asked for, or no season at all: spring.
        #expect(try #require(HomePlate.resolve(complete, world: world(level: 7, season: .spring), look: look())).season == .spring)
        #expect(try #require(HomePlate.resolve(complete, world: world(level: 7, season: nil), look: look())).season == .spring)
        #expect(try #require(HomePlate.resolve(complete, world: w, look: look(.spring))).season == .spring)
    }

    /// The autumn slice (S3): level 10 by day and by night, listed but not complete, so only Rehearsal and the screenshot tests
    /// draw it, and every asset a listed state can ask for ships (the tea stall waits for its level 3 re-take).
    @Test func theShippedDataListsTheAutumnSliceAsIncomplete() throws {
        let plate = try home
        let autumn = try #require(plate.seasons["autumn"])
        #expect(!autumn.complete && autumn.states == ["day": [0], "night": [0]])
        #expect(plate.season(.autumn, light: "day", stage: 0) == .spring, "not complete: spring unless forced")
        #expect(plate.season(.autumn, light: "day", stage: 0, forced: true) == .autumn)
        #expect(plate.season(.autumn, light: "day", stage: 7, forced: true) == .spring, "stage 7 is not listed")
        #expect(plate.season(.autumn, light: "golden", stage: 0, forced: true) == .spring, "golden is not listed")
        for light in ["day", "night"] {
            let key = PlateIsland.key(season: .autumn, light: light)
            var names = [plate.plateArt(light: key, stage: 0), plate.islandArt(light: key, stage: 0), plate.mapIslandArt(light: key, stage: 0)]
            names += plate.objects.filter(\.occluder).map { plate.occluderArt(id: $0.id, light: key, stage: 0) }
            for name in names {
                #expect(assetExists(name), "\(name)")
            }
        }
        #expect(plate.stations["windmill"]?.lookLevels["autumn-day"] == [2, 3, 4, 5])
        #expect(plate.lookArt(station: "windmill", level: 5, light: "autumn-day", stage: 0) == "world-home-look-windmill-5-autumn-day")
        #expect(plate.drawnPlateArt(light: "autumn-day", stage: 0) == "world-home-base-autumn-day-0")
        #expect(plate.drawnPlateArt(light: "autumn-night", stage: 0) == "world-home-plate-autumn-night-0")
        #expect(plate.stations["teaStall"]?.lights["autumn-day"] == nil, "the tea stall has no autumn state yet")
    }

    private func assetExists(_ name: String) -> Bool {
        let assets = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        return FileManager.default.fileExists(atPath: assets.appendingPathComponent("\(name).imageset/Contents.json").path)
    }

    @Test func theDataDecodesSeasons() throws {
        let json = """
        {"island":"s","lights":["day"],"islandBox":[0,0,10,10],"objects":[],"plateSize":[10,10],
         "seasons":{"autumn":{"complete":false,"states":{"day":[0,7]}},"winter":{"states":{}}}}
        """
        let plate = try PlateIsland.decode(Data(json.utf8))
        #expect(plate.seasons["autumn"] == SeasonStates(complete: false, states: ["day": [0, 7]]))
        #expect(plate.seasons["winter"] == SeasonStates())
    }
}
