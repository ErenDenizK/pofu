import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Level-up ceremony of light")
struct LevelUpLightTests {
    func moment(reduceMotion: Bool = false, lowPower: Bool = false) -> BuildMoment {
        BuildMoment(station: .teaStall, fromLevel: 1, toLevel: 2, maxLevel: 5, reduceMotion: reduceMotion, lowPower: lowPower)
    }

    @Test func theTeaStallLightsFromTheLitSourceTable() {
        let points = BuildMoment.litPoints(station: .teaStall, level: 2)
        #expect(!points.isEmpty)
        #expect(points.contains(LitSources.rows.first { $0.id == "ember" }!.point))
        // A station with no row falls back to its anchor, never to nothing.
        #expect(!BuildMoment.litPoints(station: .garden, level: 1).isEmpty)
    }

    @Test func lampsStartFortyMillisecondsApartAndSettleBack() throws {
        let m = moment()
        let start = try #require(m.ceremonyStart)
        #expect(start == 0.42)
        #expect(m.lampFlare(index: 0, at: start - 0.01) == 0)
        #expect(m.lampFlare(index: 0, at: start + 0.05) > 0)
        // The second lamp is 40 ms late.
        #expect(m.lampFlare(index: 1, at: start + 0.02) == 0)
        #expect(m.lampFlare(index: 1, at: start + 0.05) > 0)
        #expect(m.lampFlare(index: 1, at: start + 0.05) < m.lampFlare(index: 0, at: start + 0.05))
        // Back to the time-of-day state afterwards.
        #expect(m.lampFlare(index: 3, at: start + 2) == 0)
    }

    @Test func theBurstBloomsAndCoversTheShadowRebuild() throws {
        let m = moment()
        let swap = try #require(m.time(of: .swap))
        #expect(m.burst(at: swap - 0.01) == nil)
        // The art swaps at the cross-fade's midpoint; the bake rebuilds then.
        let rebuild = swap + BuildMoment.crossFade / 2
        let covered = try #require(m.burst(at: rebuild))
        #expect(covered.opacity > 0.3 * BuildMoment.Ceremony.burstOpacity)
        let early = try #require(m.burst(at: swap + 0.05))
        let late = try #require(m.burst(at: swap + 0.6))
        #expect(late.radius > early.radius)
        #expect(m.burst(at: swap + 1.5) == nil)
    }

    @Test func theShadowRebuildsAtTheSwapNotAtTheTap() {
        let m = moment()
        #expect(m.shownLevel(at: 0.1) == 1)
        #expect(m.shownLevel(at: 0.2) == 1)
        #expect(m.shownLevel(at: 0.6) == 2)
    }

    @Test func thePadBrightensForOnePointTwoSeconds() throws {
        let m = moment()
        let swap = try #require(m.ceremonyStart)
        #expect(m.padGlow(at: swap - 0.01) == 0)
        #expect(m.padGlow(at: swap + 0.15) > 0.9)
        #expect(m.padGlow(at: swap + 0.6) > 0)
        #expect(m.padGlow(at: swap + 1.2) == 0)
        #expect(m.ceremonyEnd == swap + 1.2)
    }

    @Test func theCeremonyIsAPureFunctionOfTime() {
        let a = moment(), b = moment()
        for t in stride(from: 0.0, through: 3.0, by: 0.05) {
            #expect(a.padGlow(at: t) == b.padGlow(at: t))
            #expect(a.lampFlare(index: 2, at: t) == b.lampFlare(index: 2, at: t))
            #expect(a.burst(at: t)?.radius == b.burst(at: t)?.radius)
        }
    }

    @Test func reduceMotionOnlyCrossFades() throws {
        let m = moment(reduceMotion: true)
        #expect(m.burst(at: 0.3) == nil)
        // The lamps fade together, no stagger.
        let t = try #require(m.ceremonyStart) + 0.05
        #expect(m.lampFlare(index: 0, at: t) == m.lampFlare(index: 3, at: t))
        #expect(m.lampFlare(index: 0, at: t) > 0)
        #expect(m.padGlow(at: t) > 0)
    }

