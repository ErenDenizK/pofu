import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Çağlayan")
struct CaglayanLayoutTests {
    @Test func everyStageDrawsItsOwnPlateAndDamlaFillsHerGlassAtTheEnd() {
        #expect((0...4).map { CaglayanLayout.islandArt(stage: $0) } == (0...4).map { "world-caglayan-island-\($0)" })
        #expect(CaglayanLayout.islandArt(stage: 9) == "world-caglayan-island-4")
        #expect((0...3).allSatisfy { CaglayanLayout.damlaArt(stage: $0) == "world-damla" })
        #expect(CaglayanLayout.damlaArt(stage: 4) == "world-damla-glass")
        // Healed, she sits at the top of the falls instead of by the pool.
        #expect(CaglayanLayout.damlaPoint(stage: 4).y < CaglayanLayout.damlaPoint(stage: 3).y)
    }

    @Test func theIslandSitsClearOfHomeKokeAndTheHarborsWater() {
        let box = CaglayanLayout.islandBox
        #expect(box.minY > IslandFraming.plateBox.maxY)
        #expect(box.minX > KokeLayout.islandBox.maxX)
        #expect(abs(box.width - CaglayanLayout.plateSize.width) < 1e-9)
    }

    @Test func theBakedPlateIsAboutTheSizeOfTheLayoutBox() throws {
        let sprite = try #require(WorldArt.sprite(CaglayanLayout.islandKey(stage: 4))?.sharp)
        #expect(abs(sprite.width - CaglayanLayout.plateSize.width) < 4)
        #expect(abs(sprite.height - CaglayanLayout.plateSize.height) < 10)
    }

    @Test func theShaftFadesAsTheWaterReturnsAndThePoolLightOnlyShinesAtNight() {
        #expect((0...4).map { CaglayanLayout.shaftAlpha(stage: $0) } == [0.5, 0.32, 0.16, 0, 0])
        #expect(CaglayanLayout.poolLight(stage: 0, night: 0) == 0)
        #expect(CaglayanLayout.poolLight(stage: 0, night: 1) == 1)
        #expect(CaglayanLayout.poolLight(stage: 3, night: 1) < CaglayanLayout.poolLight(stage: 1, night: 1))
        #expect(CaglayanLayout.poolLight(stage: 4, night: 1) == 0)
        #expect(CaglayanLayout.poolLight(stage: 0, night: .nan) == 0)
    }

    @Test func theNoteInTheMillHutShowsFromStageTwo() {
        #expect((0...4).map { CaglayanLayout.showsNote(stage: $0) } == [false, false, true, true, true])
    }

    @Test func onlyTheHealedIslandPoursAndASettledFrameDoesNotMove() {
        #expect((0...4).map { CaglayanLayout.fallStrength(stage: $0) } == [0, 0, 0, 0, 1])
        for ribbon in CaglayanLayout.ribbons {
            #expect(CaglayanLayout.fallPhase(ribbon, time: nil) == 0)
            #expect((0..<40).allSatisfy { 0..<1 ~= CaglayanLayout.fallPhase(ribbon, time: Double($0) * 0.173) })
            // Left the body at its lowest line, falling a good way down.
            #expect(ribbon.length > 60)
        }
        #expect(CaglayanLayout.undersideY < CaglayanLayout.plateSize.height)
    }

    @Test func theLinesFollowTheStoryMap() {
        // Damla greets, Pofu lays the stones and finds the note, Mochi reads the wall at the turn, Damla slides down.
        #expect((0...4).map { CaglayanLayout.speaker(stage: $0) } == [.damla, .pofu, .pofu, .mochi, .damla])
        #expect(CaglayanLayout.lineKey(.stage(3)) == "caglayan.line.3")
        #expect(CaglayanLayout.lineKey(.rumour) == "caglayan.rumour")
        #expect(CaglayanLine(id: 1, kind: .rest).speaker == .damla)
        #expect(CaglayanLine(id: 1, kind: .rumour).speaker == .pofu)
    }

    @Test func nightLineKey() {
        #expect(CaglayanLayout.lineKey(.night) == "caglayan.night")
        #expect(CaglayanLine(id: 1, kind: .night).speaker == .damla)
    }

    @Test func tappingTheIslandOnItsOwnAnswersWithTheFlowTarget() {
        let targets = WorldHitTest.islandTargets(koke: false, caglayan: true)
        #expect(targets.contains { $0.kind == .island(.caglayan) })
        #expect(!WorldHitTest.islandTargets().contains { $0.kind == .island(.caglayan) })
        #expect(WorldHitTest.targets(stations: [], z: 0, caglayan: .arrived).contains { $0.kind == .island(.caglayan) })
    }

    @Test func theMapAndTheCameraStopTakeTheIslandIn() throws {
        let stop = try #require(IslandFraming.isleStop(.caglayan, width: 402, height: 874))
        #expect(abs(stop.look.x - CaglayanLayout.islandBox.midX) < 1e-9)
        let map = IslandFraming.mapStop(width: 402, height: 874)
        #expect(map.scale > 0)
        #expect(CameraPlace.caglayan.island == .caglayan)
    }
}
