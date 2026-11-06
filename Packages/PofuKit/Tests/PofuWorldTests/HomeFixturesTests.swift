import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// The doors in the earth face, the hive on the middle lawn and the meadow's
/// painted dressing variants.
@Suite("Home fixtures")
struct HomeFixturesTests {
    @Test func theDoorsOpenWithTheirResidentsSlots() {
        #expect(HomeFixtures.doors(atLevel: 1).isEmpty)
        #expect(HomeFixtures.doors(atLevel: 2).map(\.id) == ["door-mochi"])
        #expect(HomeFixtures.doors(atLevel: 5).map(\.id) == ["door-mochi"])
        #expect(HomeFixtures.doors(atLevel: 6).map(\.id) == ["door-mochi", "door-findik"])
        let catalog = ArchipelagoCatalog.standard
        #expect(HomeFixtures.doors.first { $0.id == "door-mochi" }?.opensAtLevel == catalog.station(.teaStall)?.opensAt)
        #expect(HomeFixtures.doors.first { $0.id == "door-findik" }?.opensAtLevel == catalog.station(.workshop)?.opensAt)
    }

    @Test func theDoorsSitInTheEarthFaceBelowTheLawn() throws {
        let walkable = try #require(IslandFootprint.walkable)
        for door in HomeFixtures.doors {
            // The doors are painted into the plate (batch 60); the slot hangs below the lawn's front edge.
            #expect(!walkable.contains(door.centre), "\(door.id) is on the lawn")
            #expect(door.centre.y > IslandLayout.lawnRadiusY * 0.45, "\(door.id) reaches onto the lawn")
        }
    }

    @Test func theEarthFacePlateFollowsTheIslandLevel() {
        #expect(HomeFixtures.plateStem(islandLevel: 1) == "island-main")
        #expect(HomeFixtures.plateStem(islandLevel: 2) == "island-main-face-il2")
        #expect(HomeFixtures.plateStem(islandLevel: 5) == "island-main-face-il2")
        #expect(HomeFixtures.plateStem(islandLevel: 6) == "island-main-face-il6")
        #expect(IslandLayout.plateBands(islandLevel: 6).map(\.art) == (0..<4).map { "island-main-face-il6-band\($0)" })
        for level in [1, 2, 6] {
            for band in IslandLayout.plateBands(islandLevel: level) {
                #expect(WorldArt.sprite(band.art) != nil, "\(band.art) is baked")
            }
        }
    }

    @Test func theHiveGrowsWithTheIslandThenWithFullBloom() {
        #expect(HomeFixtures.hiveLevel(islandLevel: 8, homeStationsAtTop: true) == 0)
        #expect(HomeFixtures.hiveLevel(islandLevel: 9, homeStationsAtTop: false) == 1)
        #expect(HomeFixtures.hiveLevel(islandLevel: 9, homeStationsAtTop: true) == 1)
        #expect(HomeFixtures.hiveLevel(islandLevel: 10, homeStationsAtTop: false) == 2)
        #expect(HomeFixtures.hiveLevel(islandLevel: 10, homeStationsAtTop: true) == 3)
        #expect(HomeFixtures.hiveArt(level: 0) == nil)
        #expect(HomeFixtures.hiveArt(level: 2) == "hive-2")
        #expect(HomeFixtures.placed(islandLevel: 5, homeStationsAtTop: false).isEmpty)
        #expect(HomeFixtures.placed(islandLevel: 8, homeStationsAtTop: false).map(\.id) == ["lamp-1", "lamp-2", "lamp-3"])
        #expect(HomeFixtures.placed(islandLevel: 10, homeStationsAtTop: true).last?.art == "hive-3")
    }

    @Test func everyFixtureWasBaked() {
        #expect(WorldArt.sprite("path-lamp") != nil)
        for name in HomeFixtures.doors.map(\.art) + (1...HomeFixtures.hiveLevels).compactMap({ HomeFixtures.hiveArt(level: $0) }) {
            #expect(WorldArt.sprite(name) != nil, "missing \(name)")
        }
    }

