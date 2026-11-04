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
