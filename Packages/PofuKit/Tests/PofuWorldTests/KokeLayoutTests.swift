import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Koke")
struct KokeLayoutTests {
    @Test func theColourIsPaintedIntoEveryPlateSoTheGradeLeavesIt() {
        #expect((0..<5).map { KokeLayout.saturation(stage: $0) } == [1.0, 1.0, 1.0, 1.0, 1.0])
        #expect(KokeLayout.saturation(stage: 9) == 1.0)
        #expect(KokeLayout.saturation(stage: -3) == 1.0)
        var grade = WorldGrade.neutral
        grade.saturation = 1
        #expect(KokeLayout.graded(grade, stage: 4).saturation == 1.0)
    }

    @Test func everyStageDrawsItsOwnPaintedPlate() {
        #expect((0...4).map { KokeLayout.plateArt(stage: $0) } == (0...4).map { "world-koke-island-\($0)" })
        #expect(KokeLayout.plateArt(stage: 9) == "world-koke-island-4")
    }

    @Test func onlyStandingStillFallsBackToTheOneEyedPose() {
        #expect(KokeLayout.Pose.standing.fallback == .oneEye)
        #expect([KokeLayout.Pose.asleep, .oneEye, .stretch].allSatisfy { $0.fallback == nil })
    }

    @Test func theBounceIsGentleStageFourOnlyAndStillWithoutATime() {
        #expect(KokeLayout.bounce(stage: 4, time: nil) == 0)
        #expect(KokeLayout.bounce(stage: 3, time: 0.6) == 0)
        #expect(KokeLayout.bounce(stage: 4, time: 0) == 0)
        let peak = KokeLayout.bounce(stage: 4, time: KokeLayout.bouncePeriod / 2)
        #expect(abs(peak - KokeLayout.bounceHeight) < 1e-9)
        #expect((0..<50).allSatisfy { 0...KokeLayout.bounceHeight ~= KokeLayout.bounce(stage: 4, time: Double($0) * 0.37) })
    }

    @Test func theFirstWarmLightComesAtStageTwo() {
        #expect(!KokeLayout.hasWarmLight(stage: 1))
        #expect(KokeLayout.hasWarmLight(stage: 2))
    }

    @Test func theArtSwapsInByName() {
        #expect(KokeLayout.islandArt(stage: 3) == "world-koke-island-3")
        #expect(KokeLayout.pose(stage: 0).art == "world-koke-asleep")
        #expect(KokeLayout.pose(stage: 2).art == "world-koke-one-eye")
        #expect(KokeLayout.pose(stage: 3).art == "world-koke-stretch")
        #expect(KokeLayout.pose(stage: 4).art == "world-koke-standing")
    }

    @Test func theDuoSpeaksAndTheLastStageIsWordless() {
        #expect(KokeLayout.speaker(stage: 3) == .mochi)
        #expect(KokeLayout.speaker(stage: 4) == .koke)
        #expect(KokeLine(id: 1, kind: .rumour).speaker == .pofu)
    }

    @Test func everyLineHasTurkishAndEnglishInTheCatalog() throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/Localizable.xcstrings")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: path))
        let strings = try #require((object as? [String: Any])?["strings"] as? [String: Any])
        var kinds: [KokeLineKind] = (0..<5).map { .stage($0) }
        kinds += [.rumour, .rest]
        for key in kinds.map(KokeLayout.lineKey) + ["koke.name", "koke.speaker.pofu", "koke.speaker.mochi", "koke.gift"] {
            let entry = try #require(strings[key] as? [String: Any], "missing \(key)")
            let localizations = try #require(entry["localizations"] as? [String: Any])
            #expect(localizations["tr"] != nil && localizations["en"] != nil, "\(key) needs tr and en")
        }
    }

    @Test func theSwellIsHalfTheLevelUpBurstAndEnds() throws {
        let peak = try #require(KokeLayout.swell(age: BuildMoment.Ceremony.burstLength * BuildMoment.Ceremony.burstPeak))
        #expect(peak.opacity <= BuildMoment.Ceremony.burstOpacity * 0.5 + 1e-9)
        #expect(peak.opacity > 0.1)
        #expect(KokeLayout.swell(age: BuildMoment.Ceremony.burstLength + 0.01) == nil)
        #expect(KokeLayout.swell(age: -0.1) == nil)
        #expect(KokeLayout.swell(age: 0.3, reduceMotion: true) == nil)
    }

    @Test func theHumpShowsOnlyFromTheIslandStop() {
        #expect(KokeLayout.farOpacity(z: 0) == 0)
        #expect(KokeLayout.farOpacity(z: 1) == 1)
        #expect(KokeLayout.farOpacity(z: 2) == 1)
        #expect(KokeLayout.farOpacity(z: .nan) == 0)
    }

    @Test func kokeStaysInsideTheMapsFrame() {
        let map = IslandFraming.mapStop(width: 402, height: 874)
        let box = KokeLayout.islandBox
        let half = 402 / 2 / map.scale
        #expect(box.minX >= map.look.x - half && box.maxX <= map.look.x + half)
        let half_h = 874.0 / 2 / map.scale
        #expect(box.minY >= map.look.y - half_h && box.maxY <= map.look.y + half_h)
        // And clear of the home plate.
        #expect(box.minY > IslandFraming.plateBox.maxY || box.maxX < IslandFraming.plateBox.minX)
    }

    @Test func itsIslandStopCentresOnIt() throws {
        let stop = try #require(IslandFraming.isleStop(.koke, width: 402, height: 874))
        #expect(abs(stop.look.x - KokeLayout.islandBox.midX) < 1e-9)
        #expect(stop.scale == KokeLayout.closeScale)
    }

    @Test func theHomeIslandIsAboveTheKokeFrame() throws {
        for (width, height) in [(402.0, 874.0), (440.0, 956.0), (375.0, 812.0)] {
            let stop = try #require(IslandFraming.isleStop(.koke, width: width, height: height))
            let homeBottom = stop.anchorY + (IslandFraming.plateBox.maxY - stop.look.y) * stop.scale
            #expect(homeBottom <= 0, "home hangs into the \(width) x \(height) frame")
        }
    }

    @Test func theFocusPlaneIsKokesLawn() {
        #expect(KokeLayout.focusDepth == IslandLayout.depth(ofY: KokeLayout.center.y))
        #expect(KokeLayout.focusDepth > IslandLayout.depth(ofY: IslandLayout.pofu.y))
    }

    @Test func onlyAnArrivedKokeAnswersTaps() {
        let hidden = WorldHitTest.targets(stations: [], z: 0)
        #expect(!hidden.contains { $0.kind == .island(.koke) })
        let reachable = WorldHitTest.targets(stations: [], z: 0, koke: .arrived)
        #expect(reachable.contains { $0.kind == .island(.koke) })
        let there = WorldHitTest.targets(stations: [], z: 1, koke: .onIsland)
        #expect(there.contains { $0.kind == .koke })
        #expect(!WorldHitTest.targets(stations: [], z: 1).contains { $0.kind == .koke })
    }

    @Test func theCameraPlaceIsOnItsOwnIsland() {
        #expect(CameraPlace.koke.island == .koke)
        #expect(CameraPlace.koke.stop == .island)
    }
}
