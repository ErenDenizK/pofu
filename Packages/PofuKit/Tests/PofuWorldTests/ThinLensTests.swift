import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Thin lens (WP11)")
struct ThinLensTests {
    private var home: HomePlate {
        get throws { try #require(HomePlate.shipped, "the package ships Plates/plate-home.json") }
    }

    private var shots: ThinLens.Shots {
        get throws { try #require(home.plate.near?.shots, "plate-home.json carries near.shots") }
    }

    /// The lens at Home, focused on Pofu's feet.
    private func lens(s: Double, N: Double, focusRow: Double? = nil) throws -> ThinLens {
        let plate = try home
        let pofu = try #require(plate.plate.characters["pofu"])
        return ThinLens(scale: s, aperture: N, focusRow: focusRow ?? pofu.y, unitsPerPixel: plate.unitsPerPixel, elevationDeg: try #require(plate.plate.elevationDeg))
    }

    @Test func homeDataCarriesTheCameraAndTheShots() throws {
        let plate = try home
        #expect(plate.plate.elevationDeg == 10.5)
        #expect(try shots == .standard)
        #expect(try shots.aperture(scale: 4.5) == 1.6)
        #expect(try shots.aperture(scale: 1.145) == 0.25)
        #expect(try shots.aperture(scale: 7.4) == 1.3)
        #expect(try shots.focusAperture(scale: 2.6) == 0.8)
    }

    @Test func subjectDistanceFollowsTheFraming() throws {
        #expect(abs(try lens(s: 1.145, N: 0.25).distance - 1200.9) < 0.1)
        #expect(abs(try lens(s: 4.5, N: 1.6).distance - 305.6) < 0.1)
        #expect(abs(try lens(s: 7.4, N: 1.3).distance - 185.8) < 0.1)
    }

    @Test func skyAtRestIs7_2Pt() throws {
        let rest = try lens(s: 4.5, N: 1.6)
        #expect(abs(rest.skyRadius - 7.2) < 1e-9)
        #expect(abs(rest.radius(delta: .infinity) - 7.2) < 1e-9)
    }

    @Test func midIsSharpFrontToBack() throws {
        let plate = try home
        let box = plate.plate.islandBox
        let lip = try #require(plate.plate.near?.lipRow)
        // Mid's focal plane: the island's centre.
        let mid = try lens(s: 1.145, N: 0.25, focusRow: (box.minY + box.maxY) / 2)
        for row in stride(from: box.minY, through: box.maxY, by: 1) {
            #expect(mid.radius(row: NearLayers.groundRow(row, lipRow: lip)) <= ThinLens.sharp, "row \(row)")
            #expect(mid.radius(row: row) <= ThinLens.sharp, "row \(row), even without the lip")
        }
        // The sky skips its blur at mid.
        #expect(ThinLens.applied(mid.skyRadius) == 0)
    }

    @Test func twoRowsOnOneLineAreSharpTogether() throws {
        let plate = try home
        let pofu = try #require(plate.plate.characters["pofu"])
        for (s, N) in [(4.5, 1.6), (7.4, 1.3), (2.6, 0.8)] {
            let l = try lens(s: s, N: N)
            // Whatever stands on Pofu's row is as sharp as he is, at either side of the island.
            #expect(l.radius(row: pofu.y) == 0)
            let world = [plate.world(PlatePoint(x: 120, y: pofu.y)), plate.world(PlatePoint(x: 900, y: pofu.y))]
            let frame = try #require(NearLensFrame.make(plate: plate, pose: CameraPose(scale: s, look: plate.world(pofu), anchorY: 500), width: 402, height: 874, focus: .subject(row: pofu.y)))
            #expect(frame.radius(worldY: world[0].y) == frame.radius(worldY: world[1].y))
            #expect(frame.radius(worldY: world[0].y) <= ThinLens.sharp)
        }
        // A thing on another row is not, at near.
        let rest = try lens(s: 4.5, N: 1.6)
        #expect(rest.radius(row: pofu.y - 60) > ThinLens.sharp)
    }

    @Test func nearRestMatchesTheShotTable() throws {
        let rest = try lens(s: 4.5, N: 1.6)
        // A stall 60 units behind: r 1.2, legible.
        #expect(abs(rest.radius(delta: 60) - 1.18) < 0.01)
        // The sharp zone: about 20 units each way.
        #expect(rest.radius(delta: 20) <= ThinLens.sharp)
        #expect(rest.radius(delta: -19) <= ThinLens.sharp)
        #expect(rest.radius(delta: 26) > ThinLens.sharp)
        #expect(rest.radius(delta: -22) > ThinLens.sharp)
    }

    @Test func blurIsCappedAt14() throws {
        let rest = try lens(s: 4.5, N: 1.6)
        #expect(try lens(s: 7.4, N: 40).skyRadius == ThinLens.cap)
        #expect(try lens(s: 7.4, N: 40).radius(delta: 3000) == ThinLens.cap)
        #expect(try lens(s: 4.5, N: 4).radius(delta: 2000) > ThinLens.frontCap)
        for row in stride(from: 300.0, through: 1600, by: 10) {
            #expect(rest.radius(row: row) <= ThinLens.cap)
        }
    }

    @Test func frontIsCappedAt3() throws {
        let plate = try home
        let pofu = try #require(plate.plate.characters["pofu"])
        let rest = try lens(s: 4.5, N: 1.6)
        // The wheel's foot (row 1000) and everything nearer: 3 pt at most, never 14.
        #expect(rest.radius(row: 1000) == ThinLens.frontCap)
        #expect(rest.radius(delta: -300) == ThinLens.frontCap)
        #expect(rest.radius(delta: -1000) == ThinLens.frontCap)
        for row in stride(from: pofu.y, through: 1600, by: 2) {
            #expect(rest.radius(row: row) <= ThinLens.frontCap, "row \(row)")
        }
        // It still grows smoothly up to the cap: a stone 20 rows in front is soft, not capped.
        #expect(rest.radius(row: pofu.y + 20) > ThinLens.sharp && rest.radius(row: pofu.y + 20) < ThinLens.frontCap)
        // Behind, the back keeps the 14 pt level.
        #expect(ThinLens.frontCap == 3)
        #expect(try lens(s: 7.4, N: 3).radius(delta: 5000) > ThinLens.frontCap)
    }

    @Test func isleBlurAndHazeAreCapped() {
        #expect(ThinLens.isleCap == 1.5 && ThinLens.isleHaze == 0.30)
        // The sky's radius up to the isle cap, never past it; the sky itself keeps up to 14.
        #expect(ThinLens.isleBlur(0.8) == 0.8)
        #expect(ThinLens.isleBlur(1.5) == 1.5)
        #expect(ThinLens.isleBlur(14) == ThinLens.isleCap)
        #expect(ThinLens.isleBlur(-1) == 0)
        // Haze: 0.30 x min(r / 4, 1).
        #expect(ThinLens.isleHazeShare(0) == 0)
        #expect(abs(ThinLens.isleHazeShare(2) - 0.15) < 1e-12)
        #expect(ThinLens.isleHazeShare(4) == 0.30)
        #expect(ThinLens.isleHazeShare(14) == 0.30)
    }

    @Test func skippingNeverSteps() {
        #expect(ThinLens.applied(0.34) == 0)
        #expect(ThinLens.applied(0.36) == 0.36)
        #expect(BlurLevels.effective(0.35) == 0)
        #expect(abs(BlurLevels.effective(0.36) - 0.01 * 2 / 1.65) < 1e-9)
        #expect(BlurLevels.effective(2) == 2)
        #expect(BlurLevels.effective(20) == 14)
    }

    @Test func levelWeightsSumToOneAndMoveContinuously() {
        var previous: [Double]?
        for r in stride(from: 0.0, through: 16, by: 0.01) {
            let w = BlurLevels.radii.indices.map { BlurLevels.weight(level: $0, radius: r) }
            #expect(abs(w.reduce(0, +) - 1) < 1e-9, "r \(r)")
            #expect(w.filter { $0 > 0 }.count <= 2, "at most two levels mix, r \(r)")
            if let previous {
                for i in w.indices {
                    #expect(abs(w[i] - previous[i]) < 0.02, "level \(i) steps at r \(r)")
                }
            }
            previous = w
        }
        #expect(BlurLevels.weight(level: 2, radius: 6) == 1)
        #expect(BlurLevels.weight(level: 3, radius: 9) == 0.375)
    }

    @Test func midNeedsNoLevelAndNearRestNeedsThreeLevels() throws {
        let plate = try home
        let pofu = plate.world(try #require(plate.plate.characters["pofu"]))
        let midScale = 1.145
        let mid = NearLensFrame.make(plate: plate, pose: CameraPose(scale: midScale, look: pofu, anchorY: 437), width: 402, height: 874, focus: .rail)
        #expect(mid == nil || mid?.levels == [0])
        let near = try #require(NearLensFrame.make(plate: plate, pose: CameraPose(scale: 4.5, look: pofu, anchorY: 0.6 * 874), width: 402, height: 874, focus: .rail))
        // The back at rest stays under 6 pt and the front stops at 6: the 14 pt level is not drawn.
        #expect(near.levels == [0, 1, 2])
        #expect(abs(near.lens.focusRow - (plate.plate.characters["pofu"]?.y ?? 0)) < 1e-6)
        #expect(abs(near.skyRadius - 7.2) < 1e-9)
    }

    @Test func standingThingsTakeTheirFootAndTheEarthFaceTheLip() throws {
        let plate = try home
        let regions = NearLayers.regions(plate)
        let lip = try #require(plate.plate.near?.lipRow)
        #expect(regions.contains { $0.id == "windmill" && $0.row == 762 })
        #expect(!regions.contains { $0.id == "pond" })
        #expect(regions.allSatisfy { $0.row <= lip })
        #expect(NearLayers.groundRow(1200, lipRow: lip) == lip)
        #expect(abs(NearLayers.decode(NearLayers.encode(row: 845)) - 845) < 1e-9)
    }

    @Test func featherSpreadsAnEdgeAndKeepsTheRowUnderIt() {
        // A standing thing's share (1 in the left half) and its row times the share (0.4).
        let w = 12, h = 5
        var share = (0..<(w * h)).map { $0 % w < 6 ? 1.0 : 0 }
        var rowShare = share.map { $0 * 0.4 }
        NearLayers.feather(&share, width: w, height: h, radius: 2)
        NearLayers.feather(&rowShare, width: w, height: h, radius: 2)
        for y in 0..<h {
            let line = Array(share[(y * w)..<(y * w + w)])
            #expect(abs(line[0] - 1) < 1e-9 && abs(line[w - 1]) < 1e-9)
            #expect(zip(line, line.dropFirst()).allSatisfy { $0 >= $1 }, "falls off monotonically")
            #expect(line[5] > 0.5 && line[6] < 0.5 && line[3] < 1 && line[8] > 0)
            for x in 0..<w where line[x] > 1e-6 {
                #expect(abs(rowShare[y * w + x] / line[x] - 0.4) < 1e-9)
            }
        }
    }
}
