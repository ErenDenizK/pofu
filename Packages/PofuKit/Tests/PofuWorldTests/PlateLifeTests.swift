import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The plate's living layer (game solid v1, PR 6): the visitor's spot on the lawn, the gifts' spots
/// and a build moment's anchors, all computed from the shipped plate's data.
struct PlateLifeTests {
    private func plate() throws -> HomePlate {
        try #require(HomePlate.shipped)
    }

    private func gift() -> VisitorSnapshot {
        VisitorSnapshot(resident: .sumi, reason: .gift, slot: .v1, state: .present, gift: .seeds(3), hearts: 1)
    }

    private func distance(_ a: PlatePoint, _ b: PlatePoint) -> Double {
        hypot(a.x - b.x, a.y - b.y)
    }

    @Test func visitorSpotIsOnTheLawnAndClearOfEveryone() throws {
        let home = try plate()
        let spot = home.plate(PlateLife.visitorSpot(home))
        #expect(PlateMath.contains(home.plate.walkable, spot))
        #expect(home.plate.characters.count >= 3)
        for (name, character) in home.plate.characters {
            #expect(distance(spot, character) >= 40, "\(name)")
        }
    }

    @Test func visitorSpotIsTheFarthestGridPoint() throws {
        let home = try plate()
        let spot = home.plate(PlateLife.visitorSpot(home))
        func clearance(_ p: PlatePoint) -> Double {
            home.plate.characters.values.map { distance($0, p) }.min() ?? 0
        }
        let mine = clearance(spot)
        for p in PlateLife.lawn(home) {
            #expect(clearance(p) <= mine + 1e-6)
        }
        // Deterministic: the same plate gives the same spot.
        #expect(PlateLife.visitorSpot(home) == PlateLife.visitorSpot(home))
    }

