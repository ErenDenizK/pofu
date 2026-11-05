import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("World hit test (experience v1 §1.3)")
struct WorldHitTestTests {
    private let width = CameraRail.referenceWidth
    private var rail: CameraRail { CameraRail() }

    private func station(_ id: StationID, level: Int = 1) -> StationStatus {
        let sample = IslandSamples.playedWeek().snapshot.stations.first { $0.id == id }
        var status = sample ?? IslandSamples.playedWeek().snapshot.stations[0]
        status.level = level
        status.isOpen = true
        return status
    }

    private func target(_ kind: HitTarget.Kind, at point: WorldPoint, half: Double, depth: Double) -> HitTarget {
        HitTarget(
            kind: kind,
            worldBox: WorldBox(minX: point.x - half, minY: point.y - half, maxX: point.x + half, maxY: point.y + half),
            depth: depth
        )
    }

    @Test func theFrontmostTargetWins() {
        let pose = rail.pose(of: .home)
        let spot = WorldPoint(x: 0, y: 0)
        let behind = target(.station(.windmill), at: spot, half: 30, depth: 10)
        let front = target(.resident(.mochi), at: spot, half: 30, depth: 40)
        let screen = pose.project(spot, width: width)
        let hit = WorldHitTest.resolve(x: screen.x, y: screen.y, targets: [behind, front], pose: pose, width: width)
        #expect(hit == front)
        let reversed = WorldHitTest.resolve(x: screen.x, y: screen.y, targets: [front, behind], pose: pose, width: width)
        #expect(reversed == front)
    }

    @Test func aTieGoesToTheNearestCentre() {
        let pose = rail.pose(of: .home)
        let a = target(.station(.windmill), at: WorldPoint(x: 0, y: 0), half: 20, depth: 5)
        let b = target(.station(.workshop), at: WorldPoint(x: 12, y: 0), half: 20, depth: 5)
        let nearB = pose.project(WorldPoint(x: 9, y: 0), width: width)
        #expect(WorldHitTest.resolve(x: nearB.x, y: nearB.y, targets: [a, b], pose: pose, width: width) == b)
        let nearA = pose.project(WorldPoint(x: 3, y: 0), width: width)
        #expect(WorldHitTest.resolve(x: nearA.x, y: nearA.y, targets: [a, b], pose: pose, width: width) == a)
    }

    @Test func everyTargetIsInflatedToAtLeast44Points() {
        // At the Map's scale a 10-unit box is a few points wide.
        let pose = rail.pose(of: .map)
        let tiny = target(.station(.pond), at: WorldPoint(x: 0, y: 0), half: 5, depth: 0)
        let rect = WorldHitTest.screenRect(of: tiny, pose: pose, width: width)
        #expect(rect.maxX - rect.minX >= 44 - 1e-9)
        #expect(rect.maxY - rect.minY >= 44 - 1e-9)
        let centre = pose.project(WorldPoint(x: 0, y: 0), width: width)
        #expect(WorldHitTest.resolve(x: centre.x + 21, y: centre.y - 21, targets: [tiny], pose: pose, width: width) == tiny)
        #expect(WorldHitTest.resolve(x: centre.x + 24, y: centre.y, targets: [tiny], pose: pose, width: width) == nil)
    }

    @Test func aBigTargetKeepsItsOwnSize() {
        let pose = rail.pose(of: .home)
        let big = target(.station(.windmill), at: WorldPoint(x: 0, y: 0), half: 60, depth: 0)
        let rect = WorldHitTest.screenRect(of: big, pose: pose, width: width)
        #expect(abs((rect.maxX - rect.minX) - 120 * pose.scale) < 1e-6)
    }

    @Test func theViewOffsetMovesTheTargets() {
        let pose = rail.pose(of: .home)
        let t = target(.station(.windmill), at: WorldPoint(x: 0, y: 0), half: 20, depth: 0)
        let centre = pose.project(WorldPoint(x: 0, y: 0), width: width)
        #expect(WorldHitTest.resolve(x: centre.x + 20, y: centre.y, targets: [t], pose: pose, width: width, offset: (20, 0)) == t)
        #expect(WorldHitTest.resolve(x: centre.x + 20 + 80, y: centre.y, targets: [t], pose: pose, width: width, offset: (20, 0)) == nil)
    }

    @Test func emptyGroundResolvesToNothing() {
        let pose = rail.pose(of: .home)
        let targets = WorldHitTest.targets(stations: IslandSamples.playedWeek().snapshot.stations, z: 2)
        #expect(WorldHitTest.resolve(x: 5, y: 5, targets: targets, pose: pose, width: width) == nil)
    }

    @Test func atHomeThePropsAnswerOnTheirSlots() throws {
        let pose = rail.pose(of: .home)
        let targets = WorldHitTest.targets(stations: IslandSamples.playedWeek().snapshot.stations, z: 2)
        for prop in HomeSlots.Prop.allCases {
            let p = pose.project(prop.slot, width: width)
            let hit = try #require(WorldHitTest.resolve(x: p.x, y: p.y, targets: targets, pose: pose, width: width))
            #expect(hit.kind == .prop(prop), "\(prop) resolved to \(hit.kind)")
        }
    }

    @Test func thePropsAreTappableAtTheIslandFramingToo() throws {
        let pose = rail.pose(of: .island)
        let targets = WorldHitTest.targets(stations: IslandSamples.playedWeek().snapshot.stations, z: 1)
        let p = pose.project(HomeSlots.jar, width: width)
        let hit = try #require(WorldHitTest.resolve(x: p.x, y: p.y, targets: targets, pose: pose, width: width))
        #expect(hit.kind == .prop(.jar))
    }

    @Test func theArchipelagoOnlyAnswersWithIslands() throws {
        let pose = rail.pose(of: .map)
        let targets = WorldHitTest.targets(stations: IslandSamples.playedWeek().snapshot.stations, z: 0)
        #expect(!targets.isEmpty)
        for t in targets {
            guard case .island = t.kind else {
                Issue.record("a non-island target on the Archipelago: \(t.kind)")
                continue
            }
        }
        // The home plate's centre is the home island; the harbor answers too.
        let home = pose.project(WorldPoint(x: 0, y: 40), width: width)
        let hitHome = try #require(WorldHitTest.resolve(x: home.x, y: home.y, targets: targets, pose: pose, width: width))
        #expect(hitHome.kind == .island(.home))
        let harbor = try #require(IslandLayout.isles.first)
        let p = pose.project(harbor.center, width: width)
        let hit = try #require(WorldHitTest.resolve(x: p.x, y: p.y, targets: targets, pose: pose, width: width))
        #expect(hit.kind == .island(harbor.id))
        // The sea between answers nothing.
        let sea = pose.project(WorldPoint(x: -380, y: 380), width: width)
        #expect(WorldHitTest.resolve(x: sea.x, y: sea.y, targets: targets, pose: pose, width: width) == nil)
    }

    @Test func aBuiltStationAnswersAtTheIslandFraming() throws {
        let pose = rail.pose(of: .island)
        let status = station(.windmill)
        let targets = WorldHitTest.targets(stations: [status], z: 1)
        let anchor = try #require(IslandLayout.stationAnchors[.windmill])
        let p = pose.project(WorldPoint(x: anchor.x, y: anchor.y - 40), width: width)
        let hit = try #require(WorldHitTest.resolve(x: p.x, y: p.y, targets: targets, pose: pose, width: width))
        #expect(hit.kind == .station(.windmill))
    }
}
