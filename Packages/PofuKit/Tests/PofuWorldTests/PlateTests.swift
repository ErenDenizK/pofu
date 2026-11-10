import Foundation
import PofuCore
import PofuDesignSystem
@testable import PofuWorld
import Testing

struct PlateMathTests {
    /// A U: the notch between its arms is outside.
    let u = [
        PlatePoint(x: 0, y: 0), PlatePoint(x: 10, y: 0), PlatePoint(x: 10, y: 10), PlatePoint(x: 7, y: 10),
        PlatePoint(x: 7, y: 3), PlatePoint(x: 3, y: 3), PlatePoint(x: 3, y: 10), PlatePoint(x: 0, y: 10),
    ]

    @Test func containsAConcavePolygonButNotItsNotch() {
        #expect(PlateMath.contains(u, PlatePoint(x: 1.5, y: 8)))
        #expect(PlateMath.contains(u, PlatePoint(x: 5, y: 1.5)))
        #expect(!PlateMath.contains(u, PlatePoint(x: 5, y: 8)))
        #expect(!PlateMath.contains(u, PlatePoint(x: 12, y: 5)))
    }

    @Test func hitPrefersTheNearestObject() throws {
        let island = try PlateIsland.decode(Data(PlateIslandTests.example.utf8))
        // The hut (foot 60) and the well (foot 80) overlap at (55, 55).
        #expect(PlateMath.hit(island, at: PlatePoint(x: 55, y: 55))?.id == "well")
        #expect(PlateMath.hit(island, at: PlatePoint(x: 25, y: 25))?.id == "hut")
        #expect(PlateMath.hit(island, at: PlatePoint(x: 300, y: 300)) == nil)
    }

    @Test func occludersCoverOnlyACharacterBehindThem() throws {
        let island = try PlateIsland.decode(Data(PlateIslandTests.example.utf8))
        let behind = PlateMath.occluders(over: (footY: 50, box: PlateRect(minX: 25, minY: 30, maxX: 35, maxY: 50)), in: island)
        #expect(behind.map(\.id) == ["hut"])
        let inFront = PlateMath.occluders(over: (footY: 70, box: PlateRect(minX: 25, minY: 50, maxX: 35, maxY: 70)), in: island)
        #expect(inFront.isEmpty)
        let aside = PlateMath.occluders(over: (footY: 50, box: PlateRect(minX: 200, minY: 30, maxX: 210, maxY: 50)), in: island)
        #expect(aside.isEmpty)
    }

    @Test func lightOfAConstantMapIsThatColour() {
        let map = Array(repeating: Array(repeating: "#336699", count: 32), count: 20)
        let c = PlateMath.light(at: PlatePoint(x: 700, y: 300), map: map, plateSize: PlateRect(minX: 0, minY: 0, maxX: 1536, maxY: 1024))
        #expect(abs(c.red - 0x33 / 255.0) < 1e-9)
        #expect(abs(c.blue - 0x99 / 255.0) < 1e-9)
    }

    @Test func lightInterpolatesBetweenCells() {
        let map = [["#000000", "#ffffff"]]
        let size = PlateRect(minX: 0, minY: 0, maxX: 200, maxY: 100)
        let mid = PlateMath.light(at: PlatePoint(x: 100, y: 50), map: map, plateSize: size)
        #expect(abs(mid.green - 0.5) < 1e-9)
        let left = PlateMath.light(at: PlatePoint(x: 10, y: 50), map: map, plateSize: size)
        #expect(left.green == 0)
    }

    @Test func gainIsOneInTheOpenAndDarkerInTheLee() {
        let open = PofuRGB(hex: 0x9ACD5A)
        #expect(PlateMath.characterGain(light: open, reference: open) == 1)
        #expect(PlateMath.characterGain(light: PofuRGB(hex: 0xFFFFFF), reference: open) == 1)
        let lee = PlateMath.characterGain(light: PofuRGB(hex: 0x6E9A3E), reference: open)
        #expect(lee < 1 && lee >= 0.78)
        #expect(PlateMath.characterGain(light: PofuRGB(hex: 0x000000), reference: open) == 0.78)
    }