    @Test func plateTargetsIncludeTheVisitorAndTheParcel() throws {
        let home = try plate()
        let world = IslandSamples.world(
            clock: nil, tendedDays: 60, levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5],
            jar: .zero, islands: [.home], islandLevel: 10
        )
        let targets = WorldHitTest.plateTargets(home, stations: world.stations, z: 2, visitor: gift())
        let kinds = Set(targets.map(\.kind))
        #expect(kinds.contains(.visitor(.visitor)))
        #expect(kinds.contains(.visitor(.gift)))
        #expect(!kinds.contains(.visitor(.help)))
        // The visitor's box surrounds the spot, the parcel lies beside it.
        let spot = PlateLife.visitorSpot(home)
        let visitorBox = try #require(targets.first { $0.kind == .visitor(.visitor) }).worldBox
        #expect(visitorBox.minX < spot.x && spot.x < visitorBox.maxX)
        #expect(visitorBox.minY < spot.y && spot.y <= visitorBox.maxY)
        let parcelBox = try #require(targets.first { $0.kind == .visitor(.gift) }).worldBox
        #expect(parcelBox.midX != spot.x)
        // A quiet day's letter stands at the same spot.
        let quiet = WorldHitTest.plateTargets(home, stations: world.stations, z: 2, invitationOpen: true)
        #expect(quiet.contains { $0.kind == .visitor(.letter) })
        // Without a visit there is nothing, and on the Archipelago only the islands answer.
        #expect(!WorldHitTest.plateTargets(home, stations: world.stations, z: 2).contains {
            if case .visitor = $0.kind { true } else { false }
        })
        #expect(WorldHitTest.plateTargets(home, stations: world.stations, z: 0.2, visitor: gift()).allSatisfy {
            if case .island = $0.kind { true } else { false }
        })
    }

    @Test func aTapOnTheVisitorOnThePlateFindsThem() throws {
        let home = try plate()
        let world = IslandSamples.world(
            clock: nil, tendedDays: 60, levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5],
            jar: .zero, islands: [.home], islandLevel: 10
        )
        let stop = home.homeStop
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let spot = PlateLife.visitorSpot(home)
        let p = pose.project(WorldPoint(x: spot.x, y: spot.y - 8), width: CameraRail.referenceWidth)
        let hit = WorldHitTest.resolve(
            x: p.x, y: p.y, targets: WorldHitTest.plateTargets(home, stations: world.stations, z: 2, visitor: gift()),
            pose: pose, width: CameraRail.referenceWidth
        )
        #expect(hit?.kind == .visitor(.visitor))
    }

    @Test func noVisitorTargetsAtBedtimeOnThePlate() throws {
        let home = try plate()
        // A stay-over visitor sleeps in the guest room at night: nobody stands on the lawn.
        let stayOver = VisitorSnapshot(resident: .boncuk, reason: .stayOver, slot: .h4, state: .present)
        #expect(PlateLife.visitorTargets(plate: home, visitor: stayOver, invitationOpen: false, isBedtime: true).isEmpty)
        // The parcel waits until morning.
        let parts = PlateLife.visitorTargets(plate: home, visitor: gift(), invitationOpen: false, isBedtime: true).map(\.kind)
        #expect(!parts.contains(.visitor(.gift)))
    }

    @Test func theParcelLiesBesideTheVisitorAwayFromPofu() throws {
        let home = try plate()
        let parts = PlateLife.visitorParts(plate: home, visitor: gift(), invitationOpen: false, isBedtime: false)
        let visitor = try #require(parts.first { $0.part == .visitor })
        let parcel = try #require(parts.first { $0.part == .gift })
        let spot = PlateLife.visitorSpot(home)
        #expect(abs(visitor.feet.x - spot.x) < 1e-9 && abs(visitor.feet.y - spot.y) < 1e-9)
        #expect(abs(abs(parcel.feet.x - visitor.feet.x) - PlateLife.giftReach) < 1e-9)
        #expect(abs(parcel.feet.y - visitor.feet.y - VisitorStage.giftOffset.y) < 1e-9)
        // Pofu is on the other side, and the parcel lies clear of every character.
        let pofu = try #require(home.plate.characters["pofu"])
        let parcelIsRight = home.plate(parcel.feet).x > home.plate(visitor.feet).x
        let pofuIsRight = pofu.x > home.plate(visitor.feet).x
        #expect(parcelIsRight != pofuIsRight)
        for (name, character) in home.plate.characters {
            #expect(distance(home.plate(parcel.feet), character) >= 40, "\(name)")
        }
    }

    @Test func theHelpTargetKeepsItsOffsetFromTheVisitor() throws {
        let home = try plate()
        let help = VisitorSnapshot(resident: .damla, reason: .help, slot: .v1, state: .present)
        let parts = PlateLife.visitorParts(plate: home, visitor: help, invitationOpen: false, isBedtime: false)
        let visitor = try #require(parts.first { $0.part == .visitor })
        let kite = try #require(parts.first { $0.part == .help })
        #expect(abs(kite.feet.x - visitor.feet.x - VisitorStage.helpOffset.x) < 1e-9)
        #expect(abs(kite.feet.y - visitor.feet.y - VisitorStage.helpOffset.y) < 1e-9)
    }

    @Test func giftSpotsLieOnTheLawn() throws {
        let home = try plate()
        let visitor = home.plate(PlateLife.visitorSpot(home))
        let moss = home.plate(try #require(PlateLife.mossSpot(home)))
        #expect(PlateMath.contains(home.plate.walkable, moss))
        for (name, character) in home.plate.characters {
            #expect(distance(moss, character) >= PlateLife.mossClearance, "\(name)")
        }
        #expect(distance(moss, visitor) >= PlateLife.mossClearance)
        // The fountain stands at the top centre of the pond.
        let fountain = try #require(PlateLife.fountainSpot(home))
        let pond = try #require(home.stationBox(.pond))
        #expect(fountain.x == pond.midX)
        #expect(fountain.y == pond.minY)
    }

    @Test func everyHomeStationOnThePlateHasABuildAnchor() throws {
        let home = try plate()
        let stations = Set(home.plate.objects.compactMap(\.station))
        #expect(!stations.isEmpty)
        for station in stations {
            let anchor = try #require(PlateLife.buildAnchor(home, station: station), "\(station)")
            let foot = try #require(PlateLife.buildFoot(home, station: station), "\(station)")
            let box = try #require(home.stationBox(station))
            #expect(anchor.x == box.midX && anchor.y == box.minY)
            #expect(foot.x == box.midX && foot.y == box.maxY)
        }
        // A station the plate does not paint has none.
        #expect(PlateLife.buildAnchor(home, station: .init(rawValue: "nowhere")) == nil)
    }
}
