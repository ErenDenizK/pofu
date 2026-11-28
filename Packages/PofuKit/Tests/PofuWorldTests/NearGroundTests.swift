import Foundation
import Testing
@testable import PofuWorld

@Suite("Near ground (plan row 3a)")
struct NearGroundTests {
    private var near: PlateNear {
        get throws { try #require(HomePlate.shipped?.plate.near, "plate-home.json carries near") }
    }

    @Test func theGroundIsDataNotCode() throws {
        let near = try near
        let patch = try #require(near.patch)
        #expect(patch.rows.count == 4 && patch.rows == patch.rows.sorted())
        #expect(patch.maskBox.count == 4)
        let strip = try #require(near.foreground)
        #expect(strip.count >= 3)
        #expect(!near.dressing.isEmpty)
    }

    @Test func theStripCoversTheEarthFace() throws {
        let near = try near
        let strip = try #require(near.foreground)
        // Its soft top lies over the lawn: it starts above the lip, and its body reaches the island's bottom.
        #expect(strip.top < near.lipRow)
        #expect(strip.top + strip.height >= 1240)
        // The copies cover the island's width.
        #expect(strip.x <= 0 && strip.x + strip.width * Double(strip.count) >= 1024)
    }

    @Test func theDressingStandsOnTheLawn() throws {
        let near = try near
        let rows = try #require(near.patch?.rows)
        for piece in near.dressing {
            #expect(piece.at.count == 2 && piece.at[1] == piece.footY)
            #expect(piece.width > 0 && piece.height > 0 && piece.shadow > 0, "\(piece.art) casts a shadow")
            // Inside the band the focal ground covers, never the soft foreground.
            #expect(piece.footY > rows[0] && piece.footY < rows[3], "\(piece.art) stands in the band")
        }
    }

    @Test func theGroundFadesInWithTheCameraScale() {
        #expect(nearGroundShare(scale: 1.145, fadeIn: [3.2, 4.2]) == 0)
        #expect(nearGroundShare(scale: 2.6, fadeIn: [3.2, 4.2]) == 0)
        #expect(nearGroundShare(scale: 4.5, fadeIn: [3.2, 4.2]) == 1)
        let mid = nearGroundShare(scale: 3.7, fadeIn: [3.2, 4.2])
        #expect(mid > 0 && mid < 1)
        #expect(nearGroundShare(scale: 5, fadeIn: []) == 0)
    }

    @Test func everyAssetItNamesShips() throws {
        let near = try near
        let assets = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../Sources/PofuWorld/Resources/World.xcassets").standardized
        var names = [near.patch?.detail, near.foreground?.art].compactMap { $0 } + near.dressing.map(\.art)
        names += (0..<10).map { "\(near.patch?.mask ?? "")-\($0)" } + ["\(near.patch?.mask ?? "")-autumn-0"]
        for name in names {
            let heic = assets.appendingPathComponent("\(name).imageset/\(name).heic")
            #expect(FileManager.default.fileExists(atPath: heic.path), "\(name) is in World.xcassets")
        }
    }
}
