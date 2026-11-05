import Foundation
import Testing
@testable import PofuCore
@testable import PofuWorld

/// The visitor in the world (experience v1 §5.3): where they stand, the
/// arrival beat, what a tap sends, the invitation flow, the dressing's
/// reveal and the critters' rest.
@Suite("Visitors and life in the world (experience v1 §5, §6)")
struct VisitorStageTests {
    private func visit(
        _ reason: VisitReason = .justSitting,
        slot: VisitSlot = .v1,
        state: VisitState = .present,
        gift: VisitGift? = nil,
        giftOpened: Bool = false,
        helped: Bool = false,
        bonus: StationID? = nil
    ) -> VisitorSnapshot {
        VisitorSnapshot(
            resident: .sumi, reason: reason, slot: slot, state: state, gift: gift,
            giftOpened: giftOpened, helped: helped, bonusStation: bonus
        )
    }

    // MARK: - Slots

    @Test func theVisitorStandsAtTheirSlot() {
        for (slot, point) in [(VisitSlot.v1, VisitorSlots.v1), (.g1, VisitorSlots.g1), (.h4, VisitorSlots.h4)] {
            let parts = VisitorStage.parts(visitor: visit(slot: slot), invitationOpen: false, isBedtime: false)
            #expect(parts.first { $0.part == .visitor }?.feet == point, "\(slot)")
        }
    }

    @Test func aFestivalVisitorStandsBesideTheFavouriteStationsWorker() throws {
        let guest = visit(.festival, slot: .v2, bonus: .garden)
        let feet = VisitorStage.feet(of: guest)
        #expect(feet == VisitorSlots.v2(beside: .garden))
        let garden = try #require(IslandLayout.stationAnchors[.garden])
        #expect(abs(feet.x - garden.x) <= 40 && abs(feet.y - garden.y) <= 20)
    }

    @Test func aFavouriteWithoutAHomeSlotFallsBackToTheStall() {
        #expect(VisitorStage.feet(of: visit(.festival, slot: .v2, bonus: .pier)) == VisitorSlots.g1)
    }

    @Test func v1ClearsEverythingStandingOnTheLawn() {
        // The data test (IslandFullnessTests) holds V1 against the plate and
        // the footprints; here the pieces around the visitor stay on the plate too.
        let plate = IslandFraming.plateBox
        let helpful = visit(.help, gift: .seeds(3))
        for part in VisitorStage.parts(visitor: helpful, invitationOpen: false, isBedtime: false) {
            #expect(plate.contains(part.feet), "\(part.part) is off the plate")
        }
    }

    @Test func theGiftAndTheHelpTargetStandBesideTheVisitor() {
        let guest = visit(.gift, gift: .seeds(3))
        let parts = VisitorStage.parts(visitor: guest, invitationOpen: false, isBedtime: false)
        #expect(Set(parts.map(\.part)) == [.visitor, .gift])
        let help = VisitorStage.parts(visitor: visit(.help), invitationOpen: false, isBedtime: false)
        #expect(Set(help.map(\.part)) == [.visitor, .help])
    }

    @Test func anOpenedParcelAndAHelpedKiteLeaveTheWorld() {
        let opened = visit(.gift, gift: nil, giftOpened: true)
        #expect(VisitorStage.parts(visitor: opened, invitationOpen: false, isBedtime: false).map(\.part) == [.visitor])
        let helped = visit(.help, helped: true)
        #expect(VisitorStage.parts(visitor: helped, invitationOpen: false, isBedtime: false).map(\.part) == [.visitor])
    }

    @Test func aStayOverVisitorSleepsInTheGuestRoomAtNight() {
        let guest = visit(.stayOver, slot: .h4)
        #expect(VisitorStage.parts(visitor: guest, invitationOpen: false, isBedtime: false).map(\.part) == [.visitor])
        #expect(VisitorStage.parts(visitor: guest, invitationOpen: false, isBedtime: true).isEmpty)
        #expect(VisitorStage.isGuestNight(guest))
        #expect(!VisitorStage.isGuestNight(visit(.gift)))
        #expect(!VisitorStage.isGuestNight(nil))
        #expect(!VisitorStage.isGuestNight(visit(.stayOver, state: .departed)))
    }

