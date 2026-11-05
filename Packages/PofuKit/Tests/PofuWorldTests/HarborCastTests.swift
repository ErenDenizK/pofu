import PofuCore
import Testing
@testable import PofuWorld

@Suite("Harbor cast")
struct HarborCastTests {
    @Test func simitsPoseFollowsJoyThenTheCart() {
        #expect(SimitPose.pose(bagelCartLevel: 0, calmIsFull: false) == .rest)
        #expect(SimitPose.pose(bagelCartLevel: 1, calmIsFull: false) == .work)
        #expect(SimitPose.pose(bagelCartLevel: 3, calmIsFull: true) == .ears)
        #expect(SimitPose.pose(bagelCartLevel: 0, calmIsFull: true) == .ears)
    }

    @Test func simitBeamsAtABusyCartSleepsAtBedtimeAndStartsAtANewCart() {
        #expect(SimitPose.pose(bagelCartLevel: SimitPose.happyCartLevel, calmIsFull: false) == .happy)
        #expect(SimitPose.pose(bagelCartLevel: 2, calmIsFull: false) == .work)
        #expect(SimitPose.pose(bagelCartLevel: 4, calmIsFull: false, isBedtime: true) == .sleepy)
        #expect(SimitPose.pose(bagelCartLevel: 4, calmIsFull: true, isBedtime: true) == .ears)
        #expect(SimitPose.pose(bagelCartLevel: 1, calmIsFull: true, isBedtime: true, isStartled: true) == .surprised)
    }

    @Test func everySimitPoseWasBaked() {
        for pose in SimitPose.allCases {
            #expect(WorldArt.sprite(pose.art) != nil, "\(pose)")
        }
    }

    @Test func theHarborShowsOnlyWhatIsBuilt() {
        #expect(IslandLayout.scenery(on: .harbor, levels: [:]).isEmpty)
        #expect(IslandLayout.scenery(on: .home, levels: [.bagelCart: 3]).isEmpty)
        let cart = IslandLayout.scenery(on: .harbor, levels: [.bagelCart: 3])
        #expect(cart.map(\.id) == ["crates", "station-bagelCart"] || cart.map(\.id) == ["station-bagelCart", "crates"])
        #expect(cart.first { $0.id == "station-bagelCart" }?.art == "bagel-cart-3")
        // Past the last level with art the highest one stands in (the pier and the lighthouse have one).
        let all = IslandLayout.scenery(on: .harbor, levels: [.bagelCart: 5, .pier: 4, .lighthouse: 2])
        #expect(all.first { $0.id == "station-pier" }?.art == "pier-1")
        #expect(all.first { $0.id == "station-lighthouse" }?.art == "lighthouse-1")
        #expect(all.count == 3 + IslandLayout.harborProps.count)
    }

    @Test func theHarborSceneryIsBackToFrontAndBaked() throws {
        let all = IslandLayout.scenery(on: .harbor, levels: [.bagelCart: 1, .pier: 1, .lighthouse: 1])
        #expect(all.map(\.offset.y) == all.map(\.offset.y).sorted())
        for piece in all {
            #expect(WorldArt.sprite(piece.art) != nil, "\(piece.art) was not baked")
        }
    }

    @Test func theHarborStationsStandOnTheLawnOrItsPier() throws {
        let plate = try #require(WorldArt.sprite("harbor-island-s")?.sharp)
        for (station, slot) in IslandLayout.harborStationSlots {
            #expect(plate.minX < slot.x && slot.y < plate.midY, "\(station)")
        }
        // The cast keeps clear of the stations' slots sideways: Simit is in front of the cart, not inside it.
        let simit = try #require(IslandLayout.cast(on: .harbor).first { $0.id == "simit" })
        let cart = try #require(IslandLayout.harborStationSlots[.bagelCart])
        #expect(simit.offset.y > cart.y)
    }

    @Test func theHarborHasItsRealPlateAndBothResidents() {
        let harbor = IslandLayout.isles.first { $0.id == .harbor }
        #expect(harbor?.art == "harbor-island-s")
        #expect(IslandLayout.cast(on: .harbor).map(\.id).sorted() == ["goat", "simit"])
        #expect(IslandLayout.cast(on: .home).isEmpty)
    }

    @Test func everyoneStandsOnThePlate() throws {
        let plate = try #require(WorldArt.sprite("harbor-island-s")?.sharp)
        for member in IslandLayout.cast(on: .harbor) {
            #expect(plate.minX < member.offset.x && member.offset.x < plate.maxX, "\(member.id) is off the plate sideways")
            // The lawn is the plate's upper half; feet above its middle stand on the lawn, not the earth.
            #expect(plate.minY < member.offset.y && member.offset.y < plate.midY, "\(member.id) is not on the lawn")
        }
    }

    @Test func simitsPosesShareOneRegistration() throws {
        let boxes = try SimitPose.allCases.map { try #require(WorldArt.sprite($0.art)?.sharp) }
        for box in boxes {
            // Same canvas and feet: every pose spans the same width, give or take the paws.
            #expect(abs(box.width - boxes[0].width) < 2)
            #expect(abs(box.maxY) < 1, "feet are not on the anchor")
        }
    }
}
