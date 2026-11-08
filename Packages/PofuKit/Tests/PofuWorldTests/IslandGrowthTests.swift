import Foundation
import Testing
@testable import PofuWorld

@Suite("Island growth")
struct IslandGrowthTests {
    @Test func everyIslandLevelFromTwoToTenAddsSomethingSeen() {
        for level in 2...10 {
            let fresh = IslandGrowth.arriving(atLevel: level)
            let flowers = IslandDressing.pieces(atLevel: level).filter { !IslandDressing.pieces(atLevel: level - 1).contains($0) }
            #expect(!(fresh.isEmpty && flowers.isEmpty), "island level \(level) shows nothing new")
        }
    }

    @Test func everyLevelFromTwoToTenAddsSomethingThatMoves() {
        for level in 2...10 {
            let moving = IslandGrowth.arriving(atLevel: level).contains { $0.kind.moves }
            let flowers = IslandDressing.pieces(atLevel: level).contains { $0.touchable && $0.levels.lowerBound == level }
            #expect(moving || flowers, "island level \(level) has nothing moving")
        }
    }

    @Test func growthNeverLeaves() {
        for level in 1..<10 {
            let now = Set(IslandGrowth.pieces(atLevel: level).map(\.id))
            let next = Set(IslandGrowth.pieces(atLevel: level + 1).map(\.id))
            #expect(now.isSubset(of: next))
        }
    }

    @Test func groundPiecesLieOnTheWalkableLawn() throws {
        let lawn = try #require(IslandFootprint.walkable)
        for piece in IslandGrowth.pieces where (piece.kind == .pathStone || piece.kind == .steppingStone) || piece.kind == .lilyPad || piece.kind == .reeds {
            #expect(lawn.contains(piece.point), "\(piece.id) is off the lawn")
        }
    }

    @Test func aStillFrameDrawsTheRestPose() {
        for piece in IslandGrowth.pieces {
            let rest = IslandGrowth.motion(of: piece, at: 0)
            #expect(rest.dx == 0 && rest.dy == 0 && rest.degrees == 0)
        }
    }

    @Test func movingPiecesMoveOrAnimateInside() {
        let gull = IslandGrowth.pieces.first { $0.kind == .gull }
        #expect(gull.map { IslandGrowth.motion(of: $0, at: 3).dx != 0 } == true)
    }

    @Test func homeFramingShowsTheLawnWithPofuAtNinetyPoints() {
        let stop = IslandFraming.homeStop()
        #expect(64 * stop.scale >= 89)
        // The lawn's width on screen is at least the screen's: both edges are reached.
        #expect(IslandLayout.lawnRadiusX * 2 * stop.scale >= CameraRail.referenceWidth * 0.99)
        // The earth body (below the lawn's front edge) is at most a quarter of the screen's height.
        let plate = IslandFraming.plateBox
        let earth = (plate.maxY - IslandLayout.lawnRadiusY) * stop.scale
        #expect(earth <= CameraRail.referenceHeight * 0.25)
    }

    @Test func homeFramingKeepsPofusOwnDoorOnScreenAndTheTeaStallMostlyVisible() throws {
        let stop = IslandFraming.homeStop()
        // The door (about 36 units wide) is whole, a few points inside the left edge.
        let doorLeft = 201 + (IslandFraming.pofuDoorX - 18 - stop.look.x) * stop.scale
        #expect(doorLeft >= 6, "door left edge at \(doorLeft) pt")
        // The tea stall is at least half in frame on the right.
        let stall = try #require(IslandFraming.stationBox(.teaStall))
        let visible = min(201 + (stall.maxX - stop.look.x) * stop.scale, CameraRail.referenceWidth) - (201 + (stall.minX - stop.look.x) * stop.scale)
        #expect(visible / ((stall.maxX - stall.minX) * stop.scale) >= 0.5)
    }

    private func piece(_ id: String) throws -> GrowthPiece {
        try #require(IslandGrowth.pieces.first { $0.id == id })
    }

    @Test func theHillGateAndHilltopSitAtTheLawnsLeftTip() throws {
        // Concept flows §2.1 row 14-15: gate (-226, -12), Tepe (-172, -112).
        let gate = try piece("gate").point, top = try piece("hilltop").point
        #expect(gate == WorldPoint(x: -226, y: -12))
        #expect(top == WorldPoint(x: -172, y: -112))
        // The gate is inside the lawn, near its left tip.
        let nx = gate.x / IslandLayout.lawnRadiusX, ny = gate.y / IslandLayout.lawnRadiusY
        #expect(nx * nx + ny * ny < 1)
        #expect(gate.x < -0.9 * IslandLayout.lawnRadiusX)
        for stone in IslandGrowth.pieces where stone.kind == .hillStone {
            #expect(stone.point.x < -200 && stone.point.x > -245, "\(stone.id) is not at the left tip")
            #expect(stone.point.y < 0 && stone.point.y > -100)
        }
        #expect(IslandGrowth.pieces.filter { $0.kind == .hillStone }.count == 4)
    }

    @Test func theBenchStandsAtTheLookoutFromTheTepe() throws {
        let bench = try piece("hilltop-bench")
        #expect(bench.point == WorldPoint(x: -150, y: -112))
        #expect(bench.from == 10)
    }

    @Test func pathStonesRunTheFrontLipAndP1RunsBehindPofu() throws {
        for (i, p) in IslandGrowth.pathStones.enumerated() where i < 3 {
            #expect(p.1 == 34, "front-lip stone \(i + 1) is off y 34")
        }
        let p1 = IslandGrowth.pieces.filter { $0.id.hasPrefix("p1-") }
        #expect(p1.count >= 8)
        for stone in p1 {
            #expect((6...24).contains(stone.point.y), "\(stone.id) leaves P1's band")
            #expect(stone.from == 2)
        }
        // Behind Pofu: every stone near his x is behind (smaller y than) his feet.
        for stone in p1 where abs(stone.point.x - IslandLayout.pofu.x) < 30 {
            #expect(stone.point.y < IslandLayout.pofu.y)
        }
    }

    @Test func theWheelAnchorIsFixedOnTheFrontLip() throws {
        // On the plate's lip (inside the lawn ellipse; the walkable polygon is a little tighter).
        let w = IslandLayout.wheelAnchor
        #expect(w == WorldPoint(x: -115, y: 36))
        let nx = w.x / IslandLayout.lawnRadiusX, ny = w.y / IslandLayout.lawnRadiusY
        #expect(nx * nx + ny * ny < 1)
    }
}
