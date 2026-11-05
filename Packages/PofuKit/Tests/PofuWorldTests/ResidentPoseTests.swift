import PofuCore
import Testing
@testable import PofuWorld

@Suite("Resident poses")
struct ResidentPoseTests {
    @Test func everyBakedPoseNamesItsBaseArt() throws {
        let mochi = try #require(IslandLayout.resident(.mochi))
        #expect(mochi.art(for: .rest) == "mochi")
        #expect(mochi.art(for: .work) == "mochi-work")
        #expect(mochi.art(for: .surprised) == "mochi-surprised")
        #expect(mochi.art(for: .eyesHappy) == "mochi-eyes-happy")
        #expect(mochi.art(for: .eyesClosed) == "mochi-eyes-closed")
        let findik = try #require(IslandLayout.resident(.findik))
        #expect(findik.art(for: .work) == "findik-work")
        #expect(findik.art(for: .eyesClosed) == "findik-eyes-closed")
        #expect(findik.art(for: .eyesHappy) == "findik-eyes-happy")
    }

    @Test func aPoseWithoutArtFallsBackToTheBase() throws {
        // Fındık has no surprised pose yet.
        let findik = try #require(IslandLayout.resident(.findik))
        #expect(findik.art(for: .surprised) == "findik")
    }

    @Test func poseSpritesShareTheBaseRegistration() throws {
        for resident in IslandLayout.residents {
            let base = try #require(WorldArt.sprite(resident.art)?.sharp)
            for pose in ResidentPose.allCases {
                let art = resident.art(for: pose)
                let box = try #require(WorldArt.sprite(art)?.sharp)
                // Same canvas and feet: a pose swaps in place, give or take the paws and ears.
                #expect(abs(box.width - base.width) < 3, "\(art) width")
                #expect(abs(box.maxY - base.maxY) < 1, "\(art) feet")
            }
        }
    }

    @Test func residentsSleepAtBedtimeAndWorkUnderTheCamera() throws {
        let mochi = try #require(IslandLayout.resident(.mochi))
        #expect(mochi.idlePose(isBedtime: false, isFocused: false) == .rest)
        #expect(mochi.idlePose(isBedtime: false, isFocused: true) == .work)
        #expect(mochi.idlePose(isBedtime: true, isFocused: true) == .eyesClosed)
    }

    @Test func aBuildStartlesTheResidentThenCheersThem() {
        let moment = BuildMoment(station: .teaStall, fromLevel: 1, toLevel: 2, maxLevel: 5, reduceMotion: false)
        #expect(moment.residentPose(at: 0.1) == nil)
        #expect(moment.residentPose(at: 0.5) == .surprised)
        #expect(moment.residentPose(at: 0.9) == .eyesHappy)
        #expect(moment.residentPose(at: 2.5) == nil)
        let still = BuildMoment(station: .teaStall, fromLevel: 1, toLevel: 2, maxLevel: 5, reduceMotion: true)
        #expect(still.residentPose(at: 0.5) == nil)
    }
}