    @Test func contactRatioIsTheShadowOverTheLitClamped() {
        let lit = PofuRGB(hex: 0xA0C060)
        #expect(PlateMath.contactRatio(lit: lit, shadow: lit) == PofuRGB(red: 1, green: 1, blue: 1))
        let black = PlateMath.contactRatio(lit: lit, shadow: PofuRGB(hex: 0x000000))
        let floor = 1.055 * pow(0.15, 1 / 2.4) - 0.055
        #expect(abs(black.red - floor) < 1e-9)
        let dark = PlateMath.contactRatio(lit: lit, shadow: PofuRGB(hex: 0x506030))
        #expect(dark.green < 1 && dark.green > floor)
    }

    @Test func framingGivesTheWidths() {
        let s = PlateMath.framing(islandWidthUnits: 300, widths: 1.35, screenWidthPoints: 402)
        #expect(abs(300 * s - 1.35 * 402) < 1e-9)
    }

    @Test func budgetIsNineMegabytes() throws {
        var island = try PlateIsland.decode(Data(PlateIslandTests.example.utf8))
        island.textureBytes = 9_000_000
        #expect(PlateMath.budgetOK(island))
        island.textureBytes = 9_000_001
        #expect(!PlateMath.budgetOK(island))
    }
}

struct PlateIslandTests {
    static let example = """
    {"island":"test","version":1,"standIn":true,"minLevel":10,"plateSize":[1536,1024],"stages":1,"lights":["day"],
     "islandBox":[10,10,1500,900],"backdropBox":[-300,-1500,1800,3500],
     "objects":[
      {"id":"hut","tap":true,"label":"test.hut","station":"teaStall","polygon":[[20,20],[60,20],[60,60],[20,60]],"footY":60,"occluder":true,"box":[16,16,64,64],"sway":0,"emissive":false},
      {"id":"well","tap":true,"label":"test.well","polygon":[[50,50],[90,50],[90,80],[50,80]],"footY":80,"occluder":false,"sway":0,"emissive":false}
     ],
     "walkable":[[0,0],[200,0],[200,200],[0,200]],
     "characters":{"pofu":[100,100],"mochi":[60,120]},
     "pofuWidth":110,"residentBoost":1.3,
     "framing":{"homeWidths":1.2,"homeCenterX":0.5,"homeTopY":180,"islandWidths":0.8,"wholeWidths":0.9},
     "lightDirection":[-0.5,0.3],
     "lightMap":{"day":[[["#ffffff","#ffffff"],["#ffffff","#ffffff"]]]},
     "shadowMap":{"day":[[["#808080","#808080"],["#808080","#808080"]]]},
     "textureBytes":3000000}
    """

    @Test func decodesTheIngestSchema() throws {
        let island = try PlateIsland.decode(Data(Self.example.utf8))
        #expect(island.island == "test")
        #expect(island.minLevel == 10)
        #expect(island.plateSize.width == 1536)
        #expect(island.objects.count == 2)
        #expect(island.object("hut")?.station == .teaStall)
        #expect(island.object("hut")?.box == PlateRect(minX: 16, minY: 16, maxX: 64, maxY: 64))
        #expect(island.object("well")?.station == nil)
        #expect(island.characters["pofu"] == PlatePoint(x: 100, y: 100))
        #expect(island.framing.homeTopY == 180)
        #expect(island.lightMap["day"]?.first?.count == 2)
    }

    @Test func assetNamesFollowTheSpec() throws {
        let island = try PlateIsland.decode(Data(Self.example.utf8))
        #expect(island.plateArt(light: "day", stage: 0) == "world-test-plate-day-0")
        #expect(island.islandArt(light: "day", stage: 0) == "world-test-island-day-0")
        #expect(island.backdropArt(light: "day", stage: 0) == "world-test-backdrop-day-0")
        #expect(island.occluderArt(id: "hut", light: "day", stage: 0) == "world-test-occ-hut-day-0")
        #expect(island.diffArt(light: "night", from: 2) == "world-test-diff-night-2")
        #expect(island.emissiveArt(light: "night", stage: 4) == "world-test-emit-night-4")
        #expect(island.upgradeArt(id: "bench", light: "day") == "world-test-up-bench-day")
        #expect(island.lutArt(light: "golden") == "world-lut-plate-test-golden")
    }

    @Test func loadReturnsNilWithoutTheResource() {
        #expect(PlateIsland.load("nowhere") == nil)
    }
}

