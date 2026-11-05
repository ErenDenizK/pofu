import Foundation
import Testing
@testable import PofuWorld

@Suite("Home slots (experience v1 §1.4)")
struct HomeSlotsTests {
    private let scale = IslandFraming.homeScale

    /// At the Home framing the world slots project to where the screen
    /// layout drew the objects: Home looks the same.
    @Test func atHomeTheSlotsLandWhereTheScreenLayoutDrewThem() {
        let pose = CameraPose(scale: scale, look: IslandLayout.pofu, anchorY: IslandFraming.homeFeetY)
        let feet = pose.project(IslandLayout.pofu, width: CameraRail.referenceWidth)
        let feetPoint = MomentPoint(x: feet.x, y: feet.y)

        let jar = pose.project(HomeSlots.jar, width: CameraRail.referenceWidth)
        let layoutJar = HomeObjectsLayout.jarCenter(feet: feetPoint, screenWidth: CameraRail.referenceWidth)
        #expect(abs(jar.x - layoutJar.x) < 1e-9 && abs(jar.y - layoutJar.y) < 1e-9)

        let lantern = pose.project(HomeSlots.lantern, width: CameraRail.referenceWidth)
        let layoutLantern = HomeObjectsLayout.lanternCenter(feet: feetPoint, screenWidth: CameraRail.referenceWidth)
        #expect(abs(lantern.x - layoutLantern.x) < 1e-9 && abs(lantern.y - layoutLantern.y) < 1e-9)

        let pots = pose.project(HomeSlots.pots, width: CameraRail.referenceWidth)
        let layoutPots = HomeObjectsLayout.potsCenter(feet: feetPoint)
        #expect(abs(pots.x - layoutPots.x) < 1e-9 && abs(pots.y - layoutPots.y) < 1e-9)
    }

    @Test func theLanternEmitterOffsetMatchesTheSlot() {
        let offset = HomeSlots.lanternEmitterOffset
        #expect(abs(IslandLayout.pofu.x + offset.x - HomeSlots.lantern.x) < 1e-9)
        #expect(abs(IslandLayout.pofu.y + offset.y - HomeSlots.lantern.y) < 1e-9)
        // Right of Pofu and above his feet.
        #expect(offset.x > 0)
        #expect(offset.y < 0)
    }

    @Test func theSlotsStandAroundPofu() {
        #expect(HomeSlots.jar.x < IslandLayout.pofu.x)
        #expect(HomeSlots.lantern.x > IslandLayout.pofu.x)
        #expect(HomeSlots.pots.y > IslandLayout.pofu.y)
    }

    @Test func eachPropHasABoxAroundItsSlot() {
        for prop in HomeSlots.Prop.allCases {
            let box = prop.hitBox
            #expect(abs(box.midX - prop.slot.x) < 1e-9)
            #expect(abs(box.midY - prop.slot.y) < 1e-9)
            #expect(box.width > 0 && box.height > 0)
        }
    }

    @Test func thePropsAreInFrontOfTheLawnBehindThem() {
        for prop in HomeSlots.Prop.allCases {
            #expect(prop.depth > IslandLayout.depth(ofY: IslandLayout.stationAnchors[.windmill]?.y ?? 0))
        }
    }
}