    @Test func lowPowerIsShorterWithNoParticles() throws {
        let normal = moment(), low = moment(lowPower: true)
        #expect(try #require(low.ceremonyEnd) < (try #require(normal.ceremonyEnd)))
        #expect(low.puffs(at: 0.6).isEmpty)
        #expect(low.sparkles(at: 0.6).isEmpty)
        #expect(!normal.puffs(at: 0.6).isEmpty)
        let swap = try #require(low.ceremonyStart)
        #expect(low.padGlow(at: swap + 0.8) == 0)
        #expect(normal.padGlow(at: swap + 0.8) > 0)
    }

    @Test func theMomentTierIsHeldOnlyWhileTheMomentRuns() {
        // The 60 Hz tier is requested while a build is active (`WorldHomeModel.build`
        // until the `.end` cue) and released with it; the ceremony ends inside that.
        let m = moment()
        #expect((m.ceremonyEnd ?? .infinity) < m.duration)
        let policy = FramePolicy.standard
        #expect(policy.directive(for: FrameDemand(isMoment: true)).hz == 60)
        #expect(policy.directive(for: FrameDemand()).hz == 0)
    }
}

@Suite("Cloud shadows")
struct CloudShadowTests {
    func shadow(hour: Double) -> SunShadow {
        let light = WorldLight.at(hour: hour, wellbeing: 78, calm: 1.4, isBedtime: false)
        return SunShadow.make(light: light, world: IslandSamples.grownIsland())
    }

    let ambient = FramePolicy.standard.directive(for: FrameState.ambient)
    let settled = FramePolicy.standard.directive(for: FrameState.settled)

    @Test func theyDriftOnlyAtTheAmbientTier() throws {
        let day = shadow(hour: 12)
        let moving = try #require(CloudShadows.frame(shadow: day, directive: ambient, lowPower: false, reduceMotion: false, ambientTime: 10, held: 0))
        #expect(moving.shift == 60)
        let frozen = try #require(CloudShadows.frame(shadow: day, directive: settled, lowPower: false, reduceMotion: false, ambientTime: 10, held: 42))
        #expect(frozen.shift == 42)
        let busy = FramePolicy.standard.directive(for: FrameState.moment)
        #expect(CloudShadows.frame(shadow: day, directive: busy, lowPower: false, reduceMotion: false, ambientTime: 10, held: 7)?.shift == 7)
    }

    @Test func softAndNeverDarkerThanTwelvePercent() throws {
        let frame = try #require(CloudShadows.frame(shadow: shadow(hour: 12), directive: ambient, lowPower: false, reduceMotion: false, ambientTime: 0, held: 0))
        #expect(frame.opacity <= 0.12)
        #expect(frame.opacity > 0)
        #expect(CloudShadows.shapes.count >= 2 && CloudShadows.shapes.count <= 3)
    }

    @Test func offInLowPowerReduceMotionAndAtNight() {
        let day = shadow(hour: 12)
        #expect(CloudShadows.frame(shadow: day, directive: ambient, lowPower: true, reduceMotion: false, ambientTime: 0, held: 0) == nil)
        #expect(CloudShadows.frame(shadow: day, directive: ambient, lowPower: false, reduceMotion: true, ambientTime: 0, held: 0) == nil)
        #expect(CloudShadows.frame(shadow: shadow(hour: 22.5), directive: ambient, lowPower: false, reduceMotion: false, ambientTime: 0, held: 0) == nil)
    }

    @Test func theTileWrapsWithoutAJump() {
        #expect(CloudShadows.shift(atAmbientTime: 0) == 0)
        #expect(CloudShadows.shift(atAmbientTime: CloudShadows.tileWidth / CloudShadows.driftSpeed + 1) == CloudShadows.driftSpeed)
        for shape in CloudShadows.shapes {
            #expect(shape.x - shape.radiusX > 0 && shape.x + shape.radiusX < CloudShadows.tileWidth)
            #expect(shape.y - shape.radiusY > 0 && shape.y + shape.radiusY < CloudShadows.tileHeight)
        }
    }
}
