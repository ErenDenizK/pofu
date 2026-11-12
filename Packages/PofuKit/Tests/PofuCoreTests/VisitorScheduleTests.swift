import Foundation
import Testing
@testable import PofuCore

/// The visiting day (experience v1 §5): one visitor a day with a reason,
/// the weekday as a weighting, invitations on quiet days, and the postcard
/// before any island is healed.
@Suite("Visitor schedule")
struct VisitorScheduleTests {
    let schedule = VisitorSchedule()
    let allHealed = VisitorSchedule.Context(
        healed: Set(VisitorSchedule.standardRoster.map(\.island)),
        islandLevel: 8,
        built: [.garden, .teaStall, .pond, .workshop, .windmill, .pier, .lighthouse, "hive"]
    )
    let monday = LocalDay(year: 2026, month: 11, day: 2)

    /// Rolls `days` days, the player opening Pofu every day.
    func simulate(days: Int, context: VisitorSchedule.Context, seed: UInt64 = 7, from start: LocalDay? = nil, answeringLetters: Bool = false) -> [(LocalDay, DailyVisit?)] {
        var ledger = VisitorLedger(seed: seed)
        var out: [(LocalDay, DailyVisit?)] = []
        for offset in 0..<days {
            let day = (start ?? monday).adding(days: offset)
            schedule.roll(&ledger, to: day, context: context)
            ledger.noteSeen()
            if answeringLetters {
                ledger.greet()
                if ledger.inviteOpenSince != nil, let guest = ledger.met.first {
                    ledger.invite(guest, on: day)
                }
            }
            out.append((day, ledger.current?.day == day ? ledger.current : nil))
        }
        return out
    }

    // MARK: - The calendar

    @Test func weekdaysAreRight() {
        #expect(VisitorSchedule.weekday(of: LocalDay(year: 1970, month: 1, day: 1)) == 3)  // Thursday
        #expect(VisitorSchedule.weekday(of: monday) == 0)
        #expect(VisitorSchedule.weekday(of: LocalDay(year: 2026, month: 11, day: 8)) == 6)
        #expect(VisitorSchedule.weekday(of: LocalDay(year: 2028, month: 2, day: 29)) == 1)  // Tuesday
    }

    // MARK: - Determinism and weighting

    @Test func theScheduleIsDeterministic() {
        let a = simulate(days: 200, context: allHealed)
        let b = simulate(days: 200, context: allHealed)
        #expect(a.map(\.1) == b.map(\.1))
        let other = simulate(days: 200, context: allHealed, seed: 8)
        #expect(a.map(\.1) != other.map(\.1))
    }

    @Test func thePureDrawMatchesTheRoll() {
        var state = GameState()
        state.visitors.seed = 99
        let day = LocalDay(year: 2026, month: 11, day: 5)
        let peek = schedule.visit(for: day, state: state, seed: 99)
        #expect(peek == schedule.visit(for: day, state: state, seed: 99))
        #expect(state.visitors.current == nil)
        #expect(peek?.resident == .gezgin)
    }

    @Test func theWeekdayWeightsButNeverRules() {
        let runs = simulate(days: 10_000, context: allHealed)
        var own = 0, total = 0
        var weekdaysSeen: [ResidentID: Set<Int>] = [:]
        for (day, visit) in runs {
            guard let visit else { continue }
            let weekday = VisitorSchedule.weekday(of: day)
            total += 1
            if schedule.roster.first(where: { $0.resident == visit.resident })?.weekday == weekday { own += 1 }
            weekdaysSeen[visit.resident, default: []].insert(weekday)
        }
        let share = Double(own) / Double(total)
        // 6 : 1 against six others is about one in two; unweighted it
        // would be one in seven.
        #expect(share > 0.40 && share < 0.60, "own-day share \(share)")
        // Any healed island's resident may come on any day.
        for profile in schedule.roster {
            #expect(weekdaysSeen[profile.resident]?.count == 7, "\(profile.resident) skipped a weekday")
        }
    }

    @Test func heartsNudgeTheWeightGently() {
        var ledger = VisitorLedger(seed: 3)
        ledger.hearts[.sumi] = 10
        var heart = 0, plain = 0
        for offset in 0..<6_000 {
            let day = monday.adding(days: offset)
            var fresh = VisitorLedger(seed: 3)
            schedule.roll(&fresh, to: day, context: allHealed)
            var hearted = ledger
            schedule.roll(&hearted, to: day, context: allHealed)
            if fresh.current?.resident == .sumi { plain += 1 }
            if hearted.current?.resident == .sumi { heart += 1 }
        }
        #expect(heart > plain)
        #expect(Double(heart) < Double(plain) * 1.8)
    }

