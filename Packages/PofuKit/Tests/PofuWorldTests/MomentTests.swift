import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Moment curves")
struct MomentCurveTests {
    @Test func aSpringStartsFullAndComesToRest() {
        #expect(MomentCurves.springRemaining(0, duration: 0.55, bounce: 0.5) == 1)
        #expect(abs(MomentCurves.springRemaining(3, duration: 0.55, bounce: 0.5)) < 1e-3)
        #expect(abs(MomentCurves.springRemaining(3, duration: 0.5, bounce: 0)) < 1e-3)
    }

    @Test func aBouncySpringOvershoots() {
        let samples = stride(from: 0.0, through: 1.0, by: 0.01).map { MomentCurves.springRemaining($0, duration: 0.55, bounce: 0.5) }
        #expect(samples.contains { $0 < -0.05 })
        let critical = stride(from: 0.0, through: 1.0, by: 0.01).map { MomentCurves.springRemaining($0, duration: 0.55, bounce: 0) }
        #expect(critical.allSatisfy { $0 >= 0 })
    }
}

@Suite("Collect moment")
struct CollectMomentTests {
    let sources = [MomentPoint(x: 40, y: 500), MomentPoint(x: 360, y: 520)]
    let target = MomentPoint(x: 201, y: 790)

    func moment(total: Int, reduceMotion: Bool = false) -> CollectMoment {
        CollectMoment(total: total, jarBefore: 100, sources: sources, target: target, reduceMotion: reduceMotion)
    }

    @Test func atMostTwentyFourSeedsFly() {
        #expect(moment(total: 418).seedCount == 24)
        #expect(moment(total: 5).seedCount == 5)
        #expect(moment(total: 418, reduceMotion: true).seedCount == 0)
    }

    @Test func seedsLaunchStaggeredAndLandInThePill() throws {
        let m = moment(total: 418)
        #expect(m.seed(3, at: 0.1) == nil)
        let start = try #require(m.seed(3, at: 0.105 + 0.001))
        #expect(abs(start.x - 360) < 2 && abs(start.y - 520) < 2)
        let late = try #require(m.seed(3, at: 0.105 + 0.6))
        #expect(abs(late.x - target.x) < 6 && abs(late.y - target.y) < 6)
        #expect(m.seed(3, at: 0.105 + 0.63) == nil)
        // The toss arcs above the straight line between its ends.
        let mid = try #require(m.seed(0, at: 0.31))
        #expect(mid.y < (500 + 790) / 2)
    }

    @Test func theCounterRollsWithinASecondAndLandsOnTheTotal() {
        let m = moment(total: 418)
        #expect(m.counter(at: 0) == 100)
        #expect(m.counter(at: m.counterStart) == 100)
        #expect(m.counterEnd - m.counterStart <= CollectMoment.maxCounterRoll + 1e-9)
        #expect(m.counter(at: m.counterEnd + 0.001) == 518)
        var last = 100
        for t in stride(from: 0.0, through: m.duration, by: 0.01) {
            let value = m.counter(at: t)
            #expect(value >= last)
            last = value
        }
        #expect(last == 518)
    }

    @Test func atMostTenTicksAndASuccessAtTheLanding() {
        let m = moment(total: 418)
        #expect(m.tickTimes.count == 10)
        #expect(m.tickTimes.first == m.landing(of: 0))
        #expect(m.tickTimes.last == m.landing(of: 23))
        let cues = m.cues(after: -1, through: m.duration)
        #expect(cues.filter { $0 == .tick }.count == 10)
        #expect(cues.last == .end)
        #expect(cues.contains(.success))
        #expect(moment(total: 3).tickTimes.count == 3)
    }

    @Test func cuesSplitAcrossCallsPlayOnce() {
        let m = moment(total: 40)
        var played: [CollectMoment.Cue] = []
        var t = -1.0
        for step in stride(from: 0.0, through: m.duration + 0.1, by: 0.07) {
            played += m.cues(after: t, through: step)
            t = step
        }
        #expect(played == m.cues(after: -1, through: m.duration + 0.1))
    }

    @Test func reduceMotionCrossFadesTheCounter() {
        let m = moment(total: 418, reduceMotion: true)
        #expect(m.seed(0, at: 0.3) == nil)
        #expect(m.counter(at: 0) == 100)
        #expect(m.counter(at: 0.15) == 518)
        #expect(m.pillScale(at: 0.5) == 1)
        #expect(m.tickTimes.isEmpty)
        #expect(m.cues(after: -1, through: m.duration).contains(.success))
    }

    @Test func thePillPopsWhenTheCounterLands() {
        let m = moment(total: 40)
        #expect(m.pillScale(at: m.counterEnd - 0.01) == 1)
        #expect(m.pillScale(at: m.counterEnd) > 1.1)
        #expect(abs(m.pillScale(at: m.counterEnd + 2) - 1) < 1e-3)
    }
}

@Suite("Build moment")
struct BuildMomentTests {
    func moment(reduceMotion: Bool = false, to level: Int = 2) -> BuildMoment {
        BuildMoment(station: .teaStall, fromLevel: level - 1, toLevel: level, maxLevel: 5, reduceMotion: reduceMotion)
    }

    @Test func cuesFollowTheSpecTable() {
        let m = moment()
        let cues = m.cues(after: -1, through: m.duration)
        #expect(cues == BuildMoment.Cue.allCases)
        #expect(m.time(of: .swap) == 0.42)
        #expect(m.time(of: .settle) == 1.02)
        #expect(m.time(of: .sheetBack) == 1.75)
        #expect(abs(m.duration - 3.2) < 1e-9)
    }