struct HomePlateTests {
    var plate: HomePlate {
        get throws { try #require(HomePlate.shipped, "the package ships Plates/plate-home.json") }
    }

    @Test func pofuStandsOnHisPaintedSpot() throws {
        let home = try plate
        let spot = try #require(home.plate.characters["pofu"])
        let w = home.world(spot)
        #expect(abs(w.x - IslandLayout.pofu.x) < 1e-9)
        #expect(abs(w.y - IslandLayout.pofu.y) < 1e-9)
        let back = home.plate(w)
        #expect(abs(back.x - spot.x) < 1e-9 && abs(back.y - spot.y) < 1e-9)
    }

    @Test func everyCharacterStandsOnTheWalkableLawn() throws {
        let home = try plate
        for (name, spot) in home.plate.characters {
            #expect(PlateMath.contains(home.plate.walkable, spot), "\(name)")
        }
    }

    @Test func homeFramesTheIslandAtItsWidthsWithItsTopWhereAsked() throws {
        let home = try plate
        let stop = home.homeStop
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let box = home.islandBox
        let left = pose.project(WorldPoint(x: box.minX, y: box.minY), width: CameraRail.referenceWidth)
        let right = pose.project(WorldPoint(x: box.maxX, y: box.minY), width: CameraRail.referenceWidth)
        #expect(abs((right.x - left.x) - home.plate.framing.homeWidths * CameraRail.referenceWidth) < 1e-6)
        #expect(abs(left.y - home.plate.framing.homeTopY) < 1e-6)
        // The screen's centre sits at `homeCenterX` of the island's width.
        let centre = left.x + (right.x - left.x) * home.plate.framing.homeCenterX
        #expect(abs(centre - CameraRail.referenceWidth / 2) < 1)
    }

    @Test func theIslandStopAndTheWholeShotShowTheWholeIsland() throws {
        let home = try plate
        for stop in [home.islandStop, home.wholeStop] {
            let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
            let box = home.islandBox
            let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: CameraRail.referenceWidth)
            let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: CameraRail.referenceWidth)
            #expect(a.x > 0 && b.x < CameraRail.referenceWidth)
            #expect(a.y > IslandFraming.topBand && b.y < CameraRail.referenceHeight - IslandFraming.bottomBand + 60)
        }
    }

    @Test func theBackdropCoversTheScreenAtEveryStop() throws {
        let home = try plate
        for stop in [home.homeStop, home.islandStop, home.wholeStop] {
            let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
            let box = home.backdropBox
            let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: CameraRail.referenceWidth)
            let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: CameraRail.referenceWidth)
            #expect(a.x <= 0 && a.y <= 0)
            #expect(b.x >= CameraRail.referenceWidth && b.y >= CameraRail.referenceHeight)
        }
    }

    @Test func charactersAreSmallOnThePlate() throws {
        let home = try plate
        // Pofu keeps his share of the painted world (33 points at a 1.0 framing, 1.15 times that at
        // 1.15: about 38), the residents in proportion (docs/design/visual-system.md, Composition).
        let pofu = 64 * home.characterScale * IslandFraming.homeScale
        #expect(abs(pofu - 33 * home.plate.framing.homeWidths) < 0.5)
        let mochi = 30.4 * home.residentScale(.mochi) * IslandFraming.homeScale
        #expect(mochi > 17)
        #expect(abs(home.residentScale / home.characterScale - home.plate.residentBoost) < 1e-9)
        // Mochi and Findik are at least 60 % of Pofu's painted height (his art is 64 x 60.8 units).
        let pofuHeight = 60.8 * home.characterScale
        #expect(23.3 * home.residentScale(.mochi) >= 0.6 * pofuHeight)
        #expect(26.8 * home.residentScale(.findik) >= 0.6 * pofuHeight)
    }

    @Test func choosesItsPaintedStateByLevelHourAndWeather() throws {
        let plate = try self.plate.plate
        func state(_ level: Int, _ hour: Double, _ weather: WeatherConditions = .clear, bed: Bool = false) -> String? {
            HomePlate.state(in: plate, islandLevel: level, hour: hour, weather: weather, isBedtime: bed).map { "\($0.light)-\($0.stage)" }
        }
        // Day: one painted plate per level, 10 down to 2.
        #expect(state(10, 12) == "day-0")
        #expect(state(9, 12) == "day-1")
        #expect(state(2, 12) == "day-8")
        #expect(state(1, 12) == nil)
        #expect(state(12, 12) == "day-0")
        // Golden hour and night: level 10 only.
        #expect(state(10, 18) == "golden-0")
        #expect(state(10, 22.5) == "night-0")
        #expect(state(10, 3) == "night-0")
        #expect(state(10, 12, bed: true) == "night-0")
        #expect(state(9, 18) == nil)
        #expect(state(9, 22.5) == nil)
        // Dawn, dusk and weather keep the sprite island.
        #expect(state(10, 6.5) == nil)
        #expect(state(10, 19.75) == nil)
        #expect(state(10, 12, WeatherConditions(weather: .lightRain)) == nil)
    }

    @Test func resolvesFromTheLooksHourAndWeather() throws {
        let home = try plate
        let world = IslandSamples.world(
            clock: nil, tendedDays: 60, levels: [:], jar: .zero, islands: [.home], islandLevel: 10
        )
        #expect(HomePlate.resolve(home, world: world, look: WorldLook(hourOverride: 12))?.light == "day")
        #expect(HomePlate.resolve(home, world: world, look: WorldLook(hourOverride: 18))?.light == "golden")
        #expect(HomePlate.resolve(home, world: world, look: WorldLook(hourOverride: 22.5))?.light == "night")
        var rain = WorldLook(hourOverride: 12)
        rain.weatherOverride = WeatherConditions(weather: .lightRain)
        #expect(HomePlate.resolve(home, world: world, look: rain) == nil)
        let low = IslandSamples.world(clock: nil, tendedDays: 5, levels: [:], jar: .zero, islands: [.home], islandLevel: 5)
        #expect(HomePlate.resolve(home, world: low, look: WorldLook(hourOverride: 12))?.stage == 5)
    }

    @Test func aLowerLevelHasNoPolygonOrOccluderOnWhatItDoesNotPaint() throws {
        let top = try plate
        let plate = top.plate
        // Level 5 (stage 5): no windmill, workshop, lighthouse or bushes; the tea stall and the door stay.
        let five = HomePlate(plate: plate, light: "day", stage: 5)
        let ids = Set(five.objects.map(\.id))
        for gone in ["windmill", "workshop", "lighthouse", "mailbox", "westBush", "eastBush"] {
            #expect(!ids.contains(gone), "\(gone)")
        }
        for kept in ["teaStall", "door", "wheel", "pond"] {
            #expect(ids.contains(kept), "\(kept)")
        }
        let windmill = try #require(plate.object("windmill"))
        let c = PlatePoint(
            x: windmill.polygon.map(\.x).reduce(0, +) / Double(windmill.polygon.count),
            y: windmill.polygon.map(\.y).reduce(0, +) / Double(windmill.polygon.count)
        )
        #expect(top.tapObject(at: top.world(c))?.id == "windmill")
        #expect(five.tapObject(at: five.world(c))?.id != "windmill")
        #expect(five.stationBox(.windmill) == nil)
        // Every painted state has what its objects need: occluders only where present.
        for light in plate.lights {
            for stage in 0..<(plate.lightStages[light] ?? 1) {
                let state = HomePlate(plate: plate, light: light, stage: stage)
                #expect(state.objects.count <= plate.objects.count)
                #expect(state.objects.contains { $0.id == "door" })
            }
        }
        // Golden and night paint everything.
        #expect(HomePlate(plate: plate, light: "night", stage: 0).objects.count == plate.objects.count)
    }

    @Test func eachStateCarriesItsHarmonyData() throws {
        let plate = try self.plate.plate
        for light in plate.lights {
            #expect(plate.harmony[light]?.count == plate.lightStages[light])
        }
        let day = plate.harmony(light: "day", stage: 0)
        #expect(day.tint == PofuRGB(red: 1, green: 1, blue: 1) && day.contact == 1)
        // The night plate's lawn is darker: its tint darkens, never brightens.
        let night = plate.harmony(light: "night", stage: 0)
        #expect(night.tint.red < 1 && night.tint.green < 1 && night.tint.blue <= 1)
        for light in plate.lights {
            for h in plate.harmony[light] ?? [] {
                #expect(h.contact >= 0.5 && h.contact <= 1.2)
                #expect(h.tint.red <= 1 && h.tint.green <= 1 && h.tint.blue <= 1)
                #expect(min(h.tint.red, h.tint.green, h.tint.blue) >= 0.25)
            }
        }
        let nightPlate = HomePlate(plate: plate, light: "night", stage: 0)
        let paint = nightPlate.paint(at: IslandLayout.pofu)
        #expect(paint.red < 1)
    }

    @Test func goldenAndNightGiveTheCharactersAKeyLight() throws {
        let plate = try self.plate.plate
        let day = HomePlate(plate: plate, light: "day", stage: 0)
        let golden = HomePlate(plate: plate, light: "golden", stage: 0)
        let night = HomePlate(plate: plate, light: "night", stage: 0)
        let size = (width: 64 * golden.characterScale, height: 60.8 * golden.characterScale)
        let dayLight = day.characterLight(at: IslandLayout.pofu, width: size.width, height: size.height, id: "pofu")
        let goldenLight = golden.characterLight(at: IslandLayout.pofu, width: size.width, height: size.height, id: "pofu")
        let nightLight = night.characterLight(at: IslandLayout.pofu, width: size.width, height: size.height, id: "pofu")
        #expect(dayLight.rim == 0 && dayLight.pool == 0)
        // Golden hour: the sun's rim from the upper left, no lamp pool.
        #expect(goldenLight.rim > 0 && goldenLight.pool == 0)
        #expect(goldenLight.toward.x < 0 && goldenLight.toward.y < 0)
        // Night: Pofu stands by a lamp, whose pool and rim light him; far from every lamp they fade.
        #expect(nightLight.pool > 0 && nightLight.rim > 0)
        let far = night.characterLight(at: WorldPoint(x: IslandLayout.pofu.x + 4000, y: IslandLayout.pofu.y), width: size.width, height: size.height, id: "pofu")
        #expect(far.pool == 0 && far.rim < nightLight.rim)
        for l in [dayLight, goldenLight, nightLight] {
            // The core is the lawn's shadow, deeper, in the same hue: never lighter than the pad.
            #expect(l.core.green <= l.pad.green && l.core.red <= l.pad.red && l.core.blue <= l.pad.blue)
            #expect(abs(hypot(l.toward.x, l.toward.y) - 1) < 1e-9)
            #expect(l.bounceAmount > 0 && l.bounceAmount <= 0.15)
        }
    }

    @Test func tapsLandOnTheirStations() throws {
        let home = try plate
        for station in [StationID.teaStall, .garden, .windmill, .pond] {
            let object = try #require(home.plate.objects.first { $0.station == station }, "\(station)")
            let b = PlateMath.bounds(object.polygon)
            // A point well inside the outline: the centroid of its vertices.
            let c = PlatePoint(
                x: object.polygon.map(\.x).reduce(0, +) / Double(object.polygon.count),
                y: object.polygon.map(\.y).reduce(0, +) / Double(object.polygon.count)
            )
            #expect(b.width > 0)
            #expect(home.tapObject(at: home.world(c))?.station == station, "\(station)")
        }
        #expect(home.plate.object("door")?.tap == true)
    }

    @Test func theEastBushHidesWhoeverStandsBehindItAndNobodyAtRest() throws {
        let home = try plate
        let art = WorldBox(minX: -14.3, minY: -26.8, maxX: 14.4, maxY: 0.2)
        let bush = try #require(home.plate.object("eastBush"))
        let b = PlateMath.bounds(bush.polygon)
        // Just behind the bush's foot line, in its middle: drawn under it.
        let behind = home.world(PlatePoint(x: (b.minX + b.maxX) / 2, y: bush.footY - 30))
        #expect(home.occluders(over: behind, box: home.residentBox(art: art, at: behind)).map(\.id) == ["eastBush"])
        // At rest, everyone stands in the open, whole.
        let findik = try #require(home.residentFeet(.findik))
        #expect(home.occluders(over: findik, box: home.residentBox(art: art, at: findik)).isEmpty)
        #expect(home.occluders(over: IslandLayout.pofu, box: home.pofuBox).isEmpty)
    }

    @Test func pofuKeepsHisPaintOnTheOpenLawn() throws {
        let home = try plate
        #expect(home.gain(at: IslandLayout.pofu) == 1)
        let tone = home.contactTone(at: IslandLayout.pofu)
        #expect(tone.green < 1 && tone.green > 0.3)
    }

    @Test func theIslandStaysClearOfTheHarbor() throws {
        let home = try plate
        let harbor = try #require(IslandLayout.isles.first { $0.id == .harbor })
        #expect(home.islandBox.maxX < harbor.center.x - 40)
    }

    @Test func budgetFits() throws {
        #expect(PlateMath.budgetOK(try plate.plate))
    }
}