    // MARK: - Reasons

    @Test func noReasonRepeatsBackToBackForOneResident() {
        let runs = simulate(days: 10_000, context: allHealed).compactMap(\.1)
        var last: [ResidentID: VisitReason] = [:]
        for visit in runs {
            #expect(last[visit.resident] != visit.reason, "\(visit.resident) \(visit.reason) twice in a row")
            last[visit.resident] = visit.reason
        }
        #expect(Set(runs.map(\.reason)) == Set(VisitReason.allCases))
    }

    @Test func festivalsAndStayOversWaitForTheirPlaces() {
        let early = VisitorSchedule.Context(healed: allHealed.healed, islandLevel: 2, built: [.garden])
        let visits = simulate(days: 2_000, context: early).compactMap(\.1)
        #expect(!visits.contains { $0.reason == .festival || $0.reason == .stayOver })
        #expect(visits.allSatisfy { $0.slot == .v1 })
        let later = simulate(days: 2_000, context: allHealed).compactMap(\.1)
        for visit in later {
            switch visit.reason {
            case .festival: #expect(visit.slot == .v2)
            case .stayOver: #expect(visit.slot == .h4)
            default: #expect(visit.slot == .g1)
            }
        }
    }

    @Test func aGiftNeverBuysScreenTime() {
        let visits = simulate(days: 3_000, context: allHealed).compactMap(\.1).filter { $0.reason == .gift }
        #expect(!visits.isEmpty)
        for visit in visits {
            switch visit.gift {
            case .seeds(let n)?: #expect(schedule.rules.giftSeeds.contains(n))
            case .decor?: break
            case nil: Issue.record("a gift visit without a gift")
            }
        }
        // Only a gift visit holds a gift.
        let others = simulate(days: 500, context: allHealed).compactMap(\.1).filter { $0.reason != .gift }
        #expect(others.allSatisfy { $0.gift == nil })
    }

    @Test func giftParcelsHoldSeedsWhileDecorIsOff() {
        #expect(!schedule.rules.decorGifts)
        let visits = simulate(days: 3_000, context: allHealed).compactMap(\.1).filter { $0.reason == .gift }
        #expect(!visits.isEmpty)
        for visit in visits {
            guard case .seeds(let n)? = visit.gift else {
                Issue.record("a gift that is not seeds: \(String(describing: visit.gift))")
                continue
            }
            #expect(schedule.rules.giftSeeds.contains(n))
        }
        // Switched on, decor parcels exist again.
        var rules = VisitorRules()
        rules.decorGifts = true
        let withDecor = VisitorSchedule(rules: rules)
        var ledger = VisitorLedger(seed: 7)
        var sawDecor = false
        for offset in 0..<3_000 {
            withDecor.roll(&ledger, to: monday.adding(days: offset), context: allHealed)
            if case .decor? = ledger.current?.gift { sawDecor = true }
            ledger.noteSeen()
        }
        #expect(sawDecor)
    }

    // MARK: - Postcard

    @Test func gezginsPostcardComesBeforeAnyIslandIsHealed() {
        let none = VisitorSchedule.Context(healed: [], islandLevel: 1, built: [.garden])
        let runs = simulate(days: 60, context: none).compactMap(\.1)
        #expect(runs.count == 60)
        #expect(runs.allSatisfy { $0.resident == .gezgin && $0.slot == .v1 })
        #expect(runs.first?.reason == .news)
        #expect(Set(runs.map(\.reason)).isSubset(of: [.news, .justSitting, .gift]))
        for (a, b) in zip(runs, runs.dropFirst()) {
            #expect(a.reason != b.reason)
        }
    }

    // MARK: - Quiet days and invitations

    @Test func quietDaysStayAtOrUnderOneInSeven() {
        let runs = simulate(days: 10_000, context: allHealed, answeringLetters: true)
        let quiet = runs.map { $0.1 == nil }
        #expect(quiet.filter { $0 }.count > 700, "quiet days should be about one in eight")
        for start in 0..<(quiet.count - 7) {
            #expect(quiet[start..<(start + 7)].filter { $0 }.count <= 1, "two quiet days within a week at \(start)")
        }
    }

