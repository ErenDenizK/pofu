import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// Records what the visit asked of the camera: the island's news.
@MainActor
final class NewsSpy: WorldCamera {
    var spoken = 0

    func beginBuildFraming(_ station: StationID) {}
    func endBuildFraming(_ station: StationID) {}

    func newsHasSpoken() {
        spoken += 1
    }
}

@Suite("Island grow moment")
struct IslandGrowMomentTests {
    let moment = IslandGrowMoment(fromLevel: 3, toLevel: 4, reduceMotion: false)

    @Test func theCuesPlayInOrderAtTheBriefsTimes() {
        let cues = moment.cues(after: -1, through: moment.duration)
        #expect(cues == [.pullBack, .bloom, .crossFade, .card, .end])
        #expect(cues.map { moment.time(of: $0) } == [0, 0.6, 0.9, 1.7, 4.6])
        // Each cue plays once: a later window never repeats an earlier cue.
        #expect(moment.cues(after: 0, through: 0.9) == [.bloom, .crossFade])
        #expect(moment.cues(after: 0.9, through: 4.6) == [.card, .end])
    }

    @Test func theOldPaintingStaysUntilTheCrossFadeBegins() {
        #expect(moment.presentedLevel(at: 0) == 3)
        #expect(moment.presentedLevel(at: 0.89) == 3)
        #expect(moment.presentedLevel(at: IslandGrowMoment.crossFadeAt) == 4)
        #expect(moment.presentedLevel(at: moment.duration) == 4)
        // The cross-fade is the plate layer's own 0.8 s, in full view (0.9 to 1.7).
        #expect(moment.newPainting(at: 0.9) == 0)
        #expect(moment.newPainting(at: 1.3) > 0.4 && moment.newPainting(at: 1.3) < 0.6)
        #expect(moment.newPainting(at: 1.7) == 1)
    }

    @Test func thePresentedLevelNeverRunsAheadOfTheTrueOneAndEndsEqual() {
        var stage = IslandLevelStage(presented: 3)
        // The world is at 4 from the build's commit: the painting trails it.
        #expect(stage.shown(worldLevel: 4) == 3)
        #expect(stage.lags(behind: 4))
        var t = 0.0
        while t <= moment.duration {
            stage.present(moment.presentedLevel(at: t))
            #expect(stage.shown(worldLevel: 4) <= 4)
            #expect(stage.shown(worldLevel: 3) <= 3, "a world that has not risen is never outrun")
            t += 0.05
        }
        #expect(stage.shown(worldLevel: 4) == 4)
        #expect(!stage.lags(behind: 4))
        // A level that falls (a reset) shows at once; a first launch follows the world.
        #expect(stage.shown(worldLevel: 2) == 2)
        #expect(IslandLevelStage().shown(worldLevel: 6) == 6)
    }

    @Test func theBloomRisesFromTheSoundsCueAndFadesBeforeTheCardLeaves() {
        #expect(moment.bloom(at: 0.59) == 0)
        #expect(moment.bloom(at: 1.1) > 0.99)
        #expect(moment.bloom(at: 1.4) > 0.5)
        #expect(moment.bloom(at: 2.3) < 0.001)
    }

    @Test func theCardRisesAtTheCueAndLeavesAtTheEndOrOnATap() throws {
        #expect(moment.card(at: 1.69) == nil)
        let rising = try #require(moment.card(at: 1.72))
        #expect(rising.opacity < 0.5 && rising.rise > 0.5)
        let settled = try #require(moment.card(at: 2.4))
        #expect(settled.opacity == 1 && settled.rise == 0)
        let leaving = try #require(moment.card(at: 4.4))
        #expect(leaving.opacity < 0.6)
        #expect(moment.card(at: 4.6) == nil)
        // A tap at 3.0 s sends it away within 0.4 s.
        #expect(moment.card(at: 3.1, leavesAt: 3.4) != nil)
        #expect(moment.card(at: 3.4, leavesAt: 3.4) == nil)
    }

