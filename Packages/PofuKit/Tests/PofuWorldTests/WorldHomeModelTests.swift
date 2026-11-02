import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// A clock the test moves by hand.
@MainActor
final class TestClock {
    var now = Date(timeIntervalSinceReferenceDate: 815_000_000)

    func advance(_ seconds: Double) {
        now = now.addingTimeInterval(seconds)
    }
}

/// Records what the build moment asked of the camera.
@MainActor
final class CameraSpy: WorldCamera {
    var calls: [String] = []

    func beginBuildFraming(_ station: StationID) {
        calls.append("in:\(station)")
    }

    func endBuildFraming(_ station: StationID) {
        calls.append("back:\(station)")
    }
}

@MainActor
@Suite("World home model")
struct WorldHomeModelTests {
    let clock = TestClock()
    let pouch = SeedPouch(stations: Energy(30), gathered: Energy(6))

    func model() -> WorldHomeModel {
        let clock = self.clock
        return WorldHomeModel(now: { clock.now }, schedulesCues: false)
    }

    func visit(_ beats: [VisitBeat]) -> VisitPlan {
        VisitPlan(landing: beats.isEmpty ? .settled : .visit, showsRepairBanner: false, beats: beats)
    }

    // MARK: Collect

    @Test func collectCommitsFirstThenPlaysAndEndsTheBeat() {
        let home = model()
        home.beginVisit(visit([.collect(pouch), .build(.cay, level: 2)]))
        var commits = 0
        let started = home.collectSeeds(jarBefore: 50, sources: [MomentPoint(x: 10, y: 400)], target: MomentPoint(x: 200, y: 800)) {
            commits += 1
            return pouch
        }
        #expect(started)
        #expect(commits == 1)
        #expect(home.collectTaps == 1)
        #expect(home.collect?.moment.jarAfter == 86)
        // A second tap mid-moment is ignored and commits nothing.
        let again = home.collectSeeds(jarBefore: 86, sources: [], target: MomentPoint(x: 0, y: 0)) {
            commits += 1
            return pouch
        }
        #expect(!again)
        #expect(commits == 1)

        let moment = home.collect?.moment
        clock.advance((moment?.counterEnd ?? 0) + 0.01)
        home.advance(to: clock.now)
        #expect(home.collectTicks == 10)
        #expect(home.collectSuccesses == 1)
        #expect(home.currentBeat == .collect(pouch))

        clock.advance(CollectMoment.hold)
        home.advance(to: clock.now)
        #expect(home.collect == nil)
        #expect(home.currentBeat == .build(.cay, level: 2))
        // Cues never fire twice.
        home.advance(to: clock.now)
        #expect(home.collectSuccesses == 1)
    }

    @Test func nothingToCollectEndsTheBeatQuietly() {
        let home = model()
        home.beginVisit(visit([.collect(pouch)]))
        let started = home.collectSeeds(jarBefore: 0, sources: [], target: MomentPoint(x: 0, y: 0)) { nil }
        #expect(!started)
        #expect(home.collect == nil)
        #expect(home.isSettled)
        #expect(home.settledAt == clock.now)
        #expect(home.collectSuccesses == 0)
    }

    // MARK: Build

    @Test func buildCommitsAndDrivesTheCamera() {
        let home = model()
        let camera = CameraSpy()
        home.camera = camera
        home.beginVisit(visit([.build(.cay, level: 2)]))
        let started = home.buildStation(.cay, maxLevel: 5) { station in
            BuildReceipt(station: station, level: 2, cost: Energy(88))
        }
        #expect(started)
        #expect(home.buildingStation == .cay)
        #expect(camera.calls == ["in:cay"])
        #expect(home.isSettled)

        // Refused while the sheet is compact.
        var commits = 0
        let again = home.buildStation(.cay, maxLevel: 5) { station in
            commits += 1
            return BuildReceipt(station: station, level: 3, cost: Energy(194))
        }
        #expect(!again)
        #expect(commits == 0)

        clock.advance(0.5)
        home.advance(to: clock.now)
        #expect(home.buildSwaps == 1)
        #expect(home.celebrations == 0)
        clock.advance(0.6)
        home.advance(to: clock.now)
        #expect(home.celebrations == 1)
        #expect(home.buildSettles == 1)
        #expect(home.finalBuilds == 0)
        clock.advance(0.7)
        home.advance(to: clock.now)
        #expect(home.buildingStation == nil)
        #expect(camera.calls == ["in:cay", "back:cay"])
        clock.advance(2)
        home.advance(to: clock.now)
        #expect(home.build == nil)
    }

    @Test func aFailedCommitPlaysNothing() {
        let home = model()
        let camera = CameraSpy()
        home.camera = camera
        let started = home.buildStation(.cay, maxLevel: 5) { _ in nil }
        #expect(!started)
        #expect(home.build == nil)
        #expect(camera.calls.isEmpty)
    }

    @Test func theLastLevelCelebratesDifferently() {
        let home = model()
        home.buildStation(.cay, maxLevel: 5) { station in BuildReceipt(station: station, level: 5, cost: Energy(937)) }
        clock.advance(1.1)
        home.advance(to: clock.now)
        #expect(home.finalBuilds == 1)
        #expect(home.buildSettles == 0)
    }

    @Test func aSecondBuildAfterTheSheetReturnsReplacesTheFirst() {
        let home = model()
        home.buildStation(.cay, maxLevel: 5) { station in BuildReceipt(station: station, level: 2, cost: Energy(88)) }
        clock.advance(2)
        home.advance(to: clock.now)
        #expect(home.buildingStation == nil)
        let second = home.buildStation(.cay, maxLevel: 5) { station in BuildReceipt(station: station, level: 3, cost: Energy(194)) }
        #expect(second)
        #expect(home.build?.moment.toLevel == 3)
    }

    @Test func reduceMotionBuildsWithoutHops() {
        let home = model()
        home.reduceMotion = true
        home.buildStation(.cay, maxLevel: 5) { station in BuildReceipt(station: station, level: 2, cost: Energy(88)) }
        clock.advance(3)
        home.advance(to: clock.now)
        #expect(home.celebrations == 0)
        #expect(home.buildSettles == 1)
        #expect(home.build == nil)
    }

    @Test func aFrozenMomentStopsAtItsOffset() {
        let home = model()
        let camera = CameraSpy()
        home.camera = camera
        home.buildStation(.cay, maxLevel: 5) { station in BuildReceipt(station: station, level: 2, cost: Energy(88)) }
        home.freeze(at: 0.5)
        #expect(home.buildTime(at: clock.now.addingTimeInterval(10)) == 0.5)
        #expect(home.buildSwaps == 1)
        #expect(home.celebrations == 0)
        #expect(home.buildingStation == .cay)
    }

    // MARK: The visit

    @Test func acknowledgingTheLastBeatSettles() {
        let home = model()
        home.beginVisit(visit([.care]))
        #expect(!home.isSettled)
        #expect(home.settledAt == nil)
        home.acknowledgeCurrentBeat()
        #expect(home.isSettled)
        #expect(home.settledAt == clock.now)
    }

    @Test func aSettledPofuSaysOneLineATapInOrder() {
        let home = model()
        home.beginVisit(visit([]))
        #expect(home.settledAt != nil)
        home.pofuTapped()
        #expect(home.settledLine == 0)
        home.pofuTapped()
        #expect(home.settledLine == 1)
        home.beginVisit(visit([.care]))
        home.pofuTapped()
        #expect(home.settledLine == nil)
    }
}
