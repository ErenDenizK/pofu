import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The plate compositor (WP10, world presentation v2 §6.2): looks sorted with what stands on the plate by `footY`,
/// presence = built where a base exists, the far picture's key, and the level-up reveal's timeline (§9.2).
struct PlateCompositorTests {
    private var plate: PlateIsland {
        get throws { try #require(HomePlate.shipped?.plate) }
    }

    /// The day state at `stage` with the tea stall at `level`.
    private func compositor(stage: Int, teaStall level: Int, light: String = "day") throws -> PlateCompositor {
        try PlateCompositor(plate: HomePlate(plate: plate, light: light, stage: stage), levels: [.teaStall: level])
    }

    @Test func looksSortWithCharactersByFootY() throws {
        let c = try compositor(stage: 7, teaStall: 3)
        let look = try #require(c.looks.first)
        #expect(c.looks.map(\.station) == ["teaStall"])
        let home = c.plate
        let x = (look.box.minX + look.box.maxX) / 2
        func feet(_ dy: Double) -> WorldPoint { home.world(PlatePoint(x: home.plate(WorldPoint(x: x, y: 0)).x, y: look.footY + dy)) }
        let order = c.order(items: [("front", feet(12)), ("behind", feet(-12)), ("tie", feet(0))])
        #expect(order == [.base, .item("behind"), .look("teaStall"), .item("tie"), .item("front")])

        // what stands behind the look and overlaps it is covered by it; what stands in front is not
        let box = WorldBox(minX: x - 10, minY: feet(-12).y - 40, maxX: x + 10, maxY: feet(-12).y)
        #expect(c.looks(over: feet(-12), box: box).map(\.station) == ["teaStall"])
        let front = WorldBox(minX: x - 10, minY: feet(12).y - 40, maxX: x + 10, maxY: feet(12).y)
        #expect(c.looks(over: feet(12), box: front).isEmpty)

        // D7: on the base the painted stall's occluder retires (its look stands instead); where the plate paints the
        // stall (stage 5) the painted occluder stays
        #expect(!home.occluders(over: feet(-12), box: box).contains { $0.station == .teaStall })
        let painted = HomePlate(plate: try plate, light: "day", stage: 5)
        let stall = try #require(painted.objects.first { $0.station == .teaStall })
        let b = painted.occluderBox(stall)
        let behind = painted.world(PlatePoint(x: (PlateMath.bounds(stall.polygon).minX + PlateMath.bounds(stall.polygon).maxX) / 2, y: stall.footY - 10))
        let character = WorldBox(minX: behind.x - 5, minY: b.minY, maxX: behind.x + 5, maxY: behind.y)
        #expect(painted.occluders(over: behind, box: character).contains { $0.station == .teaStall })
    }

    /// The spec's `aBuiltStationShowsAtIslandLevel1`, at the island levels that have a base: the tea stall's erased
    /// bases are day stages 3, 4, 6 and 7 (island levels 7, 6, 4, 3); island level 1 (stage 9) paints no stall and
    /// has no base, so there the plate still decides.
    @Test func aBuiltStationShowsAtEveryIslandLevelWithABase() throws {
        let plate = try plate
        for stage in [3, 4, 6, 7] {
            let built = try compositor(stage: stage, teaStall: 1)
            #expect(built.presence(.teaStall) == true, "stage \(stage)")
            #expect(built.looks.first?.art == "world-home-look-teaStall-1-day")
            #expect(try compositor(stage: stage, teaStall: 0).presence(.teaStall) == false, "unbuilt: the base's plot")
        }
        #expect(plate.stageLevels[7] == 3)
        for stage in [0, 1, 2, 5, 8, 9] {
            #expect(try compositor(stage: stage, teaStall: 3).presence(.teaStall) == nil, "stage \(stage) keeps its painting")
        }
        // a station without looks keeps the painted plate everywhere
        #expect(try compositor(stage: 7, teaStall: 3).presence(.windmill) == nil)
    }

    @Test func snapshotKeyChangesWithABuild() throws {
        let two = try compositor(stage: 7, teaStall: 2).snapshotKey
        let three = try compositor(stage: 7, teaStall: 3).snapshotKey
        #expect(two != three)
        // past the last look, and a station without a base here, the picture is the same
        #expect(try compositor(stage: 7, teaStall: 5).snapshotKey == compositor(stage: 7, teaStall: 6).snapshotKey)
        let plate = try plate
        let withWorkshop = PlateCompositor(plate: HomePlate(plate: plate, light: "day", stage: 7), levels: [.teaStall: 3, .workshop: 4])
        #expect(withWorkshop.snapshotKey == three)
        // the state is part of it
        #expect(try compositor(stage: 6, teaStall: 3).snapshotKey != three)
        #expect(try compositor(stage: 7, teaStall: 3, light: "night").snapshotKey != three)
    }

    @Test func aBuildRevealsOnlyWhenItsLookChanges() throws {
        let c = try compositor(stage: 7, teaStall: 3)
        #expect(c.reveals(.teaStall, from: 2, to: 3))
        #expect(c.reveals(.teaStall, from: 0, to: 1))
        #expect(!c.reveals(.teaStall, from: 5, to: 6))
        #expect(!c.reveals(.windmill, from: 2, to: 3))
        #expect(try !compositor(stage: 5, teaStall: 3).reveals(.teaStall, from: 2, to: 3))
    }

    @Test func aBuiltStationAnswersOverItsLook() throws {
        let plate = try plate
        let home = HomePlate(plate: plate, light: "day", stage: 7)
        func world(_ level: Int) -> WorldSnapshot {
            IslandSamples.world(clock: nil, tendedDays: 30, levels: [.teaStall: level], jar: .zero, islands: [.home], islandLevel: 3)
        }
        let look = try #require(PlateCompositor(plate: home, levels: [.teaStall: 5]).looks.first)
        let target = try #require(WorldHitTest.plateTargets(home, stations: world(5).stations, z: 2).first { $0.kind == .plateObject("teaStall") })
        #expect(target.worldBox == look.box)
        let plot = try #require(WorldHitTest.plateTargets(home, stations: world(0).stations, z: 2).first { $0.kind == .plateObject("teaStall") })
        #expect(plot.worldBox != look.box)
    }

    // MARK: The reveal (v2 §9.2)

    @Test func theRevealFollowsTheSequenceInAtMost3_2Seconds() throws {
        let m = BuildMoment(station: .teaStall, fromLevel: 2, toLevel: 3, maxLevel: 10, reduceMotion: false, reveal: true)
        let r = try #require(StationReveal(m))
        #expect(m.duration <= 3.2)
        #expect(m.time(of: .anticipation) == 0.5)
        #expect(r.ringStart == 0.75)
        #expect(abs((m.time(of: .residentHop) ?? 0) - (r.ringStart + 0.9)) < 1e-9)
        // the tag ends with the moment
        #expect(m.tag(at: 3.19) != nil && m.tag(at: 3.2) == nil)
        // focus: nothing moves; the dip: the old look 4 % lower at its foot, the new one hidden
        #expect(r.oldScaleY(at: 0.4) == 1 && r.ring(at: 0.4) == nil && r.newOpacity(at: 0.4) == 0)
        #expect(abs(r.oldScaleY(at: 0.75) - 0.96) < 1e-9)
        // the ring opens over 0.7 s, then the look settles from 1.06 to 1 over 0.35 s
        #expect(r.ring(at: 0.75) == 0)
        let mid = try #require(r.ring(at: 1.1))
        #expect(mid > 0.3 && mid < 1)
        #expect(r.ring(at: 1.45) == 1 && r.oldOpacity(at: 1.45) == 0)
        #expect(r.newScale(at: 1.0) == 1.06)
        #expect(abs(r.newScale(at: 1.8) - 1) < 1e-9)
        #expect(r.rim(at: 1.0) == 1 && r.rim(at: 1.45) == 0)
        #expect(abs(r.end - 1.8) < 1e-9 && !r.isActive(at: 1.81))
        // the painted-station squash is not played over a look
        #expect(m.stationScale(at: 0.7) == (x: 1, y: 1))
        // a plain build keeps its own timeline
        #expect(StationReveal(BuildMoment(station: .teaStall, fromLevel: 2, toLevel: 3, maxLevel: 10, reduceMotion: false)) == nil)
    }

    @Test func withReduceMotionTheRevealIsA0_4sCrossFade() throws {
        let m = BuildMoment(station: .teaStall, fromLevel: 2, toLevel: 3, maxLevel: 10, reduceMotion: true, reveal: true)
        let r = try #require(StationReveal(m))
        let start = r.ringStart
        #expect(r.ring(at: start + 0.2) == nil)
        #expect(r.oldScaleY(at: start + 0.2) == 1 && r.newScale(at: start + 0.2) == 1)
        #expect(abs(r.newOpacity(at: start + 0.2) - 0.5) < 1e-9)
        #expect(abs(r.oldOpacity(at: start + 0.2) - 0.5) < 1e-9)
        #expect(r.newOpacity(at: start + 0.4) == 1)
        #expect(abs(m.newArt(at: start + 0.2) - 0.5) < 1e-9)
        #expect(r.end == start + 0.4)
    }

    // MARK: Looks per light (PR 1a)

    /// The tea stall with golden bases at its day stages and the day look at level 4 left out.
    private func gradedPlate() throws -> PlateIsland {
        var p = try plate
        p.stations["teaStall"]?.lights["golden"] = [3, 4, 6, 7]
        p.stations["teaStall"]?.lookLevels["day"] = [1, 2, 3, 5]
        return p
    }

    @Test func goldenDrawsTheDayLookUnderItsGrade() throws {
        let p = try gradedPlate()
        let golden = PlateCompositor(plate: HomePlate(plate: p, light: "golden", stage: 7), levels: [.teaStall: 3])
        let look = try #require(golden.looks.first)
        #expect(look.art == "world-home-look-teaStall-3-day")
        #expect(look.grade == golden.plate.harmony.tint)
        #expect(p.drawnPlateArt(light: "golden", stage: 7) == "world-home-base-golden-7")
        // the day state draws the same art ungraded, over its own base
        let day = PlateCompositor(plate: HomePlate(plate: p, light: "day", stage: 7), levels: [.teaStall: 3])
        #expect(day.looks.first?.art == look.art && day.looks.first?.grade == nil)
        // without a golden base the state keeps its painted plate and draws no look
        let bare = try compositor(stage: 7, teaStall: 3, light: "golden")
        #expect(bare.looks.isEmpty)
    }

    @Test func aMissingLookDrawsTheNearestLowerOne() throws {
        let p = try gradedPlate()
        func art(_ level: Int, _ light: String = "day") -> String? {
            p.lookArt(station: "teaStall", level: level, light: light, stage: 7)
        }
        #expect(art(4) == "world-home-look-teaStall-3-day")
        #expect(art(5) == "world-home-look-teaStall-5-day")
        #expect(art(0) == nil)
        // golden follows the day looks
        #expect(p.lookArt(station: "teaStall", level: 4, light: "golden", stage: 7) == "world-home-look-teaStall-3-day")
        // nothing painted at or below the level: nothing drawn
        var q = p
        q.stations["teaStall"]?.lookLevels["day"] = [2]
        #expect(q.lookArt(station: "teaStall", level: 1, light: "day", stage: 7) == nil)
        let c = PlateCompositor(plate: HomePlate(plate: p, light: "day", stage: 7), levels: [.teaStall: 4])
        #expect(c.looks.first?.look == 3)
    }
}
