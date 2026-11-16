import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// What the shipped `plate-home.json` paints (docs/design/demo-one-world-v1.md, PR 2): the night
/// and the day of every level from 1, and that the Rehearsal
/// tester's twenty-one days find a painting at every hour the panel lands on.
struct HomePlateDataTests {
    var plate: PlateIsland {
        get throws { try #require(HomePlate.shipped, "the package ships Plates/plate-home.json").plate }
    }

    @Test func paintsTheNightOfEveryLevel() throws {
        let plate = try plate
        #expect(plate.painted["night"] == Array(0...9))
        // The night stage is the level's own: stage s is `stageLevels[s]` for every light.
        #expect(plate.stageLevels == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1])
        for level in 1...10 {
            let stage = try #require(plate.dayStage(islandLevel: level))
            #expect(plate.paints(light: "night", stage: stage), "the night of level \(level)")
        }
    }

    @Test func shadowDecodesForEveryStage() throws {
        let plate = try plate
        #expect(plate.shadows.count == plate.stages)
        for stage in 0..<plate.stages {
            let shadow = try #require(plate.shadow(stage: stage), "stage \(stage)")
            // An ellipse wider than it is tall, under the island, inside the plate's width.
            #expect(shadow.radii.x > shadow.radii.y && shadow.radii.y > 0, "stage \(stage)")
            #expect(shadow.centre.x > 0 && shadow.centre.x < plate.plateSize.maxX, "stage \(stage)")
            #expect(shadow.centre.y > (plate.islandBox.minY + plate.islandBox.maxY) / 2, "stage \(stage)")
            #expect(shadow.opacity > 0 && shadow.opacity <= 1, "stage \(stage)")
        }
        #expect(plate.shadow(stage: plate.stages) == nil)
    }

    /// One sky at every level: every state with its island matte ships its plate cropped to the island and draws
    /// Home's sky set of its light behind it; the states that keep their old matte keep the whole plate and its backdrop.
    @Test func mattedStatesDrawTheirLightsSkyBehindACroppedPlate() throws {
        let plate = try plate
        let legacy: Set<String> = ["night:8", "night:9"]
        for light in plate.lights {
            for stage in 0..<(plate.lightStages[light] ?? 0) {
                let state = HomePlate(plate: plate, light: light, stage: stage)
                if legacy.contains("\(light):\(stage)") {
                    #expect(!state.isMatted, "\(light) \(stage)")
                    #expect(state.skySet == nil, "\(light) \(stage)")
                    #expect(state.plateImageBox == state.plateBox, "\(light) \(stage)")
                    continue
                }
                let crop = try #require(plate.plateCrop(light: light, stage: stage), "\(light) \(stage)")
                #expect(state.isMatted)
                #expect(state.skySet?.light == light, "\(light) \(stage)")
                // The crop lies inside the plate, holds the island's foot and is a band of it, not the whole plate.
                #expect(crop.minX >= 0 && crop.minY >= 0 && crop.maxX <= plate.plateSize.maxX && crop.maxY <= plate.plateSize.maxY)
                #expect(crop.height < plate.plateSize.height * 0.6, "\(light) \(stage)")
                #expect(crop.minY < (plate.islandBox.minY + plate.islandBox.maxY) / 2 && crop.maxY >= plate.islandBox.maxY - 4, "\(light) \(stage)")
                let box = state.plateImageBox, whole = state.plateBox
                #expect(box.minY > whole.minY && box.maxY < whole.maxY, "\(light) \(stage)")
            }
        }
        #expect(PlateMath.budgetOK(plate))
    }

    /// Golden hour below level 10 shows the night plate (`HomePlate.borrowed`) and with it the night sky: a plate and
    /// its sky are always the same light.
    @Test func aBorrowedLightTakesItsOwnSky() throws {
        let plate = try plate
        let stage = try #require(plate.dayStage(islandLevel: 5))
        let golden = try #require(HomePlate.state(in: plate, islandLevel: 5, hour: 18.5, weather: WeatherConditions(), isBedtime: false))
        #expect(HomePlate.light(hour: 18.5, isBedtime: false) == "golden")
        #expect(golden.light == "night" && golden.stage == stage)
        let state = HomePlate(plate: plate, light: golden.light, stage: golden.stage)
        #expect(state.skySet?.light == "night")
        // Level 10 paints its own golden hour, and its sky set is golden.
        let ten = try #require(HomePlate.state(in: plate, islandLevel: 10, hour: 18.5, weather: WeatherConditions(), isBedtime: false))
        #expect(ten.light == "golden")
        #expect(HomePlate(plate: plate, light: ten.light, stage: ten.stage).skySet?.light == "golden")
    }

    @Test func paintsTheDayOfEveryLevelFromOne() throws {
        let plate = try plate
        #expect(plate.painted["day"] == Array(0...9))
        #expect(plate.stageLevels.last == 1)
        #expect(plate.minLevel == 1)
        #expect(plate.dayStage(islandLevel: 1) == 9)
        #expect(plate.dayStage(islandLevel: 0) == nil)
    }

    @Test func lowLevelNightsHaveNoLampPool() throws {
        let plate = try plate
        // The lamps open at level 6 (`HomeFixtures.lampsOpenAtLevel`): below it no lamp is lit, so
        // the night plate gives a character no lamp pool.
        for level in 1...5 {
            let stage = try #require(plate.dayStage(islandLevel: level))
            #expect(plate.harmony(light: "night", stage: stage).pool == 0, "level \(level)")
        }
        for level in 6...10 {
            let stage = try #require(plate.dayStage(islandLevel: level))
            #expect(plate.harmony(light: "night", stage: stage).pool > 0, "level \(level)")
        }
    }

    @Test func aNightPaintsOnlyWhatItsLevelHas() throws {
        let plate = try plate
        // IL2's night: the tea stall and the pond are there, the windmill is not; IL1's day has no
        // tea stall and paints the garden.
        let two = HomePlate(plate: plate, light: "night", stage: 8)
        #expect(two.objects.contains { $0.id == "teaStall" })
        #expect(!two.objects.contains { $0.id == "windmill" })
        let one = HomePlate(plate: plate, light: "day", stage: 9)
        #expect(!one.objects.contains { $0.id == "teaStall" })
        #expect(!one.objects.contains { $0.id == "wheel" })
        #expect(one.objects.contains { $0.id == "garden" })
        #expect(one.objects.contains { $0.id == "door" })
    }

    /// The tester's island level on each of the 21 days (Rehearsal: one resisted reach a day).
    static let testerLevels = [1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7]

    /// The hours the panel and a real evening land on: "Morning" 06:00, "Next day" 09:00, noon,
    /// golden hour 18:00, the gap before night 19:45, and "Night" at bedtime (23:00).
    static let hours: [(hour: Double, bedtime: Bool)] = [(6, false), (9, false), (12, false), (18, false), (19.75, false), (23, true)]

    static let weathers: [WeatherConditions] =
        Weather.allCases.map { WeatherConditions(weather: $0) } + [WeatherConditions(weather: .clear, rainbow: true)]

    @Test func theTestersTwentyOneDaysArePainted() throws {
        let plate = try plate
        for (day, level) in Self.testerLevels.enumerated() {
            for (hour, bedtime) in Self.hours {
                for weather in Self.weathers {
                    let state = HomePlate.state(in: plate, islandLevel: level, hour: hour, weather: weather, isBedtime: bedtime)
                    #expect(state != nil, "day \(day + 1), level \(level), \(hour) h, \(weather.weather), rainbow \(weather.rainbow)")
                }
            }
        }
    }

    @Test func theTestersFirstEveningIsPainted() throws {
        let plate = try plate
        // Day 1's 18:00, 19:45 and 23:00 are the painted night of level 1 (art job A1).
        for (hour, bedtime) in Self.hours where hour >= 18 || bedtime {
            let state = HomePlate.state(in: plate, islandLevel: 1, hour: hour, weather: .clear, isBedtime: bedtime)
            #expect(state != nil, "IL1 at \(hour) h")
        }
        let night = HomePlate(plate: plate, light: "night", stage: 9)
        #expect(night.objects.contains { $0.id == "garden" })
        #expect(!night.objects.contains { $0.id == "teaStall" })
    }

    // MARK: Station looks (WP8, the tea stall first)

    @Test func theTeaStallHasALookForEveryLevelOverAnErasedBase() throws {
        let plate = try plate
        let looks = try #require(plate.stations["teaStall"])
        #expect(plate.version == 2)
        #expect(looks.levels == 5)
        #expect(looks.baseStages.contains(7))
        #expect(looks.box.width > 0 && looks.box.height > 0)
        // level to look 1 to 1, nothing while unbuilt, the last look past the ladder's top
        #expect(looks.lookLevel(stationLevel: 0) == nil)
        #expect((1...5).map { looks.lookLevel(stationLevel: $0) } == [1, 2, 3, 4, 5])
        #expect(looks.lookLevel(stationLevel: 6) == 5)
        for level in 1...5 {
            let name = try #require(plate.lookArt(station: "teaStall", level: level, light: "day", stage: 7))
            #expect(name == "world-home-look-teaStall-\(level)-day")
        }
    }

    @Test func theLookStandsWhereEachStagePaintsItsStallAndScalesAboutTheFoot() throws {
        let plate = try plate
        let looks = try #require(plate.stations["teaStall"])
        #expect(looks.baseStages == [3, 4, 6, 7])
        for stage in looks.baseStages {
            let place = looks.place(stage: stage)
            // the foot is inside its canvas, near the bottom, and the canvas is the reference one scaled about the foot
            #expect(place.box.minX < place.foot.x && place.foot.x < place.box.maxX)
            #expect(place.box.maxY > place.foot.y && place.foot.y > place.box.minY)
            let k = place.box.width / looks.box.width
            #expect(k > 0.8 && k < 1.3)
            #expect(abs(place.box.height / looks.box.height - k) < 0.01)
            #expect(plate.drawnPlateArt(light: "day", stage: stage) == "world-home-base-day-\(stage)")
            #expect(plate.lookArt(station: "teaStall", level: 3, light: "day", stage: stage) == "world-home-look-teaStall-3-day")
        }
        // a stage that keeps its painted stall has no base and no look
        for stage in [0, 1, 2, 5, 8, 9] {
            #expect(plate.lookArt(station: "teaStall", level: 3, light: "day", stage: stage) == nil)
        }
        #expect(looks.place(stage: 7).foot == looks.foot)
    }

    @Test func aStateWithoutABaseKeepsItsPaintedStall() throws {
        let plate = try plate
        #expect(plate.lookArt(station: "teaStall", level: 3, light: "night", stage: 7) == nil)
        #expect(plate.lookArt(station: "teaStall", level: 3, light: "day", stage: 0) == nil)
        #expect(plate.drawnPlateArt(light: "day", stage: 0) == plate.plateArt(light: "day", stage: 0))
        #expect(plate.drawnPlateArt(light: "day", stage: 7) == "world-home-base-day-7")
        // the painting other surfaces show is still the painted plate
        #expect(plate.plateArt(light: "day", stage: 7) == "world-home-plate-day-7")
    }

    @Test func theLooksAndTheBaseAreShippedAndWithinTheBudget() throws {
        let plate = try plate
        #expect(PlateMath.budgetOK(plate))
        let assets = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        let fm = FileManager.default
        var names = ["world-home-base-day-7"]
        names += (1...5).map { "world-home-look-teaStall-\($0)-day" }
        for name in names {
            #expect(fm.fileExists(atPath: assets.appendingPathComponent("\(name).imageset/Contents.json").path), "\(name)")
        }
    }

    @Test func version1StillDecodesWithoutStations() throws {
        let json = #"{"island":"t","plateSize":[100,200],"lights":["day"],"islandBox":[0,0,100,200],"objects":[]}"#
        let island = try PlateIsland.decode(Data(json.utf8))
        #expect(island.version == 1)
        #expect(island.stations.isEmpty)
        #expect(island.drawnPlateArt(light: "day", stage: 0) == island.plateArt(light: "day", stage: 0))
    }
}
