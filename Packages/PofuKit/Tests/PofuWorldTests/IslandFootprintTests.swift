import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Island footprint (containment)")
struct IslandFootprintTests {
    @Test func thePlateHasAMeasuredWalkablePolygon() throws {
        let walkable = try #require(IslandFootprint.walkable)
        let bounds = try #require(walkable.bounds)
        #expect(walkable.points.count >= 12)
        // Inside the lawn ellipse (350 × 82 units), eroded off the rim.
        #expect(bounds.minX > -IslandLayout.lawnRadiusX && bounds.maxX < IslandLayout.lawnRadiusX)
        #expect(bounds.width > 300)
        #expect(walkable.contains(.zero))
        #expect(!walkable.contains(WorldPoint(x: 0, y: 60)))
        #expect(!walkable.contains(WorldPoint(x: 178, y: 0)))
    }

    @Test func everyStandingSpriteHasAFootprint() {
        for placement in IslandFootprint.placements {
            #expect(placement.footprint.points.count >= 3, "\(placement.id) has no footprint")
        }
    }

    /// The founder's rule: even in a prototype, nothing sticks out past the
    /// island. Every slot (built at any level or empty), every resident and
    /// Pofu must stand inside the walkable polygon.
    @Test func nothingSticksOutPastTheIsland() {
        #expect(IslandFootprint.offenders.isEmpty, "outside the walkable footprint: \(IslandFootprint.offenders)")
    }

    @Test func clampingIsANoOpForTheAuthoredLayout() {
        for placement in IslandFootprint.placements {
            #expect(IslandFootprint.clamped(placement.anchor, footprint: placement.footprint) == placement.anchor, "\(placement.id)")
        }
    }

    @Test func clampingPullsAnOverhangBackOntoTheLawn() throws {
        let footprint = IslandFootprint.footprint(of: "cay-1")
        let outside = WorldPoint(x: 150, y: 10)
        #expect(!IslandFootprint.fits(footprint, at: outside))
        let clamped = IslandFootprint.clamped(outside, footprint: footprint)
        #expect(IslandFootprint.fits(footprint, at: clamped))
        #expect(clamped.x < outside.x)
    }

    @Test func emittersFollowTheirStation() throws {
        let ember = try #require(IslandLayout.emitters.first { $0.station == .cay })
        let cay = try #require(IslandLayout.stationAnchors[.cay])
        #expect(abs(ember.point.x - (cay.x - 14.6)) < 1e-9)
        #expect(abs(ember.point.y - (cay.y - 23.1)) < 1e-9)
    }

    @Test func polygonContainment() {
        let square = WorldPolygon([WorldPoint(x: -1, y: -1), WorldPoint(x: 1, y: -1), WorldPoint(x: 1, y: 1), WorldPoint(x: -1, y: 1)])
        #expect(square.contains(.zero))
        #expect(!square.contains(WorldPoint(x: 2, y: 0)))
        #expect(square.bounds == WorldBox(minX: -1, minY: -1, maxX: 1, maxY: 1))
        let ellipse = WorldPolygon.ellipse(radiusX: 10, radiusY: 2)
        #expect(ellipse.contains(WorldPoint(x: 9, y: 0)))
        #expect(!ellipse.contains(WorldPoint(x: 0, y: 2.5)))
    }
}
