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
}