    @Test func reduceMotionHasNoCameraCueAndNoBloomButTheCrossFadeAndTheCard() {
        let calm = IslandGrowMoment(fromLevel: 3, toLevel: 4, reduceMotion: true)
        #expect(calm.time(of: .pullBack) == nil)
        #expect(calm.cues(after: -1, through: calm.duration) == [.bloom, .crossFade, .card, .end])
        #expect(calm.bloom(at: 1.3) == 0)
        #expect(calm.presentedLevel(at: 1.0) == 4)
        #expect(calm.card(at: 2.4)?.rise == 0, "the card fades in without travelling")
    }

    @Test func lowPowerDrawsNoBloomButKeepsTheCues() {
        let low = IslandGrowMoment(fromLevel: 3, toLevel: 4, reduceMotion: false, lowPower: true)
        #expect(low.bloom(at: 1.3) == 0)
        #expect(low.cues(after: -1, through: low.duration).count == 5)
    }

    @Test func aMomentNeverGrowsBackwards() {
        let odd = IslandGrowMoment(fromLevel: 5, toLevel: 3, reduceMotion: false)
        #expect(odd.toLevel == 5)
    }

    @Test func everyLevelTheTesterReachesHasALine() {
        for level in 2...8 {
            #expect(IslandGrowMoment.hasLine(for: level))
        }
        #expect(!IslandGrowMoment.hasLine(for: 1))
        #expect(!IslandGrowMoment.hasLine(for: 9))
    }
}

@MainActor
@Suite("Island level memory")
struct IslandLevelMemoryTests {
    @Test func aFirstLaunchHasNoNewsAndEachLevelSpeaksOnce() {
        let memory = IslandLevelMemory()
        #expect(memory.lastPresented == nil)
        #expect(memory.news(worldLevel: 4) == nil, "nothing is stored on a first launch")
        memory.record(4)
        #expect(memory.news(worldLevel: 4) == nil)
        // The island grew while the app was closed.
        #expect(memory.news(worldLevel: 5) == .stageGrew(5))
        #expect(memory.news(worldLevel: 5) == .stageGrew(5), "the news waits until the level is presented")
        memory.record(5)
        #expect(memory.news(worldLevel: 5) == nil)
        // Several levels at once ("Next day" in the Prova panel): one piece of news, for the last.
        #expect(memory.news(worldLevel: 8) == .stageGrew(8))
        // A world that went back says nothing.
        #expect(memory.news(worldLevel: 2) == nil)
    }

    @Test func theLevelIsRememberedAcrossLaunches() throws {
        let suite = "pofu.test.islandLevel.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        IslandLevelMemory(defaults: defaults).record(3)
        let next = IslandLevelMemory(defaults: defaults)
        #expect(next.lastPresented == 3)
        #expect(next.news(worldLevel: 4) == .stageGrew(4))
        #expect(IslandLevelMemory(defaults: nil).lastPresented == nil)
    }

    @Test func theNewsBeatAppearsOnceAndOnlyWhenTheIslandGrewWhileAway() {
        let calendar = Calendar(identifier: .gregorian)
        let day = PlayerPath.tester(days: 4)
        let morning = day[2].morning
        #expect(morning.islandLevel == 3)
        let memory = IslandLevelMemory()
        func plan() -> VisitPlan {
            let inputs = VisitInputs(now: morning.clock ?? Date(), world: morning, news: memory.news(worldLevel: morning.islandLevel), calendar: calendar)
            return VisitQueue.plan(inputs)
        }
        func hasNews(_ plan: VisitPlan) -> Bool {
            plan.beats.contains { if case .news = $0 { return true } else { return false } }
        }
        // A first launch lands on the true level.
        #expect(!hasNews(plan()))
        memory.record(2)
        #expect(plan().beats.contains(.news(.stageGrew(3))))
        // The moment began: the level is remembered, the news is gone.
        memory.record(3)
        #expect(!hasNews(plan()))
    }
}