    @Test func noQuietDayBeforeTwoIslandsAreHealed() {
        let one = VisitorSchedule.Context(healed: ["koke"], islandLevel: 4, built: [.garden])
        let runs = simulate(days: 2_000, context: one)
        #expect(runs.allSatisfy { $0.1 != nil })
    }

    @Test func aQuietDayOffersALetterThatNeverExpires() throws {
        var ledger = VisitorLedger(seed: 11)
        var day = monday
        // Meet someone first.
        while ledger.inviteOpenSince == nil {
            schedule.roll(&ledger, to: day, context: allHealed)
            ledger.noteSeen()
            ledger.greet()
            day = day.adding(days: 1)
        }
        let opened = ledger.inviteOpenSince
        #expect(ledger.current?.day != opened, "nobody comes on a quiet day")
        // Forty more days without answering: the letter waits, costs nothing.
        let heartsBefore = ledger.hearts
        for _ in 0..<40 {
            schedule.roll(&ledger, to: day, context: allHealed)
            ledger.noteSeen()
            day = day.adding(days: 1)
        }
        #expect(ledger.inviteOpenSince == opened)
        #expect(ledger.hearts == heartsBefore)
        // Pick someone met: they come on the next draw, bigger, with the bonus.
        let guest = try #require(ledger.met.first)
        let taken = ledger.invite(guest, on: day)
        #expect(taken)
        #expect(ledger.inviteOpenSince == nil)
        schedule.roll(&ledger, to: day, context: allHealed)
        let visit = try #require(ledger.current)
        #expect(visit.resident == guest && visit.isInvited && visit.slot == .v2 && visit.hasStationBonus)
        #expect(ledger.invitation == nil)
    }

    @Test func youCanOnlyInviteSomeoneYouHaveMet() {
        var ledger = VisitorLedger(seed: 1)
        ledger.inviteOpenSince = monday
        let early = ledger.invite(.sumi, on: monday)
        #expect(!early)
        #expect(ledger.invitation == nil)
        ledger.hearts[.sumi] = 1
        let met = ledger.invite(.sumi, on: monday)
        #expect(met)
    }

    @Test func anInvitationSurvivesAQuietDay() {
        var ledger = VisitorLedger(seed: 5)
        ledger.hearts[.nane] = 2
        ledger.nextQuietDay = monday
        ledger.invitation = Invitation(resident: .nane, askedOn: monday.adding(days: -1))
        schedule.roll(&ledger, to: monday, context: allHealed)
        #expect(ledger.current?.resident == .nane)
        #expect(ledger.inviteOpenSince == nil)
    }

    // MARK: - Staying

    @Test func anUnseenVisitorStaysUntilTheFirstVisitAfterTheirDay() {
        var ledger = VisitorLedger(seed: 21)
        schedule.roll(&ledger, to: monday, context: allHealed)
        let first = ledger.current
        #expect(first?.state == .arriving)
        // Two days pass with the app closed: nothing is missed or expired.
        schedule.roll(&ledger, to: monday.adding(days: 1), context: allHealed)
        schedule.roll(&ledger, to: monday.adding(days: 2), context: allHealed)
        #expect(ledger.current == first)
        #expect(ledger.history.isEmpty)
        // The player opens Pofu and greets them; the next day they leave.
        ledger.noteSeen()
        ledger.greet()
        #expect(ledger.hearts(of: first!.resident) == 1)
        schedule.roll(&ledger, to: monday.adding(days: 3), context: allHealed)
        #expect(ledger.history.last?.resident == first?.resident)
        #expect(ledger.history.last?.state == .departed)
        #expect(ledger.current?.day == monday.adding(days: 3) || ledger.inviteOpenSince != nil)
    }

    @Test func heartsCountVisitsNotStreaks() {
        var ledger = VisitorLedger(seed: 4)
        schedule.roll(&ledger, to: monday, context: allHealed)
        let who = ledger.current!.resident
        ledger.greet()
        ledger.greet()
        #expect(ledger.hearts(of: who) == 1)
    }

    // MARK: - Through the world clock

