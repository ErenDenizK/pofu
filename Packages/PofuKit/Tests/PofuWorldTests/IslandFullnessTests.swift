import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// Fullness (experience v1 §6): cute at every build stage, checked from the
/// layout data alone, and the visitors' slots (§5.3).
@Suite("Island fullness")
struct IslandFullnessTests {
    let catalog = ArchipelagoCatalog.standard
    let levels = 1...10

    // MARK: - The grid

    @Test func theGridCoversTheLawn() {
        let cells = IslandFullness.cells
        #expect(cells.count >= 18, "a 40-unit grid over the 468 × 75 lawn")
        #expect(Set(cells.map(\.row)).count >= 2)
    }

    @Test func noCellOfTheLawnIsBareAtAnyIslandLevel() {
        for level in levels {
            let bare = IslandFullness.bareCells(atLevel: level).map { "(\(Int($0.box.midX)), \(Int($0.box.midY)))" }
            #expect(bare.isEmpty, "IL\(level) leaves bare cells at \(bare)")
        }
    }

    /// The rule has teeth: without dressing and critters the early levels
    /// are bare.
    @Test func theEarlyLawnIsBareWithoutDressing() {
        let holders = IslandFullness.holders(atLevel: 1).filter { !$0.id.hasPrefix("dressing") && !$0.id.hasPrefix("critter") }
        let bare = IslandFullness.cells.filter { cell in !holders.contains { IslandFullness.holds($0, cell) } }
        #expect(bare.count >= 8, "IL1 has only \(bare.count) bare cells without dressing")
    }

    @Test func theNextSlotsSketchStaysWhileItsDressingStands() {
        #expect(IslandFullness.sketchedStation(atLevel: 1) == .teaStall)
        #expect(IslandFullness.sketchedStation(atLevel: 3) == .pond)
        #expect(IslandFullness.sketchedStation(atLevel: 10) == nil)
        #expect(IslandFullness.openStations(atLevel: 1) == [.garden])
    }

    // MARK: - Dressing

    @Test func dressingIsHandPlacedOnTheLawn() {
        let ids = IslandDressing.pieces.map(\.id)
        #expect(Set(ids).count == ids.count)
        for piece in IslandDressing.pieces {
            #expect(piece.levels.lowerBound >= 1 && piece.levels.upperBound <= catalog.maxIslandLevel, "\(piece.id)")
            #expect(IslandFootprint.walkable?.contains(piece.point) ?? true, "\(piece.id) is off the lawn")
        }
        #expect(DressingKind.allCases.allSatisfy { $0.art.hasPrefix("dressing-") })
        #expect(DressingKind.wateringCan.art == "dressing-watering-can")
    }

    @Test func dressingNeverStandsInsideWhatStandsThere() {
        for level in levels {
            let grounds: [(String, WorldPolygon)] =
                IslandFullness.openStations(atLevel: level).compactMap { id in IslandFootprint.ground(of: "\(id)").map { ("\(id)", $0) } }
                + IslandLayout.residents.compactMap { r in IslandFootprint.ground(of: "\(r.id)").map { ("\(r.id)", $0) } }
                + [IslandFootprint.ground(of: "pofu")].compactMap { $0 }.map { ("pofu", $0) }
            for piece in IslandDressing.pieces(atLevel: level) {
                for (owner, ground) in grounds {
                    #expect(!ground.contains(piece.point), "\(piece.id) stands inside \(owner) at IL\(level)")
                }
            }
        }
    }

    /// The dressing waits on its slot and leaves in the reveal's puff: it is
    /// gone from the level the slot opens at.
    @Test func slotDressingLeavesWhenItsSlotOpens() {
        let waiting: [(prefix: String, station: StationID)] = [
            ("tea-ring", .teaStall), ("pond-", .pond), ("workshop-", .workshop), ("windmill-", .windmill),
        ]
        for (prefix, station) in waiting {
            let opens = catalog.station(station)?.opensAt ?? 0
            let owned = IslandDressing.pieces.filter { $0.id.hasPrefix(prefix) }
            #expect(!owned.isEmpty, "\(station) has no dressing")
            for piece in owned {
                #expect(piece.levels == 1...(opens - 1), "\(piece.id) should wait for \(station) (opens at IL\(opens))")
            }
        }
    }