struct PlateHitTests {
    @Test func aPolygonTargetAnswersOnlyInsideItsOutline() {
        // A triangle: its box's corner is outside it.
        let triangle = [WorldPoint(x: 0, y: 0), WorldPoint(x: 100, y: 0), WorldPoint(x: 0, y: 100)]
        let target = HitTarget(
            kind: .plateObject("hut"), worldBox: WorldBox(minX: 0, minY: 0, maxX: 100, maxY: 100), depth: 0, polygon: triangle
        )
        let pose = CameraPose(scale: 1, look: WorldPoint(x: 0, y: 0), anchorY: 0)
        let width = 402.0
        #expect(WorldHitTest.resolve(x: 201 + 20, y: 20, targets: [target], pose: pose, width: width) != nil)
        #expect(WorldHitTest.resolve(x: 201 + 90, y: 90, targets: [target], pose: pose, width: width) == nil)
    }

    @Test func thePlateAnswersWithItsObjectsAndResidents() throws {
        let home = try #require(HomePlate.shipped)
        let world = IslandSamples.world(
            clock: nil, tendedDays: 60,
            levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5],
            jar: .zero, islands: [.home], islandLevel: 10
        )
        let targets = WorldHitTest.plateTargets(home, stations: world.stations, z: 2)
        let kinds = Set(targets.map(\.kind))
        for id in ["teaStall", "garden", "windmill", "pond", "door"] {
            #expect(kinds.contains(.plateObject(id)), "\(id)")
        }
        #expect(kinds.contains(.resident(.mochi)))
        #expect(kinds.contains(.resident(.findik)))
        #expect(!kinds.contains { if case .prop = $0 { true } else { false } })
        // On the Archipelago only the islands answer.
        #expect(WorldHitTest.plateTargets(home, stations: world.stations, z: 0.2).allSatisfy {
            if case .island = $0.kind { true } else { false }
        })
    }

    @Test func aTapOnTheTeaStallAtHomeFindsIt() throws {
        let home = try #require(HomePlate.shipped)
        let world = IslandSamples.world(
            clock: nil, tendedDays: 60, levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5],
            jar: .zero, islands: [.home], islandLevel: 10
        )
        let stop = home.homeStop
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let awning = home.world(PlatePoint(x: 0.68 * 1024, y: 0.45 * 1536))
        let p = pose.project(awning, width: CameraRail.referenceWidth)
        let hit = WorldHitTest.resolve(
            x: p.x, y: p.y, targets: WorldHitTest.plateTargets(home, stations: world.stations, z: 2),
            pose: pose, width: CameraRail.referenceWidth
        )
        #expect(hit?.kind == .plateObject("teaStall"))
    }
}