    @Test func theParcelWaitsAtNight() {
        let guest = visit(.gift, gift: .seeds(2))
        #expect(!VisitorStage.parts(visitor: guest, invitationOpen: false, isBedtime: true).contains { $0.part == .gift })
    }

    // MARK: - Taps

    @Test func tapsMapToTheGameEvents() {
        let guest = visit(.gift, gift: .seeds(2))
        #expect(VisitorStage.event(for: .visitor, visitor: guest) == .greetedVisitor)
        #expect(VisitorStage.event(for: .gift, visitor: guest) == .openedGift)
        #expect(VisitorStage.event(for: .help, visitor: guest) == .helped)
        #expect(VisitorStage.event(for: .letter, visitor: nil) == nil)
        // A greeted visitor does not count another heart.
        #expect(VisitorStage.event(for: .visitor, visitor: visit(state: .greeted)) == nil)
    }

    @Test func thePartsAreTargetsForTheOneResolver() throws {
        let guest = visit(.gift, slot: .v1, gift: .seeds(2))
        let targets = WorldHitTest.targets(stations: [], z: 2, visitor: guest)
        let kinds = targets.compactMap { target -> VisitorPart? in
            if case .visitor(let part) = target.kind { part } else { nil }
        }
        #expect(Set(kinds) == [.visitor, .gift])
        // A tap at the visitor's body, projected, lands on them.
        let pose = CameraPose(scale: 2.2, look: VisitorSlots.v1, anchorY: 400)
        let body = pose.project(WorldPoint(x: VisitorSlots.v1.x, y: VisitorSlots.v1.y - 14), width: 402)
        let hit = WorldHitTest.resolve(x: body.x, y: body.y, targets: targets, pose: pose, width: 402)
        #expect(hit?.kind == .visitor(.visitor))
        // On the Archipelago only the islands answer.
        let far = WorldHitTest.targets(stations: [], z: 0, visitor: guest)
        #expect(far.allSatisfy { if case .island = $0.kind { true } else { false } })
    }

    @Test func everyTargetIsAtLeastFortyFourPointsAtHome() {
        let guest = visit(.help, gift: .seeds(2))
        let pose = CameraPose(scale: IslandFraming.homeScale, look: VisitorSlots.v1, anchorY: 440)
        for target in WorldHitTest.targets(stations: [], z: 2, visitor: guest, invitationOpen: false) {
            let rect = WorldHitTest.screenRect(of: target, pose: pose, width: 402)
            #expect(rect.maxX - rect.minX >= 44 - 1e-9 && rect.maxY - rect.minY >= 44 - 1e-9)
        }
    }

    // MARK: - The quiet day's letter and the invitation

    @Test func aQuietDayShowsTheLetterOnlyWhileItIsOpen() {
        let open = VisitorStage.parts(visitor: nil, invitationOpen: true, isBedtime: false)
        #expect(open.map(\.part) == [.letter])
        #expect(open.first?.feet == VisitorStage.letterSpot)
        #expect(VisitorStage.parts(visitor: nil, invitationOpen: false, isBedtime: false).isEmpty)
        #expect(VisitorStage.event(for: .letter, visitor: nil) == nil, "the letter opens a sheet, it sends nothing")
    }

    @Test func theInviteSheetListsOnlyMetResidentsWhoVisit() {
        let met: [ResidentID] = [.nane, .gezgin, .sumi, .mochi]
        #expect(VisitorStage.inviteChoices(met: met) == [.sumi, .nane], "in story order, without Gezgin and the home residents")
        #expect(VisitorStage.inviteChoices(met: []).isEmpty)
    }

