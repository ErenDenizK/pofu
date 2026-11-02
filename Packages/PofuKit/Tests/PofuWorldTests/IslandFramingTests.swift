import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Island framing")
struct IslandFramingTests {
    /// Screen interval of a world box under a pose.
    func span(_ box: WorldBox, _ pose: CameraPose, width: Double) -> (lo: Double, hi: Double) {
        (width / 2 + (box.minX - pose.lookX) * pose.scale, width / 2 + (box.maxX - pose.lookX) * pose.scale)
    }

    @Test(arguments: [(402.0, 874.0), (375.0, 812.0), (440.0, 956.0)])
    func everyStationAndCharacterIsOnScreenAtTheIslandFraming(size: (Double, Double)) {
        let rail = CameraRail(width: size.0, height: size.1)
        let pose = rail.pose(of: .island)
        let boxes = IslandLayout.stationAnchors.keys.compactMap(IslandFraming.stationBox) + IslandFraming.characterBoxes
        for box in boxes {
            let s = span(box, pose, width: size.0)
            #expect(s.lo >= 0)
            #expect(s.hi <= size.0)
        }
    }

    @Test func theStationRowFillsTheWidth() {
        let pose = CameraRail().pose(of: .island)
        let row = span(IslandFraming.stationRow, pose, width: 402)
        #expect(abs(row.lo - IslandFraming.sideMargin) < 1e-6)
        #expect(abs(row.hi - (402 - IslandFraming.sideMargin)) < 1e-6)
        // Larger than round 1's ×1.06.
        #expect(pose.scale > 1.2)
    }

    @Test func theIslandIsCentredBetweenTheBands() {
        let pose = CameraRail().pose(of: .island)
        let island = IslandFraming.islandBox
        let top = pose.anchorY + (island.minY - pose.lookY) * pose.scale
        let bottom = pose.anchorY + (island.maxY - pose.lookY) * pose.scale
        #expect(abs((top + bottom) / 2 - IslandFraming.bandMid(height: 874)) < 1e-6)
        #expect(top >= IslandFraming.topBand)
        #expect(bottom <= 874 - IslandFraming.bottomBand)
        // The plate's proportions cap the island at about half the band.
        let fill = IslandFraming.bandFill(scale: pose.scale, height: 874)
        #expect(fill > 0.5 && fill < 0.7)
    }

    @Test func theMapShowsEveryIslandBetweenTheBands() {
        let rail = CameraRail()
        let pose = rail.pose(of: .map)
        for isle in IslandLayout.isles {
            guard let box = WorldArt.sprite(isle.art)?.sharp else { continue }
            let placed = IslandFraming.placed(box, at: isle.center)
            let s = span(placed, pose, width: 402)
            #expect(s.lo >= 0 && s.hi <= 402, "\(isle.id) is cut off")
            let top = pose.anchorY + (placed.minY - pose.lookY) * pose.scale
            let bottom = pose.anchorY + (placed.maxY - pose.lookY) * pose.scale
            #expect(top >= IslandFraming.topBand && bottom <= 874 - IslandFraming.bottomBand, "\(isle.id) leaves the band")
        }
    }

    // MARK: Focus

    @Test func theCayFocusKeepsPofuWhole() throws {
        let pose = try #require(IslandLayout.stationFocusPose(.cay, width: 402, height: 874, safeTop: 62))
        let pofu = span(IslandFraming.pofuBox, pose, width: 402)
        #expect(pofu.lo >= 0 && pofu.hi <= 402)
        let cay = try #require(IslandFraming.stationBox(.cay))
        let station = span(cay, pose, width: 402)
        #expect(station.lo >= 0 && station.hi <= 402)
    }

    @Test(arguments: [(402.0, 874.0, 0.42), (402.0, 874.0, 132.0 / 874), (375.0, 812.0, 0.42), (440.0, 956.0, 0.42)])
    func noFocusCutsACharacter(case: (Double, Double, Double)) {
        let (width, height, sheet) = `case`
        for station in IslandLayout.stationAnchors.keys.sorted() {
            guard
                let pose = IslandLayout.stationFocusPose(station, width: width, height: height, safeTop: 62, sheetFraction: sheet, maxScale: sheet < 0.3 ? 1.95 : 1.70),
                let focus = IslandFraming.stationBox(station)
            else {
                Issue.record("no pose for \(station)")
                continue
            }
            let target = span(focus, pose, width: width)
            #expect(target.lo >= -1e-6 && target.hi <= width + 1e-6, "\(station) itself is cut")
            for box in IslandFraming.characterBoxes {
                let s = span(box, pose, width: width)
                let whole = s.lo >= -1e-6 && s.hi <= width + 1e-6
                let gone = s.hi <= 1e-6 || s.lo >= width - 1e-6
                #expect(whole || gone, "a character is cut at \(station)'s focus (\(s.lo)…\(s.hi))")
            }
        }
    }

    @Test func keepingWholePrefersMoreCharactersThenLessDrift() {
        let pose = CameraPose(scale: 2, look: WorldPoint(x: 0, y: 0), anchorY: 400)
        let focus = WorldBox(minX: -20, minY: -20, maxX: 20, maxY: 0)
        // A character straddling the left edge: x −110…−90 is −19…21 pt.
        let character = WorldBox(minX: -110, minY: -20, maxX: -90, maxY: 0)
        let kept = IslandFraming.keepingCharactersWhole(pose, focus: focus, subjects: [character], width: 402, margin: 8, maxDrift: 60)
        let lo = 201 + (character.minX - kept.lookX) * 2
        #expect(abs(lo - 8) < 1e-9)
        // With too little drift allowed it leaves the character out.
        let out = IslandFraming.keepingCharactersWhole(pose, focus: focus, subjects: [character], width: 402, margin: 8, maxDrift: 22)
        let hi = 201 + (character.maxX - out.lookX) * 2
        #expect(hi <= 1e-9)
    }

    @Test func aPoseWithNothingCutIsUnchanged() {
        let pose = CameraPose(scale: 1, look: WorldPoint(x: 0, y: 0), anchorY: 400)
        let focus = WorldBox(minX: -20, minY: -20, maxX: 20, maxY: 0)
        let kept = IslandFraming.keepingCharactersWhole(pose, focus: focus, subjects: IslandFraming.characterBoxes, width: 402, maxDrift: 80)
        #expect(kept == pose)
    }

    @Test func theLargePlateRatioIsRecorded() {
        #expect(IslandFraming.largePlateWidthRatio == 1.4)
    }
}
