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

#if canImport(SwiftUI)
@Suite("Companion stage layout")
struct CompanionStageLayoutTests {
    let rig = CompanionRig.hamster

    @Test func feetAreTheScaleAnchor() {
        let layout = CompanionStageLayout(width: 360, rig: rig)
        let paddedHeight = layout.artHeight + 2 * layout.padding
        let paddedWidth = layout.artWidth + 2 * layout.padding
        #expect(abs(layout.groundAnchorY * paddedHeight - layout.groundYInPaddedFigure) < 1e-9)
        #expect(abs(layout.groundAnchorX * paddedWidth - (layout.padding + rig.ground.x * layout.artWidth)) < 1e-9)
    }

    @Test func stageLeavesHeadroomForTheHop() {
        let layout = CompanionStageLayout(width: 360, rig: rig)
        let stageHeight = 360 / CompanionStageLayout.aspectRatio(for: rig)
        // The highest hop (a fifth of the art height) must stay on stage.
        #expect(layout.artOriginY >= 0.2 * layout.artHeight)
        #expect(layout.groundY < stageHeight)
        #expect(abs(layout.figureCenter.x - 180) < 1e-9)
    }

    @Test func restingHeadroomIsTheRoomAboveTheArt() throws {
        let art = try #require(CompanionArt.placeholder)
        let layout = CompanionStageLayout(width: 300, rig: art.rig)
        let headroom = Double(CompanionView.restingHeadroom(forWidth: 300, art: art))
        #expect(headroom > 0)
        #expect(abs(headroom - layout.artOriginY) < 1e-9)
        #expect(CompanionView.restingHeadroom(forWidth: 300, art: nil) == 0)
    }

    @Test(arguments: [0.0, -10, .nan, .infinity])
    func degenerateWidthsDoNotProduceNaN(width: Double) {
        let layout = CompanionStageLayout(width: width, rig: rig)
        #expect(layout.groundAnchorX.isFinite && layout.groundAnchorY.isFinite)
        #expect(layout.artWidth.isFinite)
    }
}
#endif
