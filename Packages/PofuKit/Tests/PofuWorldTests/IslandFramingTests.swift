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

    func rows(_ box: WorldBox, _ pose: CameraPose) -> (top: Double, bottom: Double) {
        (pose.anchorY + (box.minY - pose.lookY) * pose.scale, pose.anchorY + (box.maxY - pose.lookY) * pose.scale)
    }

    static let sizes: [(Double, Double)] = [(402.0, 874.0), (375.0, 812.0), (440.0, 956.0)]

    /// The establishing shot (round 3's Island framing): the plate fills
    /// 88 % of the width tip to tip and nothing is cropped.
    @Test(arguments: sizes)
    func theWholeIslandFillsTheWidthWithNothingCropped(size: (Double, Double)) {
        let pose = CameraRail(width: size.0, height: size.1).wholeIslandPose
        let plate = span(IslandFraming.plateBox, pose, width: size.0)
        #expect(plate.lo >= 0 && plate.hi <= size.0, "the plate is cropped: \(plate)")
        let fill = (plate.hi - plate.lo) / size.0
        #expect(fill > 0.85 && fill < 0.90, "the plate fills \(fill) of the width")
    }

    /// Look round 4: the world is not shrunk to fit; Pofu is at least 80 pt
    /// at the Island framing and the camera opens centred on him.
    @Test func theIslandFramingKeepsPofuBig() {
        let pose = CameraRail().pose(of: .island)
        #expect(64 * pose.scale >= 80 - 1e-9)
        let pofu = span(IslandFraming.pofuBox, pose, width: 402)
        #expect(abs((pofu.lo + pofu.hi) / 2 - 201) < 20, "Pofu is not centred: \(pofu)")
    }

    @Test(arguments: sizes)
    func theIslandIsCentredBetweenTheBands(size: (Double, Double)) {
        let pose = CameraRail(width: size.0, height: size.1).pose(of: .island)
        let island = rows(IslandFraming.islandBox, pose)
        let mid = IslandFraming.bandMid(height: size.1)
        // Rows follow the height and scales the width, so other sizes land
        // within a few points of the band's middle.
        #expect(abs((island.top + island.bottom) / 2 - mid) < 6.0)
        #expect(island.top >= IslandFraming.topBand)
        #expect(island.bottom <= size.1 - IslandFraming.bottomBand)
    }

    /// The pan runs tip to tip: at either end the plate's tip meets the
    /// screen's edge, never leaving sky between them.
    @Test func thePanRunsTipToTip() {
        var rig = CameraRig(framing: .island)
        let range = IslandFraming.panRange
        #expect(range.contains(0))
        rig.jumpPan(to: range.lowerBound)
        let left = span(IslandFraming.plateBox, rig.pose, width: 402)
        #expect(abs(left.lo) < 0.5)
        rig.jumpPan(to: range.upperBound)
        let right = span(IslandFraming.plateBox, rig.pose, width: 402)
        #expect(abs(right.hi - 402) < 0.5)
    }

    /// Every station has a snap point that shows it whole.
    @Test func everyStationHasASnapThatShowsItWhole() {
        for (station, anchor) in IslandLayout.stationAnchors {
            var rig = CameraRig(framing: .island)
            rig.jumpPan(to: IslandFraming.panValue(lookX: anchor.x))
            #expect(IslandFraming.panSnaps.contains { abs($0 - IslandFraming.panValue(lookX: anchor.x)) < 0.01 })
            guard let box = IslandFraming.stationBox(station) else { continue }
            let s = span(box, rig.pose, width: 402)
            #expect(s.lo >= 0 && s.hi <= 402, "\(station) is cut at its snap: \(s)")
        }
    }

    @Test func aDragFollowsTheFingerAndBandsPastTheEnds() {
        var rig = CameraRig(framing: .island)
        let s = rig.pose.scale
        rig.panDrag(dx: -40)
        #expect(abs(rig.pan.value - 40 / s) < 1e-9)
        // Far past the end, the band never reaches the panBand.
        rig.panDrag(dx: -4000)
        let over = rig.pan.value - IslandFraming.panRange.upperBound
        #expect(over > 0 && over < CameraRig.panBand / s)
    }

    @Test func aFlickCoastsAndSnapsToAStation() {
        var rig = CameraRig(framing: .island)
        rig.panDrag(dx: -10)
        let target = rig.endPan(velocity: -900)
        #expect(IslandFraming.panSnaps.contains(target))
        #expect(target > rig.pan.value)
        for _ in 0..<600 {
            rig.advance(1.0 / 120)
        }
        #expect(abs(rig.pan.value - target) < 1e-6)
        #expect(rig.isSettled)
    }

    @Test func aReleasePastTheEndLandsOnTheEndWithoutBounce() {
        var rig = CameraRig(framing: .island)
        rig.panDrag(dx: 4000)
        let target = rig.endPan(velocity: 0)
        #expect(abs(target - IslandFraming.panSnaps[0]) < 1e-9)
        // It comes back from past the left end and never swings beyond it.
        #expect(rig.pan.value < target)
        var highest = rig.pan.value
        for _ in 0..<600 {
            rig.advance(1.0 / 120)
            highest = max(highest, rig.pan.value)
        }
        #expect(highest <= target + 1e-6)
    }

    @Test func flyingAwayAndBackOpensOnPofu() {
        var rig = CameraRig(framing: .island)
        rig.jumpPan(to: IslandFraming.panRange.upperBound)
        rig.fly(to: .home)
        rig.fly(to: .island)
        for _ in 0..<600 {
            rig.advance(1.0 / 120)
        }
        #expect(abs(rig.pan.value) < 1e-6)
        // The pan never shows at Home.
        var home = CameraRig(framing: .home)
        home.jumpPan(to: 30)
        #expect(home.panWeight == 0)
    }

    @Test func theMapShowsEveryIslandBetweenTheBands() {
        let rail = CameraRail()
        let pose = rail.pose(of: .map)
        for isle in IslandLayout.isles {
            guard let box = WorldArt.sprite(isle.art)?.sharp else { continue }
            let placed = IslandFraming.placed(box, at: isle.center)
            let s = span(placed, pose, width: 402)
            #expect(s.lo >= 0 && s.hi <= 402, "\(isle.id) is cut off")
            let r = rows(placed, pose)
            #expect(r.top >= IslandFraming.topBand && r.bottom <= 874 - IslandFraming.bottomBand, "\(isle.id) leaves the band")
        }
        let plate = span(IslandFraming.plateBox, pose, width: 402)
        #expect(plate.lo >= 0 && plate.hi <= 402)
    }

    @Test func theNeighboursClearTheLargePlate() {
        let plate = IslandFraming.plateBox
        for isle in IslandLayout.isles {
            guard let box = WorldArt.sprite(isle.art)?.sharp else { continue }
            let placed = IslandFraming.placed(box, at: isle.center)
            let apart = placed.maxX < plate.minX || placed.minX > plate.maxX || placed.maxY < plate.minY || placed.minY > plate.maxY
            #expect(apart, "\(isle.id) overlaps the home plate")
        }
    }

    // MARK: Home

    @Test(arguments: sizes)
    func homeKeepsEveryCharacterWholeOrOut(size: (Double, Double)) {
        let pose = CameraRail(width: size.0, height: size.1).pose(of: .home)
        for box in IslandFraming.characterBoxes {
            let s = span(box, pose, width: size.0)
            let whole = s.lo >= -1e-6 && s.hi <= size.0 + 1e-6
            let gone = s.hi <= 1e-6 || s.lo >= size.0 - 1e-6
            #expect(whole || gone, "a character is cut at Home (\(s.lo)…\(s.hi))")
        }
        let pofu = span(IslandFraming.pofuBox, pose, width: size.0)
        #expect(pofu.lo >= 0 && pofu.hi <= size.0)
    }

    // MARK: Focus

    @Test func theCayFocusKeepsPofuWhole() throws {
        let pose = try #require(IslandLayout.stationFocusPose(.cay, width: 402, height: 874, safeTop: 62))
        let cay = try #require(IslandFraming.stationBox(.cay))
        let station = span(cay, pose, width: 402)
        #expect(station.lo >= 0 && station.hi <= 402)
        for box in IslandFraming.characterBoxes {
            let s = span(box, pose, width: 402)
            #expect((s.lo >= -1e-6 && s.hi <= 402 + 1e-6) || s.hi <= 1e-6 || s.lo >= 402 - 1e-6)
        }
    }

    @Test(arguments: [(402.0, 874.0, 0.42), (402.0, 874.0, 132.0 / 874), (375.0, 812.0, 0.42), (440.0, 956.0, 0.42)])
    func noFocusCutsACharacter(config: (Double, Double, Double)) {
        let (width, height, sheet) = config
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
        let pose = CameraPose(scale: 0.5, look: WorldPoint(x: 0, y: 0), anchorY: 400)
        let focus = WorldBox(minX: -20, minY: -20, maxX: 20, maxY: 0)
        let kept = IslandFraming.keepingCharactersWhole(pose, focus: focus, subjects: IslandFraming.characterBoxes, width: 402, maxDrift: 80)
        #expect(kept == pose)
    }

    // MARK: The far sky

    @Test func theFarSkyLeavesTheMapAndKeepsItsSides() {
        for element in FarSkyLayout.elements {
            #expect(element.placement(z: 0).opacity == 0, "\(element.art) shows on the map")
            let island = element.placement(z: 1), home = element.placement(z: 2)
            // A flight reads as parallax, not a swap: each element keeps its side.
            #expect((island.x - 0.5) * (home.x - 0.5) >= 0, "\(element.art) crosses the screen")
            #expect(WorldArt.sprite(element.art) != nil, "\(element.art) was not baked")
        }
    }

    @Test func theFarSkyFillsTheBandAboveTheIsland() {
        // Something painted sits in the sky band between the top chrome and
        // the island's top at the Island framing, so it is never dead sky.
        let pose = CameraRail().pose(of: .island)
        let top = rows(IslandFraming.islandBox, pose).top / 874
        let inBand = FarSkyLayout.elements.filter { e in
            let p = e.placement(z: 1)
            return p.opacity > 0.5 && p.y > IslandFraming.topBand / 874 && p.y < top
        }
        #expect(inBand.count >= 3)
    }
}