@MainActor
@Suite("Morning voice")
struct MorningVoiceTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .gmt
        return calendar
    }()
    let pouch = SeedPouch(stations: Energy(30), gathered: Energy(6))

    func visit(_ beats: [VisitBeat]) -> VisitPlan {
        VisitPlan(landing: .visit, showsRepairBanner: false, beats: beats)
    }

    @Test func thePathMorningsSayTheCheeksLineRarelyAndNeverTwiceInAWeek() {
        let path = PlayerPath.tester(days: 21)
        var history = CheekLineHistory()
        var spoken: [(day: Int, variant: Int)] = []
        for day in path {
            let now = day.morningAt
            let home = WorldHomeModel(now: { now }, schedulesCues: false, calendar: calendar, cheekLineHistory: history)
            home.beginVisit(VisitQueue.plan(VisitInputs(now: now, world: day.morning, calendar: calendar)))
            history = home.cheekLineHistory
            if home.saysCheeksHuge { spoken.append((day.day, home.cheeksHugeVariant)) }
        }
        #expect(spoken.count <= 8, "rare: \(spoken.map(\.day))")
        for (a, b) in zip(spoken, spoken.dropFirst()) { #expect(b.day - a.day >= 3) }
    }

    @Test func aMorningWithNewsLetsTheNewsSpeakFirst() {
        let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
        let home = WorldHomeModel(now: { now }, schedulesCues: false, calendar: calendar)
        home.beginVisit(visit([.collect(pouch), .news(.stageGrew(3))]))
        #expect(!home.saysCheeksHuge, "the news speaks first")
        // The cheeks keep their line: the same day, a visit without news says it.
        home.beginVisit(visit([.collect(pouch)]))
        #expect(home.saysCheeksHuge)
    }
}

@MainActor
@Suite("Island news and the camera")
struct IslandNewsCameraTests {
    let pouch = SeedPouch(stations: Energy(30), gathered: Energy(6))

    func model() -> (WorldHomeModel, NewsSpy) {
        let home = WorldHomeModel(now: { Date(timeIntervalSinceReferenceDate: 815_000_000) }, schedulesCues: false)
        let spy = NewsSpy()
        home.camera = spy
        return (home, spy)
    }

    func visit(_ beats: [VisitBeat]) -> VisitPlan {
        VisitPlan(landing: beats.isEmpty ? .settled : .visit, showsRepairBanner: false, beats: beats)
    }

    @Test func anIslandThatGrewWaitsForTheVisitUntilItIsPlanned() {
        let (home, spy) = model()
        #expect(home.holdsIslandGrowForNews, "before any visit the news is not known yet")
        _ = spy
        home.beginVisit(visit([.news(.stageGrew(3))]))
        #expect(home.holdsIslandGrowForNews)
        #expect(spy.spoken == 0)
    }

    @Test func theNewsBeatsButtonLetsTheIslandGrow() {
        let (home, spy) = model()
        home.beginVisit(visit([.collect(pouch), .news(.stageGrew(3))]))
        #expect(home.hasStageNewsWaiting)
        // Collecting does not end the news: it is the next beat.
        home.acknowledgeCurrentBeat()
        #expect(home.currentBeat == .news(.stageGrew(3)))
        #expect(spy.spoken == 0)
        // The button.
        home.acknowledgeCurrentBeat()
        #expect(!home.hasStageNewsWaiting)
        #expect(!home.holdsIslandGrowForNews)
        #expect(spy.spoken == 1)
    }

    @Test func aVisitWithoutNewsReleasesAnIslandThatWasWaiting() {
        let (home, spy) = model()
        home.beginVisit(visit([]))
        #expect(!home.holdsIslandGrowForNews)
        #expect(spy.spoken == 1, "the night landing, a settled reopen: nothing will speak, so the island grows")
    }

    @Test func aNewIslandIsNotTheStageNews() {
        let (home, _) = model()
        home.beginVisit(visit([.news(.islandArrived(.harbor))]))
        #expect(!home.hasStageNewsWaiting)
    }
}