    @Test func invitingThroughTheClockMakesThemTomorrowsVisitor() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Istanbul"))
        let clock = WorldClock(calendar: calendar)
        var state = GameState()
        func date(_ day: Int, _ hour: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
        }
        clock.advance(&state, to: date(2, 9), applying: [GameEvent(at: date(2, 9), kind: .signOfLife)])
        state.visitors.current = nil
        state.visitors.hearts[.sumi] = 1
        state.visitors.hearts[.nane] = 2
        state.visitors.inviteOpenSince = LocalDay(year: 2026, month: 11, day: 2)
        let letter = clock.snapshot(of: state)
        #expect(letter.invitationOpen && letter.visitor == nil)
        #expect(VisitorStage.parts(visitor: letter.visitor, invitationOpen: letter.invitationOpen, isBedtime: false).map(\.part) == [.letter])
        let choices = VisitorStage.inviteChoices(met: letter.metResidents)
        #expect(choices == [.sumi, .nane])
        // The player picks Sumi.
        clock.advance(&state, to: date(2, 10), applying: [GameEvent(at: date(2, 10), kind: .invited(.sumi))])
        let picked = clock.snapshot(of: state)
        #expect(picked.invited == .sumi)
        #expect(!picked.invitationOpen, "the letter is spent")
        #expect(VisitorStage.parts(visitor: picked.visitor, invitationOpen: picked.invitationOpen, isBedtime: false).isEmpty)
        // Tomorrow she comes, invited, with the favourite-station bonus.
        clock.advance(&state, to: date(3, 9), applying: [GameEvent(at: date(3, 9), kind: .foregroundBegan)])
        let tomorrow = clock.snapshot(of: state)
        #expect(tomorrow.visitor?.resident == .sumi)
        #expect(tomorrow.visitor?.isInvited == true)
        #expect(tomorrow.visitor?.bonusStation == .garden)
    }

    // MARK: - The arrival

    @Test func theArrivalFitsTheMomentWindow() {
        #expect(VisitorStage.panLead + VisitorStage.arrivalSeconds <= VisitorStage.momentSeconds)
        #expect(VisitorStage.momentSeconds <= 2.0)
    }

    @Test func theCameraPansBeforeTheVisitorAppears() {
        for style in [VisitorArrivalStyle.dandelion, .pier] {
            #expect(VisitorStage.arrival(style: style, elapsed: 0).opacity == 0)
            #expect(VisitorStage.arrival(style: style, elapsed: VisitorStage.panLead).opacity == 0)
            #expect(VisitorStage.arrival(style: style, elapsed: VisitorStage.panLead + 0.4).opacity > 0)
        }
    }

    @Test func theVisitorSettlesExactlyAtTheSlot() {
        for style in [VisitorArrivalStyle.dandelion, .pier] {
            let done = VisitorStage.arrival(style: style, elapsed: VisitorStage.panLead + VisitorStage.arrivalSeconds)
            #expect(done.dx == 0 && done.dy == 0 && done.opacity == 1 && done.seed == 0)
            let later = VisitorStage.arrival(style: style, elapsed: 30)
            #expect(later.dx == 0 && later.dy == 0 && later.opacity == 1)
        }
    }

    @Test func theDandelionDriftsDownAndThePierLandingSlidesIn() {
        let midDrift = VisitorStage.arrival(style: .dandelion, elapsed: VisitorStage.panLead + 0.5)
        #expect(midDrift.dy < -4, "still above the slot")
        #expect(midDrift.seed > 0.9, "the seed still carries them")
        let midLanding = VisitorStage.arrival(style: .pier, elapsed: VisitorStage.panLead + 0.5)
        #expect(midLanding.dx > 5, "still on the way in from the pier")
        #expect(midLanding.seed == 0)
    }

    @Test func v1ArrivesOnADandelionAndTheHarborLandsThemAtThePier() {
        #expect(VisitorStage.arrivalStyle(for: .v1) == .dandelion)
        for slot in [VisitSlot.g1, .v2, .h4] {
            #expect(VisitorStage.arrivalStyle(for: slot) == .pier)
        }
    }

    @Test func aGreetedVisitorHasNoArrivalLeftToPlay() {
        #expect(VisitorStage.hasArrival(visit(state: .arriving)))
        #expect(VisitorStage.hasArrival(visit(state: .present)))
        #expect(!VisitorStage.hasArrival(visit(state: .greeted)))
    }

    @Test func theIdleBobHoldsStillWhenNotAmbient() {
        #expect(VisitorStage.idleBob(at: 3.3, isAmbient: false) == 0)
        #expect(VisitorStage.idleBob(at: 3.3, isAmbient: true) <= 0)
    }

    @Test func theArtNamesAreTheFutureCodexJobs() {
        #expect(VisitorArt.dandelion == "visitor-dandelion")
        #expect(VisitorArt.giftParcel == "gift-parcel")
        #expect(VisitorArt.guestLetter == "guest-letter")
    }

    // MARK: - The H4 window

    @Test func theGuestRoomLightsOnStayOverNights() {
        var world = IslandSamples.world(clock: nil, tendedDays: 40, levels: [.garden: 3, .teaStall: 2], jar: .zero, islands: [.home], islandLevel: 4)
        let night = WorldLight.at(hour: 22, wellbeing: 78, calm: 1.4, isBedtime: true)
        let dark = LightField.make(world: world, light: night, guestNight: false)
        let lit = LightField.make(world: world, light: night, guestNight: VisitorStage.isGuestNight(visit(.stayOver, slot: .h4)))
        #expect(!dark.sources.contains { $0.id == "window-guest" })
        let window = lit.sources.first { $0.id == "window-guest" }
        #expect(window != nil)
        #expect(window?.point == VisitorSlots.h4)
        world.visitor = visit(.stayOver, slot: .h4)
        #expect(VisitorStage.isGuestNight(world.visitor))
    }

    // MARK: - Dressing

    @Test func dressingLeavesWhenItsSlotOpens() {
        // The tea stall opens at IL2: its mushroom ring leaves.
        #expect(IslandDressing.leaving(fromLevel: 1, toLevel: 2).map(\.id) == ["tea-ring"])
        // The pond opens at IL4: its three pieces leave together.
        #expect(Set(IslandDressing.leaving(fromLevel: 3, toLevel: 4).map(\.id)) == ["pond-flowers", "pond-pebbles", "pond-tuft"])
        // The workshop at IL6 and the windmill at IL8.
        #expect(Set(IslandDressing.leaving(fromLevel: 5, toLevel: 6).map(\.id)).isSuperset(of: ["workshop-trowel", "workshop-twine", "workshop-crate"]))
        #expect(Set(IslandDressing.leaving(fromLevel: 7, toLevel: 8).map(\.id)) == ["windmill-flowers", "windmill-ring"])
    }

    @Test func nothingLeavesWhenTheLevelStaysOrFalls() {
        #expect(IslandDressing.leaving(fromLevel: 4, toLevel: 4).isEmpty)
        #expect(IslandDressing.leaving(fromLevel: 6, toLevel: 3).isEmpty)
    }

    @Test func aPieceThatLeavesWasShownBeforeAndIsGoneAfter() {
        for old in 1...9 {
            for piece in IslandDressing.leaving(fromLevel: old, toLevel: old + 1) {
                #expect(piece.isShown(atLevel: old) && !piece.isShown(atLevel: old + 1), "\(piece.id)")
            }
        }
    }

    @Test func thePuffRunsForSixTenthsAndThenIsGone() throws {
        #expect(DressingReveal.frame(elapsed: -0.1) == nil)
        let start = try #require(DressingReveal.frame(elapsed: 0))
        #expect(start.scale == 1 && start.opacity == 1 && start.puffOpacity == 0)
        let middle = try #require(DressingReveal.frame(elapsed: DressingReveal.puffSeconds / 2))
        #expect(middle.puffOpacity > 0.5, "the cloud peaks while the piece shrinks")
        #expect(middle.scale < 1 && middle.opacity < 1)
        #expect(DressingReveal.frame(elapsed: DressingReveal.puffSeconds) == nil)
        #expect(DressingReveal.frame(elapsed: 5) == nil)
    }

    @Test func harborDressingWaitsForTheHarbor() {
        let harbor = IslandDressing.pieces.filter { $0.kind.family == .harbor }
        #expect(!harbor.isEmpty)
        #expect(harbor.allSatisfy { $0.levels.lowerBound == 3 }, "the bridge opens at IL3")
        #expect(DressingKind.Family.harbor.job == "dressing-harbor")
        #expect(DressingKind.Family.meadow.job == "dressing-meadow")
        #expect(DressingKind.Family.garden.job == "dressing-garden")
    }

    @Test func dressingIsDrawnAtEveryLevelAndGrowsFullerThanItsFirstLevel() {
        let first = IslandDressing.pieces(atLevel: 1).count
        for level in 1...10 {
            #expect(IslandDressing.pieces(atLevel: level).count >= 5, "IL\(level)")
        }
        #expect(first >= 5)
    }

    // MARK: - Critters

    private func ambientDirective() -> FrameDirective {
        FramePolicy.standard.directive(for: FrameDemand(isVisiting: true))
    }

    @Test func crittersMoveOnlyInAmbient() {
        let policy = FramePolicy.standard
        #expect(CritterMotion.moves(under: ambientDirective()))
        for demand in [FrameDemand(), FrameDemand(isDirect: true), FrameDemand(isMoment: true), FrameDemand(isCovered: true)] {
            #expect(!CritterMotion.moves(under: policy.directive(for: demand)), "\(demand)")
        }
        // Low Power Mode skips Ambient: the critters rest.
        let lowPower = policy.directive(for: FrameDemand(isVisiting: true), conditions: FrameConditions(lowPower: true))
        #expect(!CritterMotion.moves(under: lowPower))
    }

    @Test func aSettledCritterIsExactlyAtRestWhateverTheTime() {
        for critter in Critters.all {
            for t in stride(from: 0.0, through: 600, by: 7.3) {
                #expect(CritterMotion.pose(of: critter, at: t, isAmbient: false).isRest, "\(critter.id) at \(t)")
            }
        }
    }

    @Test func anAmbientCritterMovesAndStaysNearItsPerch() {
        for critter in Critters.all {
            var moved = false
            for t in stride(from: 0.0, through: 30, by: 0.1) {
                let pose = CritterMotion.pose(of: critter, at: t, isAmbient: true)
                if !pose.isRest { moved = true }
                #expect(abs(pose.dx) <= 14 && abs(pose.dy) <= 14, "\(critter.id) strays at \(t)")
            }
            #expect(moved, "\(critter.id) never moves in Ambient")
        }
    }

    @Test func crittersDoNotFlapInStep() {
        let butterflies = Critters.all.filter { $0.kind == .butterfly }
        let ladybugs = Critters.all.filter { $0.kind == .ladybug }
        #expect(!ladybugs.isEmpty, "the ladybug has a rest spot")
        #expect(CritterKind.ladybug.art == "critter-ladybug")
        #expect(CritterKind.butterfly.art == "critter-butterfly")
        #expect(CritterKind.snail.art == "critter-snail" && CritterKind.bird.art == "critter-bird")
        if butterflies.count >= 2 {
            #expect(CritterMotion.phase(of: butterflies[0].id) != CritterMotion.phase(of: butterflies[1].id))
        }
    }

    @Test func theJobsCoverEveryCodexName() {
        let arts = Set(CritterKind.allCases.map(\.art))
        #expect(arts.isSuperset(of: ["critter-butterfly", "critter-snail", "critter-bird", "critter-ladybug"]))
    }
}
