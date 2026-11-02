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
        // Inside the large plate's lawn ellipse (480 × 87 units), eroded
        // off the rim.
        #expect(bounds.minX > -IslandLayout.lawnRadiusX && bounds.maxX < IslandLayout.lawnRadiusX)
        #expect(bounds.width > 440)
        #expect(walkable.contains(.zero))
        #expect(!walkable.contains(WorldPoint(x: 0, y: 60)))
        #expect(!walkable.contains(WorldPoint(x: IslandLayout.lawnRadiusX + 2, y: 0)))
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

    /// Look round 3: on the large plate every station (at every level and
    /// as an empty spot), Pofu and the residents stand on ground of their
    /// own; round 2 found five stations and Pofu could not share the small
    /// plate.
    @Test func noTwoThingsShareGround() {
        #expect(IslandFootprint.overlaps.isEmpty, "overlapping ground: \(IslandFootprint.overlaps)")
    }

    /// The characters are drawn in their own layer (the colour script's
    /// character light), so no station nearer the camera may overlap one.
    @Test func noNearerStationHidesACharacter() {
        let characters: [(String, WorldPoint, WorldBox)] =
            [("pofu", IslandLayout.pofu, IslandFraming.pofuBox)]
            + IslandLayout.residents.map { ("\($0.id)", $0.feet, IslandFraming.residentBox($0)) }
        for (id, feet, box) in characters {
            for (station, anchor) in IslandLayout.stationAnchors where anchor.y > feet.y {
                guard let s = IslandFraming.stationBox(station) else { continue }
                let overlaps = s.maxX > box.minX && s.minX < box.maxX && s.minY < box.maxY && s.maxY > box.minY
                #expect(!overlaps, "\(station) stands in front of \(id)")
            }
        }
    }

    @Test func everyGeneratedLevelHasArt() {
        for (station, levels) in IslandLayout.generatedLevels {
            for level in 1...levels {
                let art = IslandLayout.stationArt(station, level: level)
                #expect(art?.isStandIn == false, "\(station) \(level)")
                #expect(art.flatMap { WorldArt.sprite($0.name) } != nil, "\(station) \(level) was not baked")
            }
            // Past the generated levels the highest one stands in.
            let past = IslandLayout.stationArt(station, level: levels + 1)
            #expect(past?.name == "\(station.rawValue)-\(levels)" && past?.isStandIn == true)
        }
    }

    @Test func clampingIsANoOpForTheAuthoredLayout() {
        for placement in IslandFootprint.placements {
            #expect(IslandFootprint.clamped(placement.anchor, footprint: placement.footprint) == placement.anchor, "\(placement.id)")
        }
    }

    @Test func clampingPullsAnOverhangBackOntoTheLawn() throws {
        let footprint = IslandFootprint.footprint(of: "cay-1")
        let outside = WorldPoint(x: 220, y: 10)
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
