import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The Gezgin moored at Home's pier (ADR-0028, plan row 2b): her data, her level, when she is a shadow and
/// when she is moored, her small motions and her tap box.
struct GezginTests {
    var data: GezginData {
        get throws { try #require(GezginData.shipped, "world-map.json carries `gezgin`") }
    }

    private func status(_ phase: WonderStatus.Phase, stage: Int = 0) -> WonderStatus {
        WonderStatus(phase: phase, stage: stage)
    }

    // MARK: Presence and level

    @Test func isAbsentUntilKokeIsOnTheHorizonThenAShadowThenMoored() throws {
        let data = try data
        let none = WonderStatus()
        #expect(Gezgin.presence(koke: none, caglayan: none, data: data) == .absent)
        #expect(Gezgin.presence(koke: status(.rumoured), caglayan: none, data: data) == .shadow)
        #expect(Gezgin.presence(koke: status(.arrived), caglayan: none, data: data) == .moored(level: 1))
    }

    @Test func herLevelFollowsTheHealedIslands() throws {
        let data = try data
        let healed = WonderIslands.healedStage
        #expect(Gezgin.level(koke: status(.arrived, stage: healed - 1), caglayan: status(.arrived), data: data) == 1)
        #expect(Gezgin.level(koke: status(.arrived, stage: healed), caglayan: status(.hidden), data: data) == 2)
        #expect(Gezgin.level(koke: status(.arrived, stage: healed), caglayan: status(.arrived, stage: healed), data: data) == 3)
        // The first main island alone does not skip her a level: level 3 needs the data's island healed.
        #expect(Gezgin.level(koke: status(.arrived), caglayan: status(.arrived, stage: healed), data: data) == 3)
        #expect(Gezgin.presence(koke: status(.arrived, stage: healed), caglayan: status(.hidden), data: data) == .moored(level: 2))
    }

    @Test func herLevelIsDataAndNeverAboveTheArt() throws {
        let data = try data
        #expect(data.levelAt == ["2": "koke", "3": "caglayan"])
        #expect(Gezgin.maxLevel == 3)
        #expect(Gezgin.art(level: 9, "awake") == "world-gezgin-l3-awake")
        #expect(Gezgin.art(level: 0, "tail") == "world-gezgin-l1-tail")
    }

    // MARK: Pose and motion

    @Test func sleepsInTheNightPlateAndATapWakesHerForAWhile() throws {
        let data = try data
        #expect(Gezgin.pose(light: "day", wakeAge: nil, data: data) == .awake)
        #expect(Gezgin.pose(light: "golden", wakeAge: nil, data: data) == .awake)
        #expect(Gezgin.pose(light: "night", wakeAge: nil, data: data) == .asleep)
        #expect(Gezgin.pose(light: "night", wakeAge: 0.1, data: data) == .awake)
        #expect(Gezgin.pose(light: "night", wakeAge: data.awakeSeconds - 0.1, data: data) == .awake)
        #expect(Gezgin.pose(light: "night", wakeAge: data.awakeSeconds + 0.1, data: data) == .asleep)
    }

    @Test func herMotionIsSmallAndStillInAStillFrame() throws {
        let data = try data
        #expect(Gezgin.bob(time: 0, data: data) == 0)
        #expect(Gezgin.swayDegrees(time: 0, data: data) == 0)
        for i in 1...200 {
            let t = Double(i) * 0.1
            #expect(abs(Gezgin.bob(time: t, data: data)) <= data.bob.plate + 1e-9)
            // Her tail is a piece over the painted tail: a small angle keeps the painted one from showing.
            #expect(abs(Gezgin.swayDegrees(time: t, data: data)) <= 1.5)
        }
        #expect(Gezgin.blinking(time: 0.05, data: data))
        #expect(!Gezgin.blinking(time: 1, data: data))
    }

    @Test func theAnswerToATapStretchesAndSettles() {
        #expect(Gezgin.answer(age: nil) == (1, 0))
        #expect(Gezgin.answer(age: 5) == (1, 0))
        let peak = Gezgin.answer(age: 0.15)
        #expect(peak.squash > 1 && peak.lift > 0)
        #expect(Gezgin.answer(age: 0.3).lift == 0)
        for i in 0..<90 {
            let a = Gezgin.answer(age: Double(i) / 100)
            #expect(a.squash > 0.9 && a.squash < 1.1)
        }
    }

    @Test func herShadowCrossesTheWholeCloudAndHoldsInASightInAStillFrame() throws {
        let data = try data
        let mooring = try #require(HomePlate.shipped?.plate.mooring)
        let width = 1024.0
        let still = Gezgin.shadowCentre(time: 0, data: data, mooring: mooring, plateWidth: width)
        #expect(still.x > 0 && still.x < width, "a held frame shows it")
        let start = Gezgin.shadowCentre(time: 0.001, data: data, mooring: mooring, plateWidth: width)
        let end = Gezgin.shadowCentre(time: data.shadow.seconds - 0.001, data: data, mooring: mooring, plateWidth: width)
        #expect(start.x < -mooring.width / 2 && end.x > width + mooring.width / 2, "it enters and leaves off the plate")
        #expect(start.y == data.shadow.y)
    }

    @Test func theLinesHaveKeysAndTheNightOneIsForSleep() {
        #expect(Gezgin.lineKey(asleep: true, taps: 4) == "gezgin.line.night")
        let day = Set((0..<9).map { Gezgin.lineKey(asleep: false, taps: $0) })
        #expect(day == ["gezgin.line.0", "gezgin.line.1", "gezgin.line.2"])
        #expect(Gezgin.dayLines == 3)
    }

    // MARK: Place and taps

    @Test func homeMoorsHerBesideTheIslandInsideThePlate() throws {
        let plate = try #require(HomePlate.shipped).plate
        let mooring = try #require(plate.mooring)
        #expect(mooring.feet.x > (plate.islandBox.minX + plate.islandBox.maxX) / 2 && mooring.feet.x < plate.plateSize.maxX)
        #expect(mooring.feet.y > plate.islandBox.minY && mooring.feet.y < plate.plateSize.maxY)
        // Her body is well over Pofu's width and well under the island's.
        #expect(mooring.width > plate.pofuWidth * 2 && mooring.width < (plate.islandBox.maxX - plate.islandBox.minX) / 3)
        let box = Gezgin.tapBox(mooring)
        #expect(box.minX >= 0 && box.maxX <= plate.plateSize.maxX + mooring.width)
    }

    @Test func aTapOnHerBodyResolvesToHerOnlyWhileSheIsMoored() throws {
        let home = try #require(HomePlate.shipped)
        let plate = HomePlate(plate: home.plate, light: "day", stage: 0)
        let mooring = try #require(plate.plate.mooring)
        func has(_ presence: GezginPresence) -> Bool {
            WorldHitTest.plateTargets(plate, stations: [], z: 1, gezgin: presence).contains { $0.kind == .gezgin }
        }
        #expect(has(.moored(level: 1)))
        #expect(!has(.shadow))
        #expect(!has(.absent))
        let target = try #require(WorldHitTest.plateTargets(plate, stations: [], z: 1, gezgin: .moored(level: 2)).first { $0.kind == .gezgin })
        let feet = plate.world(mooring.feet)
        #expect(target.worldBox.minX < feet.x && target.worldBox.maxX > feet.x && target.worldBox.maxY >= feet.y)
        // On the Map only the islands answer.
        #expect(!WorldHitTest.plateTargets(plate, stations: [], z: 0, gezgin: .moored(level: 1)).contains { $0.kind == .gezgin })
    }

    // MARK: Art

    @Test func everyLevelShipsItsCutOutsTailAndShadow() throws {
        let assets = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        for level in 1...Gezgin.maxLevel {
            for part in ["awake", "asleep", "tail", "shadow"] {
                let name = Gezgin.art(level: level, part)
                let png = assets.appendingPathComponent("\(name).imageset/\(name).png")
                #expect(FileManager.default.fileExists(atPath: png.path), "\(name)")
            }
        }
    }

    @Test func theSkySetNoLongerPaintsAWhale() throws {
        let plate = try #require(HomePlate.shipped).plate
        for light in ["day", "golden", "night"] {
            let set = try #require(SkySet.shipped(island: plate.island, light: light, stage: 0), "\(light)")
            #expect(!set.layers.contains { $0.id == "whale" }, "\(light)")
        }
    }
}