    /// The hive stands on ground of its own at every level: inside the
    /// lawn, clear of every station at every level, the residents and Pofu.
    @Test func theHiveStandsOnGroundOfItsOwn() throws {
        let slot = HomeFixtures.hiveSlot
        var hive: [WorldPoint] = []
        for level in 1...HomeFixtures.hiveLevels {
            let art = try #require(HomeFixtures.hiveArt(level: level))
            let footprint = IslandFootprint.footprint(of: art)
            #expect(footprint.points.count >= 3, "\(art) has no footprint")
            #expect(IslandFootprint.fits(footprint, at: slot), "\(art) hangs over the rim")
            hive += footprint.points.map { WorldPoint(x: $0.x + slot.x, y: $0.y + slot.y) }
        }
        let ground = WorldPolygon.hull(hive)
        for owner in IslandLayout.stationAnchors.keys.sorted().map({ "\($0)" }) + IslandLayout.residents.map({ "\($0.id)" }) + ["pofu"] {
            guard let other = IslandFootprint.ground(of: owner) else { continue }
            #expect(!ground.intersects(other), "the hive overlaps \(owner)")
        }
    }

    @Test func noDressingStandsInsideTheHive() throws {
        let slot = HomeFixtures.hiveSlot
        var hive: [WorldPoint] = []
        for level in 1...HomeFixtures.hiveLevels {
            let art = try #require(HomeFixtures.hiveArt(level: level))
            hive += IslandFootprint.footprint(of: art).points.map { WorldPoint(x: $0.x + slot.x, y: $0.y + slot.y) }
        }
        let ground = WorldPolygon.hull(hive)
        for piece in IslandDressing.pieces(atLevel: HomeFixtures.hiveOpensAtLevel) {
            #expect(!ground.contains(piece.point), "\(piece.id) stands inside the hive")
        }
    }

    // MARK: Meadow variants

    @Test func theMeadowSheetIsCutIntoTwelveBakedPieces() {
        var names = Set<String>()
        for kind in DressingKind.allCases where kind.family == .meadow {
            for variant in 0..<kind.variantCount {
                names.insert(kind.art(variant: variant))
            }
        }
        #expect(names.count == 12)
        for name in names {
            #expect(WorldArt.sprite(name) != nil, "missing \(name)")
        }
    }

    @Test func variantNamesFollowTheSheetsNumbering() {
        #expect(DressingKind.grassTuft.art == "dressing-grass-tuft")
        #expect(DressingKind.grassTuft.art(variant: 1) == "dressing-grass-tuft-2")
        #expect(DressingKind.mushroomRing.art(variant: 3) == "dressing-mushroom-ring")
        #expect(DressingKind.pebbles.art(variant: -1) == "dressing-pebbles-3")
    }

    @Test func everyMeadowPieceOfTheSheetIsOnTheLawn() {
        let worn = Set(IslandDressing.pieces.filter { $0.kind.family == .meadow }.map(\.art))
        // Every painted variant shows somewhere (the sheet is for the lawn).
        #expect(worn.count == 12, "the lawn shows \(worn.count) of 12 meadow pieces")
    }

    // MARK: Garden and harbor dressing

    @Test func theGardenAndHarborSheetsAreBakedAndWorn() {
        let worn = IslandDressing.pieces.filter { $0.kind.family != .meadow }
        #expect(!worn.isEmpty)
        for piece in worn {
            #expect(WorldArt.sprite(piece.art) != nil, "\(piece.id) wears \(piece.art), which is not baked")
        }
        // The crate has both of the garden sheet's poses.
        #expect(DressingKind.crate.variantCount == 2)
        #expect(DressingKind.crate.art(variant: 1) == "dressing-crate-2")
        #expect(Set(worn.map(\.art)).count == 8, "the lawn wears every baked garden and harbor piece")
    }
}
