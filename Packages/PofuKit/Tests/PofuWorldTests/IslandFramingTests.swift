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
    /// 88 % of the width tip to tip (home plus İskele) and nothing is cropped.
    @Test(arguments: sizes)
    func theWholeIslandFillsTheWidthWithNothingCropped(size: (Double, Double)) {
        let pose = CameraRail(width: size.0, height: size.1).wholeIslandPose
        let plate = span(IslandFraming.homeAndIsleBox, pose, width: size.0)
        #expect(plate.lo >= 0 && plate.hi <= size.0, "home and İskele are cropped: \(plate)")
        let fill = (plate.hi - plate.lo) / size.0
        #expect(fill > 0.85 && fill < 0.90, "home and İskele fill \(fill) of the width")
    }

    /// Mid (ADR-0027) for the sprite island: its box is 378 pt across at the reference width,
    /// centred on row 416 (moved down from 383 so the island sits in the middle of the screen, brief 2026-11-24-2), scaled with the screen.
    @Test(arguments: sizes)
    func midFitsTheIslandBoxCentredOnItsRow(size: (Double, Double)) {
        let pose = CameraRail(width: size.0, height: size.1).pose(of: .mid)
        let island = span(IslandFraming.islandBox, pose, width: size.0)
        #expect(abs((island.hi - island.lo) - 378 * size.0 / 402) < 1e-6)
        #expect(abs((island.lo + island.hi) / 2 - size.0 / 2) < 1e-6)
        let rows = rows(IslandFraming.islandBox, pose)
        #expect(abs((rows.top + rows.bottom) / 2 - 416 * size.1 / 874) < 1e-6)
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
        let pose = CameraRail(width: size.0, height: size.1).pose(of: .mid)
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

    @Test func theTeaStallFocusKeepsPofuWhole() throws {
        let pose = try #require(IslandLayout.stationFocusPose(.teaStall, width: 402, height: 874, safeTop: 62))
        let teaStall = try #require(IslandFraming.stationBox(.teaStall))
        let station = span(teaStall, pose, width: 402)
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
        let old = IslandFraming.islandStop(width: 402, height: 874)
        let pose = CameraPose(scale: old.scale, look: old.look, anchorY: old.anchorY)
        let top = rows(IslandFraming.islandBox, pose).top / 874
        let inBand = FarSkyLayout.elements.filter { e in
            let p = e.placement(z: 1)
            return p.opacity > 0.5 && p.y > IslandFraming.topBand / 874 && p.y < top
        }
        #expect(inBand.count >= 3)
    }

    @Test func iskeleSitsBesideHomeAndTheWholeShotFramesBoth() throws {
        let harbor = try #require(IslandLayout.isles.first { $0.id == .harbor })
        #expect(harbor.center == WorldPoint(x: 395, y: 14))
        let stop = IslandFraming.wholeStop(width: 402, height: 874)
        let islet = try #require(WorldArt.sprite(harbor.art)?.sharp)
        let box = IslandFraming.placed(islet, at: harbor.center)
        let plate = IslandFraming.plateBox
        for edge in [plate.minX, plate.maxX, box.minX, box.maxX] {
            let x = 201 + (edge - stop.look.x) * stop.scale
            #expect(x >= -0.5 && x <= 402.5, "edge at \(x) pt is off screen")
        }
    }

    @Test func theFourMapIslesAndGezginSitAtTheirSpots() throws {
        let spots: [FarSkyLayout.Mark: (Double, Double, Double)] = [
            .caglayan: (0.17, 0.33, 0.20), .emanet: (0.40, 0.235, 0.12), .mehtap: (0.58, 0.13, 0.09),
            .revontuli: (0.88, 0.37, 0.14), .gezgin: (0.68, 0.225, 0.30),
        ]
        for (mark, spot) in spots {
            let element = try #require(FarSkyLayout.element(for: mark))
            for z in [1.0, 2.0] {
                let p = element.placement(z: z)
                #expect(p.x == spot.0 && p.y == spot.1 && abs(p.width - spot.2 * 402) < 1e-9, "\(mark) at z \(z)")
                #expect(p.opacity == 1)
            }
            #expect(element.placement(z: 0).opacity == 0)
        }
        #expect(!FarSkyLayout.elements.contains { $0.id == "far-isle-1" || $0.id == "far-isle-2" || $0.id == "far-isle-3" })
        let ids = FarSkyLayout.elements.map(\.id)
        #expect(Set(ids).count == ids.count)
        let caglayan = try #require(FarSkyLayout.element(for: .caglayan))
        #expect(caglayan.art(healed: false) != caglayan.art(healed: true))
        #expect(WorldArt.sprite(caglayan.art(healed: true)) != nil)
    }

    @Test func aStuckIsleIsNeverDarkerThanAHealedOne() {
        let stuck = FarSkyLayout.MarkLook.stuck, healed = FarSkyLayout.MarkLook.healed
        #expect(stuck.lightness >= healed.lightness)
        #expect(stuck.lift >= 0)
        #expect(stuck.saturation < healed.saturation)
        #expect(stuck.blur > healed.blur)
    }
}
