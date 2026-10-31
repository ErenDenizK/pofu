import Foundation
import Testing
@testable import PofuCompanion

#if canImport(ImageIO)
@Suite("Companion art")
struct CompanionArtTests {
    @Test func placeholderArtShipsInTheBundle() throws {
        let art = try #require(CompanionArt.placeholder)
        #expect(art.base.width == Int(art.rig.pixelWidth))
        #expect(art.base.height == Int(art.rig.pixelHeight))
        let plate = try #require(art.lidPlate)
        #expect(abs(Double(plate.width) - art.rig.lidPlateSize.x * art.rig.pixelWidth) < 1)
        #expect(abs(Double(plate.height) - art.rig.lidPlateSize.y * art.rig.pixelHeight) < 1)
        #expect(art.base.alphaInfo != .none && art.base.alphaInfo != .noneSkipLast)
    }

    @Test func rigLandmarksLieInsideTheArt() {
        let rig = CompanionRig.hamster
        let points = [rig.ground, rig.leftEye.center, rig.rightEye.center, rig.leftCheek, rig.rightCheek, rig.tuftPivot]
        for point in points {
            #expect((0...1).contains(point.x) && (0...1).contains(point.y))
        }
        #expect(rig.leftEye.center.x < rig.rightEye.center.x)
        #expect(rig.ground.y > rig.leftEye.center.y)
    }
}
#endif