    @Test func theSquashBottomsOutAtTheSwapAndPopsBack() {
        let m = moment()
        let still = m.stationScale(at: 0.2)
        #expect(still.x == 1 && still.y == 1)
        let deepest = m.stationScale(at: 0.42)
        #expect(abs(deepest.x - 1.06) < 1e-9 && abs(deepest.y - 0.88) < 1e-9)
        let mid = m.stationScale(at: 0.36)
        #expect(mid.y < 1 && mid.y > 0.88)
        // The pop overshoots into a stretch, then rests.
        let stretched = stride(from: 0.42, through: 1.2, by: 0.01).map { m.stationScale(at: $0).y }
        #expect(stretched.contains { $0 > 1.01 })
        let rest = m.stationScale(at: 3)
        #expect(abs(rest.x - 1) < 1e-3 && abs(rest.y - 1) < 1e-3)
    }

    @Test func theArtSwapsInsideTheSquash() {
        let m = moment(to: 3)
        #expect(m.shownLevel(at: 0.41) == 2)
        #expect(m.newArt(at: 0.42) == 0)
        #expect(m.shownLevel(at: 0.5) == 3)
        #expect(m.newArt(at: 0.56) == 1)
    }

    @Test func sixPuffsSevenSparklesAndATag() {
        let m = moment()
        #expect(m.puffs(at: 0.41).isEmpty)
        #expect(m.puffs(at: 0.5).count == 6)
        #expect(m.puffs(at: 1.1).isEmpty)
        #expect(m.sparkles(at: 0.7).count == 7)
        #expect(m.sparkles(at: 2).isEmpty)
        #expect(m.tag(at: 0.59)?.opacity == nil)
        #expect((m.tag(at: 1.0)?.opacity ?? 0) > 0.99)
        #expect(m.tag(at: 3.21)?.opacity == nil)
    }

    @Test func theResidentHopsAfterPofu() {
        let m = moment()
        #expect((m.time(of: .residentHop) ?? 0) > (m.time(of: .pofuHop) ?? 1))
        #expect(m.residentLift(at: 0.84) == 0)
        #expect(abs(m.residentLift(at: 0.84 + 0.21) - BuildMoment.residentHopHeight) < 1e-9)
        #expect(m.residentLift(at: 1.3) == 0)
    }

    @Test func reduceMotionKeepsOnlyTheCrossFadeAndTheTag() {
        let m = moment(reduceMotion: true)
        let flat = m.stationScale(at: 0.42)
        #expect(flat.x == 1 && flat.y == 1)
        #expect(m.puffs(at: 0.5).isEmpty)
        #expect(m.sparkles(at: 0.6).isEmpty)
        #expect(m.residentLift(at: 1) == 0)
        let cues = m.cues(after: -1, through: m.duration)
        #expect(!cues.contains(.pofuHop))
        #expect(cues.contains(.settle))
        #expect(m.tag(at: 0.5)?.opacity != nil)
    }

    @Test func theLastLevelIsTheFinalOne() {
        #expect(moment(to: 5).isFinalLevel)
        #expect(!moment(to: 4).isFinalLevel)
    }
}

@Suite("Sky")
struct SkyModelTests {
    @Test func theSkyIsContinuousThroughTheDay() {
        var previous = SkyModel.palette(minuteOfDay: 0)
        for minute in stride(from: 1.0, through: 24 * 60, by: 1) {
            let palette = SkyModel.palette(minuteOfDay: minute)
            #expect(abs(palette.zenith.red - previous.zenith.red) < 0.05)
            #expect(abs(palette.stars - previous.stars) < 0.05)
            previous = palette
        }
    }

    @Test func dayIsBrightAndNightHasStars() {
        let noon = SkyModel.palette(minuteOfDay: 12 * 60)
        let midnight = SkyModel.palette(minuteOfDay: 0)
        #expect(noon.stars == 0)
        #expect(midnight.stars == 1)
        #expect(noon.zenith.blue > midnight.zenith.blue)
        #expect(noon.grade.red == 1 && noon.grade.green == 1 && noon.grade.blue == 1)
        #expect(SkyModel.palette(minuteOfDay: 12 * 60, isBedtime: true) == midnight)
        let dark = SkyModel.palette(minuteOfDay: 12 * 60, isDark: true)
        #expect(dark.zenith.red < noon.zenith.red)
    }

    @Test func theSunCrossesTheSky() {
        let morning = SkyModel.palette(minuteOfDay: 9 * 60).sun.x
        let evening = SkyModel.palette(minuteOfDay: 17 * 60).sun.x
        #expect(morning < 0.5 && evening > 0.5)
    }

    @Test func cloudsWrapAroundTheStrip() {
        let x0 = SkyModel.cloudX(time: 0, speed: 5, phase: 100, width: 80, span: 402)
        #expect(x0 == 20)
        let later = SkyModel.cloudX(time: 482 / 5, speed: 5, phase: 100, width: 80, span: 402)
        #expect(abs(later - x0) < 1e-6)
        for t in stride(from: 0.0, through: 400, by: 7) {
            let x = SkyModel.cloudX(time: t, speed: 5, phase: 100, width: 80, span: 402)
            #expect(x >= -80 && x < 402)
        }
    }

    @Test func cloudsAreTheSameEveryLaunch() {
        #expect(CloudShape.lobes(seed: 5) == CloudShape.lobes(seed: 5))
        #expect(CloudShape.lobes(seed: 5) != CloudShape.lobes(seed: 6))
        for lobe in CloudShape.lobes(seed: 3) {
            #expect(lobe.x > 0 && lobe.x < 1)
            #expect(lobe.y + lobe.r <= 0.5 + 1e-9)
        }
    }
}
