import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("World map")
struct WorldMapTests {
    let map: WorldMap
    let size = CGSize(width: 402, height: 874)

    init() throws {
        map = try #require(WorldMap.shipped, "the package ships world-map.json")
    }

    /// The screen box of a slot's island at a tier frame, from the stop.
    private func box(_ id: String, tier: Int) throws -> ScreenBox {
        let slot = try #require(map.slot(id))
        let stop = map.tierFrame(tier: tier, size: size)
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let tl = pose.project(WorldPoint(x: slot.center.x - slot.width / 2, y: slot.center.y - slot.height / 2), width: size.width)
        return ScreenBox(minX: tl.x, minY: tl.y, maxX: tl.x + slot.width * pose.scale, maxY: tl.y + slot.height * pose.scale)
    }

    @Test func tierOneScaleIs0_70() {
        #expect(abs(map.tierFrame(tier: 1, size: size).scale - 0.70) <= 0.01)
    }

    @Test func tierTwoScaleIs0_47() {
        #expect(abs(map.tierFrame(tier: 2, size: size).scale - 0.47) <= 0.01)
    }

    @Test func homeIs230PtWideWithItsFootAt0_80() throws {
        let home = try box("home", tier: 1)
        #expect(abs(home.width - 230) <= 2)
        #expect(abs(home.maxY / size.height - 0.80) <= 0.002)
        #expect(abs(home.minY - 520) <= 2)
        #expect(abs(home.maxY - 699) <= 2)
    }

    @Test func kokeAndCaglayanMatchTheV2Table() throws {
        let koke = try box("koke", tier: 1), caglayan = try box("caglayan", tier: 1)
        #expect(abs(koke.width - 174) <= 2)
        // Koke moved 8 units up with the mid row (brief 2026-11-24-2), so its Map box sits about 5 pt higher.
        #expect(abs(koke.minY - 219) <= 2)
        #expect(abs(koke.maxY - 334.4) <= 2)
        #expect(abs(caglayan.width - 148) <= 2)
        #expect(abs(caglayan.minY - 181) <= 2)
        #expect(abs(caglayan.maxY - 286) <= 2)
    }

    @Test func theTierOneConstellationStaysInsideItsFit() throws {
        for id in ["home", "koke", "caglayan"] {
            let b = try box(id, tier: 1)
            #expect(b.minX >= 16 - 0.5 && b.maxX <= 386 + 0.5, "\(id) is between x 16 and 386")
            #expect(b.minY >= 84 - 0.5, "\(id) is below y 84")
        }
    }

    @Test func tierTwoHoldsTheFirstTierAndTheSecond() throws {
        let home = try box("home", tier: 2)
        #expect(abs(home.width - 156) <= 2)
        #expect(abs(home.minY - 577) <= 3 && abs(home.maxY - 699) <= 2)
        let first = [try box("koke", tier: 2), try box("caglayan", tier: 2)]
        #expect(abs((first.map(\.minY).min() ?? 0) - 347) <= 4)
        #expect(abs((first.map(\.maxY).max() ?? 0) - 455) <= 4)
        let second = try ["tier2-a", "tier2-b", "tier2-c"].map { try box($0, tier: 2) }
        #expect(abs((second.map(\.minY).min() ?? 0) - 84) <= 2, "the tier fits to y 84")
    }

    @Test func noNeighbourEntersTheMidFrame() throws {
        // Mid: Home's box fills 378 pt, centred on y 416 (v2 section 1.4).
        let scale = map.midFitWidth / map.home.width
        let pose = CameraPose(scale: scale, look: WorldPoint(x: 0, y: 0), anchorY: map.midCenterY)
        let screen = ScreenBox(minX: 0, minY: 0, maxX: 402, maxY: 874)
        for slot in map.slots where slot.tier > 0 {
            let tl = pose.project(WorldPoint(x: slot.center.x - slot.width / 2, y: slot.center.y - slot.height / 2), width: 402)
            // The box with its name chip below it.
            let chip = (slot.chip?.height ?? map.chipHeight) + map.chipGap
            let b = ScreenBox(minX: tl.x, minY: tl.y, maxX: tl.x + slot.width * scale, maxY: tl.y + slot.height * scale + chip)
            #expect(!b.intersects(screen), "\(slot.id) is out of the mid frame (bottom \(b.maxY))")
        }
    }

    @Test func theTierPitchIsTheSmallestThatKeepsThemOut() {
        // 478 (was 470 at centre row 383; mid moved to 416): the pitch at which Koke's box and chip clear the top edge of mid.
        let scale = map.midFitWidth / map.home.width
        let koke = map.slot("koke")!
        let bottom = map.midCenterY + (koke.center.y + koke.height / 2) * scale + map.chipGap + (koke.chip?.height ?? 0)
        #expect(map.tierPitch == 478)
        #expect(bottom < 0 && bottom > -60, "Koke clears the screen by less than 60 pt: the pitch is not generous")
    }

    @Test func centresAreTheV2Table() {
        #expect(map.center(of: .home) == WorldPoint(x: 0, y: 0))
        #expect(map.center(of: "koke") == WorldPoint(x: -150, y: -478))
        #expect(map.center(of: "caglayan") == WorldPoint(x: 150, y: -540))
        #expect(map.center(of: .harbor) == nil)
        let tier2 = map.slots.filter { $0.tier == 2 }
        #expect(tier2.map(\.center.x) == [-190, 20, 200])
        #expect(tier2.allSatisfy { (-1100 ... -950).contains($0.center.y) })
    }

    @Test func slotsAreNeverEmpty() {
        for stage in 1 ... 3 {
            for slot in map.slots {
                #expect([SlotState.cloud, .veiled, .island].contains(map.state(of: slot.id, stage: stage)), "\(slot.id) holds something at stage \(stage)")
            }
        }
        #expect(map.state(of: "koke", stage: 1) == .veiled && map.state(of: "caglayan", stage: 1) == .cloud)
        #expect(map.state(of: "koke", stage: 2) == .island && map.state(of: "caglayan", stage: 2) == .veiled)
        #expect(map.state(of: "koke", stage: 3) == .island && map.state(of: "caglayan", stage: 3) == .island)
        #expect(map.state(of: "home", stage: 1) == .island)
    }

    @Test func homeBoxMatchesThePlate() throws {
        let plate = try #require(PlateIsland.load("home"))
        let u = map.unitsPerPlatePoint
        #expect(abs((plate.islandBox.maxX - plate.islandBox.minX) * u - map.home.width) <= 1)
        #expect(abs((plate.islandBox.maxY - plate.islandBox.minY) * u - map.home.height) <= 1)
    }

    @Test func horizonAndLanes() {
        #expect(map.horizon == 0.53)
        #expect(map.backdropLane == 350 ... 450)
        for f in map.mapFeatures where f.id != "isle-top" {
            #expect(f.box.minY >= 350 && f.box.maxY <= 450, "\(f.id) sits in the lane")
        }
    }
}