    @Test func theClockRollsTheVisitAtTheDayBoundary() {
        var world = World()
        let start = instant(2026, 11, 2, 9)
        world.advance(to: start, .signOfLife(at: start))
        #expect(world.snapshot.visitor?.resident == .gezgin)
        #expect(world.snapshot.visitor?.state == .arriving)
        // Pofu comes forward: the arrival lands; a greeting is a heart.
        let later = start.adding(hours: 1)
        world.advance(to: later, .foregroundBegan(at: later))
        #expect(world.snapshot.visitor?.state == .present)
        world.advance(to: later.adding(minutes: 1), GameEvent(at: later.adding(minutes: 1), kind: .greetedVisitor))
        #expect(world.snapshot.visitor?.state == .greeted)
        #expect(world.snapshot.visitor?.hearts == 1)
        // Tomorrow somebody else (or the same) arrives and yesterday leaves.
        world.advance(to: instant(2026, 11, 3, 9))
        #expect(world.state.visitors.current?.day == LocalDay(year: 2026, month: 11, day: 3))
        #expect(world.state.visitors.history.count == 1)
    }

    @Test func aSeedParcelJoinsThePouchAndNeverBuysScreenTime() throws {
        var world = World()
        let start = instant(2026, 11, 2, 9)
        world.advance(to: start, .signOfLife(at: start))
        world.state.visitors.current = DailyVisit(
            day: LocalDay(year: 2026, month: 11, day: 2), resident: .gezgin, reason: .gift, slot: .v1, gift: .seeds(4)
        )
        let seedsBefore = world.seeds
        let open = start.adding(minutes: 30)
        let delta = world.advance(to: open, GameEvent(at: open, kind: .openedGift))
        #expect(delta.giftSeeds == 4)
        #expect(world.seeds - seedsBefore >= 4)
        #expect(world.snapshot.visitor?.giftOpened == true)
        #expect(world.snapshot.visitor?.gift == nil)
        // A second tap gives nothing.
        let again = open.adding(minutes: 1)
        #expect(world.advance(to: again, GameEvent(at: again, kind: .openedGift)).giftSeeds == .zero)
        // The jar is untouched: seeds only move by collecting and building.
        #expect(world.state.stations.jar == .zero)
        #expect(world.state.guarded.isEmpty)
    }

    @Test func helpingCountsAHeartOnlyForAHelpVisit() {
        var world = World()
        let start = instant(2026, 11, 2, 9)
        world.advance(to: start, .signOfLife(at: start))
        let tap = start.adding(minutes: 5)
        world.advance(to: tap, GameEvent(at: tap, kind: .helped))
        #expect(world.state.visitors.hearts.isEmpty)
        world.state.visitors.current = DailyVisit(
            day: LocalDay(year: 2026, month: 11, day: 2), resident: .gezgin, reason: .help, slot: .v1
        )
        let again = tap.adding(minutes: 1)
        world.advance(to: again, GameEvent(at: again, kind: .helped), GameEvent(at: again, kind: .helped))
        #expect(world.state.visitors.hearts(of: .gezgin) == 1)
    }

    @Test func festivalBonusNamesTheFavouriteStation() {
        var world = World()
        let start = instant(2026, 11, 2, 9)
        world.advance(to: start, .signOfLife(at: start))
        world.state.visitors.current = DailyVisit(
            day: LocalDay(year: 2026, month: 11, day: 2), resident: .sumi, reason: .festival, slot: .v2
        )
        let snapshot = world.snapshot.visitor
        #expect(snapshot?.bonusStation == .garden)
        #expect(snapshot?.bonusPercent == 50)
    }

    // MARK: - Saves

    @Test func anOldSaveWithoutVisitorsLoadsEmpty() throws {
        var state = GameState()
        state.visitors.hearts[.sumi] = 3
        let data = try JSONEncoder().encode(state)
        var json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["visitors"] != nil)
        json.removeValue(forKey: "visitors")
        let old = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(GameState.self, from: old)
        #expect(decoded.visitors == VisitorLedger())
        #expect(decoded.visitors.current == nil && decoded.visitors.hearts.isEmpty)
    }

    @Test func theVisitorsRoundTrip() throws {
        var world = World()
        let start = instant(2026, 11, 2, 9)
        world.advance(to: start, .signOfLife(at: start))
        world.state.visitors.hearts[.damla] = 2
        world.state.visitors.inviteOpenSince = LocalDay(year: 2026, month: 11, day: 2)
        let data = try JSONEncoder().encode(world.state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        #expect(decoded == world.state)
    }
}
