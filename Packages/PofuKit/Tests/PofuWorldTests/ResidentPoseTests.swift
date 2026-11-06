import Foundation
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

    @Test func theReactionPosesAreBakedForBothResidents() throws {
        for id in [ResidentID.mochi, .findik] {
            let resident = try #require(IslandLayout.resident(id))
            let name = resident.art
            #expect(resident.art(for: .happy) == "\(name)-happy")
            #expect(resident.art(for: .sleepy) == "\(name)-sleepy")
            #expect(resident.art(for: .proud) == "\(name)-proud")
        }
        let findik = try #require(IslandLayout.resident(.findik))
        #expect(findik.art(for: .surprised) == "findik-surprised")
    }

    @Test func aReactionWithoutArtFallsBackToTheOlderPoseThenTheBase() {
        #expect(ResidentPose.happy.fallbacks == [.happy, .eyesHappy])
        #expect(ResidentPose.sleepy.fallbacks == [.sleepy, .eyesClosed])
        #expect(ResidentPose.proud.fallbacks == [.proud])
    }

    @Test func poseSpritesShareTheBaseRegistration() throws {
        for resident in IslandLayout.residents {
            let base = try #require(WorldArt.sprite(resident.art)?.sharp)
            for pose in ResidentPose.allCases {
                let art = resident.art(for: pose)
                let box = try #require(WorldArt.sprite(art)?.sharp)
                // Same canvas and feet: a pose swaps in place, give or take the paws and ears.
                // The reactions lift an arm or fold the ears, so their width gives a little more.
                #expect(abs(box.width - base.width) < base.width * 0.2, "\(art) width")
                #expect(abs(box.maxY - base.maxY) < 1, "\(art) feet")
            }
        }
    }

    @Test func residentsSleepAtBedtimeAndWorkUnderTheCamera() throws {
        let mochi = try #require(IslandLayout.resident(.mochi))
        #expect(mochi.idlePose(isBedtime: false, isFocused: false) == .rest)
        #expect(mochi.idlePose(isBedtime: false, isFocused: true) == .work)
        #expect(mochi.idlePose(isBedtime: true, isFocused: true) == .sleepy)
    }

    // MARK: Mood to pose

    @Test func eachEventAsksForItsPose() {
        #expect(ResidentEvent.stationLevelledUp.pose == .happy)
        #expect(ResidentEvent.visitorArrived.pose == .happy)
        #expect(ResidentEvent.ceremonyDone.pose == .proud)
        #expect(ResidentEvent.firstTapOfDay.pose == .surprised)
        #expect([ResidentEvent.stationLevelledUp, .visitorArrived, .ceremonyDone, .firstTapOfDay].allSatisfy { $0.seconds > 0 })
    }

    @Test func anEventBeatsBedtimeAndFocus() throws {
        let mochi = try #require(IslandLayout.resident(.mochi))
        #expect(mochi.idlePose(isBedtime: true, isFocused: false, event: .visitorArrived) == .happy)
        #expect(mochi.idlePose(isBedtime: false, isFocused: true, event: .ceremonyDone) == .proud)
        #expect(mochi.idlePose(isBedtime: true, isFocused: true, event: .firstTapOfDay) == .surprised)
        #expect(mochi.idlePose(isBedtime: true, isFocused: false, event: nil) == .sleepy)
    }

    @Test func aReactionLapsesByItself() {
        var reactions = ResidentReactions()
        let now = Date(timeIntervalSinceReferenceDate: 1000)
        reactions.add(.ceremonyDone, for: ["mochi"], at: now)
        #expect(reactions.event(of: "mochi", at: now.addingTimeInterval(1)) == .ceremonyDone)
        #expect(reactions.event(of: "mochi", at: now.addingTimeInterval(ResidentEvent.ceremonyDone.seconds + 0.1)) == nil)
        #expect(reactions.event(of: "findik", at: now) == nil)
        reactions.add(.visitorArrived, for: ["mochi"], at: now.addingTimeInterval(2))
        #expect(reactions.event(of: "mochi", at: now.addingTimeInterval(3)) == .visitorArrived)
    }

    @Test func onlyTheFirstTapOfTheDaySurprises() {
        var reactions = ResidentReactions()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let morning = Date(timeIntervalSince1970: 1_800_000_000)
        let first = reactions.noteTap(on: "mochi", at: morning, calendar: calendar)
        #expect(first)
        #expect(reactions.event(of: "mochi", at: morning) == .firstTapOfDay)
        let second = reactions.noteTap(on: "findik", at: morning.addingTimeInterval(60), calendar: calendar)
        #expect(!second)
        #expect(reactions.event(of: "findik", at: morning.addingTimeInterval(60)) == nil)
        let nextDay = reactions.noteTap(on: "findik", at: morning.addingTimeInterval(86_400), calendar: calendar)
        #expect(nextDay)
    }

    @Test func aCeremonyShowsOnItsStationsCast() {
        #expect(ResidentReactions.cast(of: .teaStall) == ["mochi"])
        #expect(ResidentReactions.cast(of: .bagelCart).contains("simit"))
        #expect(ResidentReactions.cast(of: .pier) == ["goat"])
        #expect(ResidentReactions.cast(of: .pond).isEmpty)
        #expect(Set(ResidentReactions.everyone) == ["mochi", "findik", "simit", "goat"])
    }

    @Test func aBuildStartlesTheResidentThenCheersThem() {
        let moment = BuildMoment(station: .teaStall, fromLevel: 1, toLevel: 2, maxLevel: 5, reduceMotion: false)
        #expect(moment.residentPose(at: 0.1) == nil)
        #expect(moment.residentPose(at: 0.5) == .surprised)
        #expect(moment.residentPose(at: 0.9) == .happy)
        #expect(moment.residentPose(at: 2.5) == nil)
        let still = BuildMoment(station: .teaStall, fromLevel: 1, toLevel: 2, maxLevel: 5, reduceMotion: true)
        #expect(still.residentPose(at: 0.5) == nil)
    }
}