/// Çağlayan, the first island besides Home drawn from its painted plates (ADR-0022): the same
/// `HomePlate`, placed by data, shown only where a plate is painted.
struct CaglayanPlateTests {
    var island: PlateIsland {
        get throws { try #require(HomePlate.caglayanIsland, "the package ships Plates/plate-caglayan.json") }
    }

    func state(_ island: PlateIsland, _ stage: Int, _ hour: Double, _ weather: WeatherConditions = .clear, bed: Bool = false) -> String? {
        HomePlate.caglayanState(in: island, stage: stage, hour: hour, weather: weather, isBedtime: bed).map { "\($0.light)-\($0.stage)" }
    }

    @Test func paintsTheDayOfEveryStageAndTheNightsGoldenAndRainThatExist() throws {
        let island = try island
        #expect(island.painted["day"] == [0, 1, 2, 3, 4])
        #expect(island.painted["night"] == [2, 3])
        #expect(island.painted["golden"] == [4])
        #expect(island.painted["rain"] == [4])
        for stage in 0...4 {
            #expect(state(island, stage, 12) == "day-\(stage)")
        }
        #expect(state(island, 3, 22.5) == "night-3")
        #expect(state(island, 2, 3) == "night-2")
        #expect(state(island, 2, 12, bed: true) == "night-2")
        #expect(state(island, 4, 18) == "golden-4")
        #expect(state(island, 4, 12, WeatherConditions(weather: .lightRain)) == "rain-4")
        #expect(state(island, 4, 12, WeatherConditions(weather: .clear, rainbow: true)) == "day-4")
    }

    @Test func everyOtherStateKeepsTheSpriteIsland() throws {
        let island = try island
        // Not painted: night at stages 0, 1 and 4, golden hour and rain before the island is healed.
        #expect(state(island, 0, 22.5) == nil)
        #expect(state(island, 1, 22.5) == nil)
        #expect(state(island, 4, 22.5) == nil)
        #expect(state(island, 3, 18) == nil)
        #expect(state(island, 3, 12, WeatherConditions(weather: .lightRain)) == nil)
        // Rain at night, the other weathers and the dawn and dusk hours.
        #expect(state(island, 4, 22.5, WeatherConditions(weather: .lightRain)) == nil)
        for weather in [Weather.overcast, .mist, .goldenHaze] {
            #expect(state(island, 4, 12, WeatherConditions(weather: weather)) == nil)
        }
        #expect(state(island, 4, 6.5) == nil)
        #expect(state(island, 4, 19.75) == nil)
    }

    @Test func resolvesFromTheWorldsStageAndTheLooksHour() throws {
        let island = try island
        var world = IslandSamples.world(clock: nil, tendedDays: 60, levels: [:], jar: .zero, islands: [.home], islandLevel: 5)
        var look = WorldLook(hourOverride: 12)
        look.weatherOverride = .clear
        // Not arrived: the sprite path (there is nothing to draw).
        #expect(HomePlate.resolveCaglayan(island, world: world, look: look) == nil)
        world.caglayan = WonderStatus(phase: .arrived, stage: 3)
        let plate = try #require(HomePlate.resolveCaglayan(island, world: world, look: look))
        #expect(plate.light == "day" && plate.stage == 3)
        #expect(plate.placement == CaglayanLayout.placement)
        look.homePlates = false
        #expect(HomePlate.resolveCaglayan(island, world: world, look: look) == nil)
    }

    @Test func theIslandLandsOnItsOwnBoxAtTheStopsScale() throws {
        let plate = HomePlate(plate: try island, placement: CaglayanLayout.placement)
        let box = plate.islandBox
        #expect(abs(box.width - CaglayanLayout.plateSize.width) < 1e-6)
        #expect(abs((box.minX + box.maxX) / 2 - CaglayanLayout.center.x) < 1e-6)
        #expect(abs((box.minY + box.maxY) / 2 - CaglayanLayout.center.y) < 1e-6)
        // Round trip.
        let p = PlatePoint(x: 700, y: 500)
        let back = plate.plate(plate.world(p))
        #expect(abs(back.x - p.x) < 1e-9 && abs(back.y - p.y) < 1e-9)
    }

    @Test func theStopFramesTheIslandAtItsMassHeightWithTheDataTop() throws {
        let island = try island
        let plate = HomePlate(plate: island, placement: CaglayanLayout.placement)
        let stop = try #require(IslandFraming.isleStop(.caglayan, width: 402, height: 874))
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let a = pose.project(WorldPoint(x: plate.islandBox.minX, y: plate.islandBox.minY), width: 402)
        let b = pose.project(WorldPoint(x: plate.islandBox.maxX, y: plate.islandBox.maxY), width: 402)
        // The island is `homeWidths` screens wide, its centre at 54 % of the screen's height, its
        // top where `framing.homeTopY` (the backdrop's frame, `tools/plate/ingest.py`) says.
        #expect(abs((b.x - a.x) / 402 - island.framing.homeWidths) < 0.003)
        #expect(abs((a.y + b.y) / 2 - IslandFraming.massY * 874) < 0.5)
        #expect(abs(a.y - island.framing.homeTopY) < 1.5)
        #expect(a.x > 0 && b.x < 402)
        // Clear of the top button band and the bottom UI.
        #expect(a.y > IslandFraming.topBand && b.y < 874 - IslandFraming.bottomBand)
    }

    @Test func theBackdropCoversTheScreenAtTheStop() throws {
        let plate = HomePlate(plate: try island, placement: CaglayanLayout.placement)
        let stop = try #require(IslandFraming.isleStop(.caglayan, width: 402, height: 874))
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let box = plate.backdropBox
        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: 402)
        let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: 402)
        #expect(a.x <= 0 && a.y <= 0 && b.x >= 402 && b.y >= 874)
        // At a wider phone too (the stop's scale follows the width, the rows the height).
        let wide = try #require(IslandFraming.isleStop(.caglayan, width: 440, height: 956))
        let w = CameraPose(scale: wide.scale, look: wide.look, anchorY: wide.anchorY)
        let c = w.project(WorldPoint(x: box.minX, y: box.minY), width: 440)
        let d = w.project(WorldPoint(x: box.maxX, y: box.maxY), width: 440)
        #expect(c.x <= 0 && c.y <= 0 && d.x >= 440 && d.y >= 956)
    }

    @Test func damlaStandsOnTheLawnAtPofusScaleRule() throws {
        let island = try island
        let plate = HomePlate(plate: island, placement: CaglayanLayout.placement)
        let spot = try #require(island.characters["damla"])
        #expect(PlateMath.contains(island.walkable, spot))
        #expect(island.characters["pofu"] == nil)
        // Pofu's proportion (about a tenth of the island's width), Damla boosted so she reads: her
        // art is 38.3 units wide, drawn between 7 and 11 % of the island's width.
        #expect(abs(plate.characterScale * 64 / plate.islandBox.width - 0.1) < 0.02)
        let width = 38.267 * plate.residentScale(.damla)
        #expect(width / plate.islandBox.width > 0.07 && width / plate.islandBox.width < 0.11)
        #expect(plate.damla(stage: 3)?.art == "damla")
        #expect(plate.damla(stage: 4)?.art == "damla-glass")
    }

    @Test func eachPaintedStateCarriesHarmonyAndTheRootIsTheReference() throws {
        let island = try island
        for (light, stages) in island.painted {
            for stage in stages {
                let h = island.harmony(light: light, stage: stage)
                #expect(h.contact >= 0.5 && h.contact <= 1.2, "\(light) \(stage)")
                #expect(h.tint.red <= 1 && h.tint.green <= 1 && h.tint.blue <= 1)
                #expect(min(h.tint.red, h.tint.green, h.tint.blue) >= 0.25)
                #expect(!island.lightMap[light, default: []][stage].isEmpty, "\(light) \(stage) has its light map")
            }
        }
        // The stage 4 day is the island's own root: its sprites are not tinted.
        #expect(island.harmony(light: "day", stage: 4).tint == PofuRGB(red: 1, green: 1, blue: 1))
        // At night the lantern and the window are the key light.
        #expect(island.lamps.count == 2)
        let night = HomePlate(plate: island, light: "night", stage: 3, placement: CaglayanLayout.placement)
        #expect(night.harmony.rim > 0 && night.harmony.pool > 0)
    }

    @Test func thePlateFadesInWithTheCameraNeverAsARectangleOverTheSky() throws {
        let stop = try #require(IslandFraming.isleStop(.caglayan, width: 402, height: 874))
        let at = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        #expect(HomePlate.caglayanFade(pose: at, viewportWidth: 402) == 1)
        // Zoomed out to the Map, or flying across the sea at the Island scale, it is the island cut alone.
        let map = IslandFraming.mapStop(width: 402, height: 874)
        #expect(HomePlate.caglayanFade(pose: CameraPose(scale: map.scale, look: map.look, anchorY: map.anchorY), viewportWidth: 402) == 0)
        let home = IslandFraming.homeStop(width: 402)
        #expect(HomePlate.caglayanFade(pose: CameraPose(scale: home.scale, look: home.look, anchorY: home.anchorY), viewportWidth: 402) == 0)
        var across = at
        across.lookX += CaglayanLayout.plateSize.width
        #expect(HomePlate.caglayanFade(pose: across, viewportWidth: 402) == 0)
        // A little off centre keeps it whole.
        var near = at
        near.lookX += 4
        #expect(HomePlate.caglayanFade(pose: near, viewportWidth: 402) == 1)
    }

    @Test func budgetFits() throws {
        #expect(PlateMath.budgetOK(try island))
    }
}