    @Test func eachLevelShowsMoreLifeThanTheOneBeforeItGoesBare() {
        // Nothing ever leaves a level empty-handed: each level keeps pieces.
        for level in levels {
            #expect(IslandDressing.pieces(atLevel: level).count >= 5, "IL\(level)")
        }
    }

    // MARK: - Critters

    @Test func atMostSixCrittersAtOnce() {
        for level in levels {
            let shown = Critters.critters(atLevel: level)
            #expect(shown.count <= Critters.limit, "IL\(level) has \(shown.count)")
            #expect(shown.count >= 3, "IL\(level) needs life in the frame")
        }
    }

    @Test func crittersRestWhereTheyReadInAStillFrame() throws {
        let plate = IslandFraming.plateBox
        for critter in Critters.all {
            switch critter.perch {
            case .dressing(let id):
                let piece = try #require(IslandDressing.piece(id), "\(critter.id) perches on a missing piece")
                #expect(piece.levels.contains(critter.levels.lowerBound) && piece.levels.contains(critter.levels.upperBound), "\(critter.id) outlives \(id)")
                #expect(abs(critter.rest.x - piece.point.x) <= 8 && abs(critter.rest.y - piece.point.y) <= 8, "\(critter.id) is off its perch")
            case .lip:
                #expect(plate.contains(critter.rest), "\(critter.id) is off the plate")
            case .station(let station):
                let opens = try #require(catalog.station(station)).opensAt
                #expect(critter.levels.lowerBound >= opens || station == .garden, "\(critter.id) arrives before \(station)")
                if station != .pond {
                    let box = try #require(IslandFraming.stationBox(station))
                    #expect(box.contains(critter.rest), "\(critter.id) is not on \(station)")
                }
            }
        }
        // The frogs arrive with the pond (IL4).
        #expect(Critters.all.filter { $0.kind == .frog }.allSatisfy { $0.levels.lowerBound == 4 })
    }

    @Test func crittersKeepApart() {
        for level in levels {
            let shown = Critters.critters(atLevel: level)
            for (i, a) in shown.enumerated() {
                for b in shown.dropFirst(i + 1) {
                    #expect(hypot(a.rest.x - b.rest.x, a.rest.y - b.rest.y) >= 12, "\(a.id) and \(b.id) overlap at IL\(level)")
                }
            }
        }
    }

    // MARK: - Visitor slots

    /// V1 on the front lip: on the plate, clear of every station, resident
    /// and Pofu, between the pond (D4) and the harbor's guest spot.
    @Test func theFrontLipSlotStandsOnThePlateAndClearOfEverything() throws {
        let guest = VisitorSlots.footprint.offset(by: VisitorSlots.v1)
        let box = try #require(guest.bounds)
        let plate = IslandFraming.plateBox
        #expect(plate.contains(WorldPoint(x: box.minX, y: box.minY)) && plate.contains(WorldPoint(x: box.maxX, y: box.maxY)))
        for placement in IslandFootprint.placements {
            let ground = placement.footprint.offset(by: placement.anchor)
            #expect(!ground.intersects(guest), "V1 overlaps \(placement.id)")
        }
    }

    @Test func slotsPointWhereTheDesignSays() {
        #expect(VisitorSlots.v1 == WorldPoint(x: -95, y: 36))
        #expect(VisitorSlots.g1 == WorldPoint(x: 398, y: -6))
        #expect(VisitorSlots.h4 == WorldPoint(x: -15, y: 98))
        #expect(VisitorSlots.point(of: .v1) == VisitorSlots.v1)
        #expect(VisitorSlots.point(of: .v2) == nil)
    }

    @Test func theFavouriteStationSlotSitsBesideTheWorker() throws {
        let walkable = try #require(IslandFootprint.walkable)
        for (station, anchor) in IslandLayout.stationAnchors {
            let slot = try #require(VisitorSlots.v2(beside: station))
            #expect(abs(slot.x - anchor.x) == 30, "\(station)")
            #expect(walkable.contains(slot), "\(station)'s guest slot is off the lawn")
        }
        // The harbor's stations have no slot on the home plate.
        #expect(VisitorSlots.v2(beside: .pier) == nil)
        #expect(VisitorSlots.point(for: .v2, favourite: .pier) == VisitorSlots.g1)
        #expect(VisitorSlots.point(for: .v2, favourite: .garden) == VisitorSlots.v2(beside: .garden))
    }
}
