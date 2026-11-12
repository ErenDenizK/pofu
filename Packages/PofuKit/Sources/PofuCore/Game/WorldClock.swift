import Foundation

/// The game model's one entry point: it takes the gate's events in, advances
/// Pofu's wellbeing, calm, gathering, and the stations deterministically,
/// and answers what the world looks like (game design v2, W3).
///
/// **The minute grid.** The model advances in whole minutes of absolute
/// time, like the simulation (`tools/sim/island_economy.py`). Each minute is
/// classified once, by the state at its start:
///
/// - **in a guarded app** (a pass is running): wellbeing drains (×2 at
///   night, ×1.25 per earlier open in 3 h), calm's run breaks, stations
///   pause;
/// - **unobserved** (before the first sign of life, past the observation
///   window, or, under the soft gate, after a pass expired until the next
///   sign of life): nothing that rewards absence accrues, and the runs
///   toward calm and gathering break (decision audit C1, U2);
/// - **paused** (Pofu in the foreground past A20's 2-minute grace): nothing
///   grows and nothing drains; looking earns nothing;
/// - **away** and observed: the stations produce × calm × care, and in
///   waking time calm grows, Pofu heals, and Pofu gathers a seed per quiet
///   minutes (ADR-0014).
///
/// An event takes effect at the start of its minute; an event older than
/// the clock takes effect at the clock (the past is never rewritten). So
/// the result depends only on the events and the final time, never on how
/// the calls are split: advancing in many small steps equals one advance
/// over the same span, exactly (A4's "production is the same computed in
/// many small steps or one").
///
/// Like `Economy`, the clock is stateless and never reads the system time.
public struct WorldClock: Sendable {
    public let rules: GameRules
    public let calendar: Calendar
    /// Reused for its bedtime arithmetic, which follows DST.
    private let nights: QuietTimeAccrual
    /// Who visits and when (experience v1 §5).
    public let visitors: VisitorSchedule

    public init(rules: GameRules = GameRules(), calendar: Calendar, visitors: VisitorSchedule = VisitorSchedule()) {
        self.rules = rules
        self.calendar = calendar
        self.visitors = visitors
        self.nights = QuietTimeAccrual(rules: rules.quiet, bedtime: rules.bedtime, calendar: calendar)
    }

    // MARK: - Advancing

    /// Applies `events` in time order and advances `state` to `date`.
    ///
    /// - Returns: What the advance did.
    @discardableResult
    public func advance(_ state: inout GameState, to date: Date, applying events: [GameEvent] = []) -> WorldDelta {
        var delta = WorldDelta()
        var frame: DayFrame?
        let ordered = events.enumerated()
            .sorted { ($0.element.at, $0.offset) < ($1.element.at, $1.offset) }
            .map(\.element)
        for event in ordered {
            run(&state, to: event.at, frame: &frame, delta: &delta)
            apply(event, to: &state, frame: &frame, delta: &delta)
        }
        run(&state, to: date, frame: &frame, delta: &delta)
        return delta
    }

    /// Starts a fresh state at `date` for a user who used Pofu before the
    /// game existed: the clock starts now (nothing before it is ever
    /// credited), and the last sign of life the gate saw keeps Pofu
    /// observing for what is left of its window, never longer. Does nothing
    /// once the state has a clock.
    public func start(_ state: inout GameState, at date: Date, lastSignal: Date?) {
        guard state.clock == nil else { return }
        state.clock = Self.minuteFloor(date)
        if let lastSignal, lastSignal <= date {
            state.lastSignalAt = Self.minuteFloor(lastSignal)
        }
    }

    /// Moves every waiting seed into the jar, after advancing to `date`.
    ///
    /// - Returns: What was collected; `nil` when nothing waits, when the
    ///   seeds are held because Pofu is not observing (ADR-0014), or at
    ///   night, when the islands sleep (A21).
    @discardableResult
    public func collect(_ state: inout GameState, at date: Date) -> SeedPouch? {
        advance(&state, to: date)
        guard let clock = state.clock, isObserving(state, at: clock), !isBedtime(clock) else { return nil }
        return state.stations.collect()
    }

    /// Builds the next level of `station` from the jar, after advancing to
    /// `date`. The only way seeds are spent.
    @discardableResult
    public func build(_ station: StationID, in state: inout GameState, at date: Date) throws -> BuildReceipt {
        advance(&state, to: date)
        if let clock = state.clock, isBedtime(clock) {
            throw BuildError.islandsAsleep
        }
        return try state.stations.build(station, tendedDays: state.tendedDays, catalog: rules.catalog)
    }

    // MARK: - Island-game rounds

    /// Rounds that can be played at `date`: none at night (A21), else the
    /// banked ones within today's plays.
    public func playableRounds(in state: GameState, at date: Date) -> Int {
        guard !isBedtime(date) else { return 0 }
        return state.rounds.playable(on: LocalDay(containing: date, in: calendar), rules: rules.rounds)
    }

    /// Spends a round played at `date` and credits its yield (at most
    /// `maximumYield`) to the pouch, after advancing to `date`.
    ///
    /// - Returns: The seeds credited.
    @discardableResult
    public func playRound(yield seeds: Int, in state: inout GameState, at date: Date) throws -> Energy {
        advance(&state, to: date)
        guard !isBedtime(date) else { throw RoundError.islandsAsleep }
        try state.rounds.play(on: LocalDay(containing: date, in: calendar), rules: rules.rounds)
        let credited = Energy(min(max(0, seeds), rules.rounds.maximumYield))
        state.stations.creditRound(credited)
        return credited
    }

    // MARK: - Reading

    /// Whether Pofu is observing at `date`: after a sign of life, and,
    /// under the soft gate, within the observation window.
    public func isObserving(_ state: GameState, at date: Date) -> Bool {
        guard let last = state.lastSignalAt else { return false }
        switch rules.measurement {
        case .screenTime:
            return true
        case .softGate:
            return date < last.addingTimeInterval(rules.quiet.observationWindow)
        }
    }

    /// Whether `date` falls in the bedtime window.
    public func isBedtime(_ date: Date) -> Bool {
        rules.bedtime.contains(date, in: calendar)
    }

    /// What the world is doing at the state's clock.
    public func activity(of state: GameState) -> WorldActivity {
        guard state.lastSignalAt != nil, let clock = state.clock else { return .notSetUp }
        if state.isInGuardedApp { return .inGuardedApp }
        if !isObserving(state, at: clock) || state.awaitingReturn { return .unobserved }
        if let since = state.foregroundSince, clock >= since.addingTimeInterval(rules.foregroundGrace) {
            return .paused
        }
        return .away
    }

    /// The breath the next open at `date` needs, or `nil`. Advance the state
    /// to `date` first, so today's guarded time is current.
    ///
    /// - Parameters:
    ///   - isRapidReach: The fourth rapid reach (the ladder's top rung),
    ///     which falls back to the breath until friend approval ships.
    ///   - isEmergency: The emergency pass, never breathed.
    public func breath(for state: GameState, at date: Date, isRapidReach: Bool = false, isEmergency: Bool = false) -> BreathRequirement? {
        let today = self.counters(of: state, on: LocalDay(containing: date, in: calendar))
        return rules.breath.requirement(
            guardedMinutes: today?.guardedMinutes ?? 0,
            overLimitOpensToday: today?.overLimitOpens ?? 0,
            isRapidReachFallback: isRapidReach,
            isEmergency: isEmergency
        )
    }

    /// The world at the state's clock, for `PofuWorld` to draw.
    public func snapshot(of state: GameState) -> WorldSnapshot {
        let catalog = rules.catalog
        let current = self.activity(of: state)
        let bedtime = state.clock.map { self.isBedtime($0) } ?? false
        let islandLevel = state.stations.islandLevel(tendedDays: state.tendedDays, catalog: catalog)
        let stations = catalog.stations.filter { state.stations.hasArrived($0.island) }.map { spec in
            let level = state.stations.level(of: spec.id)
            let next = state.stations.nextCost(of: spec)
            let cap = state.stations.maxLevel(of: spec, tendedDays: state.tendedDays, catalog: catalog)
            let capped = next != nil && level >= cap
            return StationStatus(
                id: spec.id,
                island: spec.island,
                level: level,
                maxLevel: spec.maxLevel,
                levelCap: cap,
                isOpen: state.stations.isOpen(spec, tendedDays: state.tendedDays, catalog: catalog),
                nextCost: next,
                canAfford: next.map { state.stations.jar >= $0 } ?? false,
                seedsPerHour: spec.seedsPerHour(at: level),
                capLiftsAtIslandLevel: capped ? catalog.islandLevel(allowingStationLevel: level + 1) : nil
            )
        }
        let rate = Double(state.stations.centiRate(catalog: catalog)) / 100
        let factor = state.calm.multiplier * Double(state.care.productionTenths(rules: rules.care)) / 10
        let day = state.clock.map { LocalDay(containing: $0, in: calendar) }
        let today = day.flatMap { self.counters(of: state, on: $0) }
        return WorldSnapshot(
            clock: state.clock,
            activity: current,
            isBedtime: bedtime,
            wellbeing: state.care.wellbeing,
            band: state.care.band(rules: rules.care),
            calm: state.calm.multiplier,
            calmProgress: state.calm.progressToNextStep(rules: rules.calm),
            calmIsFull: state.calm.isFull(rules: rules.calm),
            pending: state.stations.pending,
            jar: state.stations.jar,
            isHolding: !state.stations.pending.isEmpty && !(state.clock.map { self.isObserving(state, at: $0) } ?? false),
            tendedDays: state.tendedDays,
            calmNights: state.calmNights,
            homeStage: catalog.homeStage(islandLevel: islandLevel),
            islandLevel: islandLevel,
            nextIslandLevel: state.stations.nextIslandLevelRequirement(tendedDays: state.tendedDays, catalog: catalog),
            islands: state.stations.arrivalOrder,
            stations: stations,
            seedsPerHour: current == .away ? rate * factor : 0,
            guardedMinutesToday: today?.guardedMinutes ?? 0,
            dailyHourMinutes: rules.breath.dailyHourMinutes,
            overLimitOpensToday: today?.overLimitOpens ?? 0,
            nextBreath: state.clock.flatMap { self.breath(for: state, at: $0) },
            visitor: visitorSnapshot(of: state),
            invitationOpen: state.visitors.inviteOpenSince != nil,
            metResidents: state.visitors.met,
            invited: state.visitors.invitation?.resident,
            koke: asleepAtBedtime(WonderIslands.status(game: state, day: day), bedtime),
            caglayan: asleepAtBedtime(WonderIslands.status(of: .caglayan, game: state, day: day), bedtime),
            firstDay: state.firstDay
        )
    }

    /// Both wonder islands sleep at bedtime: no advance, however the day went.
    private func asleepAtBedtime(_ status: WonderStatus, _ bedtime: Bool) -> WonderStatus {
        guard bedtime else { return status }
        var asleep = status
        asleep.isAsleep = true
        asleep.canAdvance = false
        return asleep
    }

    private func visitorSnapshot(of state: GameState) -> VisitorSnapshot? {
        guard let visit = state.visitors.current else { return nil }
        let favourite = visitors.roster.first { $0.resident == visit.resident }?.favourite
        let bonus = visit.hasStationBonus
        return VisitorSnapshot(
            resident: visit.resident,
            reason: visit.reason,
            slot: visit.slot,
            state: visit.state,
            gift: visit.giftOpened ? nil : visit.gift,
            giftOpened: visit.giftOpened,
            helped: visit.helped,
            isInvited: visit.isInvited,
            hearts: state.visitors.hearts(of: visit.resident),
            bonusStation: bonus ? favourite : nil,
            bonusPercent: bonus && favourite != nil ? visitors.rules.stationBonusPercent : 0
        )
    }

    /// The first instant of the minute containing `date`.
    public static func minuteFloor(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }

    // MARK: - The minute loop

    private func counters(of state: GameState, on day: LocalDay) -> GameDay? {
        state.today.flatMap { $0.day == day ? $0 : nil }
    }

    /// Processes every whole minute that ends by `date`.
    private func run(_ state: inout GameState, to date: Date, frame: inout DayFrame?, delta: inout WorldDelta) {
        guard let start = state.clock else {
            state.clock = Self.minuteFloor(date)
            return
        }
        var minute = start
        while minute.addingTimeInterval(60) <= date {
            tick(&state, minute: minute, frame: &frame, delta: &delta)
            minute = minute.addingTimeInterval(60)
        }
        state.clock = minute
    }

    private func tick(_ state: inout GameState, minute: Date, frame cached: inout DayFrame?, delta: inout WorldDelta) {
        let frame = self.frame(containing: minute, cached: &cached)
        rollDay(&state, to: frame.day, delta: &delta)
        let bedtime = frame.isBedtime(minute)
        if frame.startsBedtime(minute) {
            state.calmNightCandidate = true
            state.quietRunMinutes = 0
        }
        expirePasses(&state, at: minute)

        let observing = isObserving(state, at: minute)
        if observing {
            state.today?.observed = true
        }
        if state.isInGuardedApp {
            state.care.drainMinute(earlierOpens: earlierOpens(state, at: minute), atNight: bedtime, rules: rules.care)
            breakRuns(&state, bedtime: bedtime)
            state.today?.estimatedGuardedMinutes += 1
            delta.guardedMinutes += 1
        } else if !observing || state.awaitingReturn {
            breakRuns(&state, bedtime: bedtime)
            delta.unobservedMinutes += 1
        } else if let since = state.foregroundSince, minute >= since.addingTimeInterval(rules.foregroundGrace) {
            // A20: looking at Pofu is not being away. Nothing grows, nothing
            // drains, and the runs hold.
            delta.pausedMinutes += 1
        } else {
            if !bedtime {
                if state.calm.calmMinute(rules: rules.calm) {
                    delta.calmSteps += 1
                }
                state.care.healMinute(rules: rules.care)
                gatherMinute(&state, delta: &delta)
            }
            delta.stationSeeds += state.stations.produceMinute(
                calmTenths: state.calm.tenths,
                careTenths: state.care.productionTenths(rules: rules.care),
                catalog: rules.catalog
            )
            delta.awayMinutes += 1
        }
        if frame.endsBedtime(minute.addingTimeInterval(60)) {
            settleNight(&state, delta: &delta)
        }
    }

    private func breakRuns(_ state: inout GameState, bedtime: Bool) {
        state.calm.breakRun()
        state.quietRunMinutes = 0
        if bedtime {
            state.calmNightCandidate = false
        }
    }

    /// Opens before this minute's in the escalation window: the current
    /// open does not escalate itself.
    private func earlierOpens(_ state: GameState, at minute: Date) -> Int {
        let start = minute.addingTimeInterval(-rules.care.escalationWindow)
        var count = 0
        for open in state.recentOpens where open > start && open <= minute {
            count += 1
        }
        return max(0, count - 1)
    }

    private func gatherMinute(_ state: inout GameState, delta: inout WorldDelta) {
        state.quietRunMinutes += 1
        let quiet = rules.quiet
        guard quiet.blockMinutes > 0, state.quietRunMinutes % quiet.blockMinutes == 0 else { return }
        let already = state.today?.gatheredSeeds ?? .zero
        let credited = min(quiet.seedsPerBlock, max(quiet.dailyCap - already, .zero))
        guard credited > .zero else { return }
        state.today?.gatheredSeeds += credited
        state.stations.gather(credited)
        delta.gatheredSeeds += credited
    }

    private func expirePasses(_ state: inout GameState, at minute: Date) {
        guard state.guarded.contains(where: { $0.until <= minute }) else { return }
        state.guarded.removeAll { $0.until <= minute }
        if state.guarded.isEmpty, rules.measurement == .softGate, state.foregroundSince == nil {
            // Nothing closes the app at expiry: until the next sign of life,
            // Pofu cannot know the user left (decision audit C1). With Pofu
            // on screen, the user is demonstrably out.
            state.awaitingReturn = true
        }
    }

    /// The bedtime window ended: Pofu sleeps it off, and a calm night
    /// (no opens, observed throughout) heals him, adds calm, and brings
    /// the slept-on-it bonus.
    private func settleNight(_ state: inout GameState, delta: inout WorldDelta) {
        let calmNight = state.calmNightCandidate == true
        state.care.nightEnded(calm: calmNight, rules: rules.care)
        if calmNight {
            state.calm.calmNight(rules: rules.calm)
            state.calmNights += 1
            state.stations.addSleepBonus(rules.quiet.sleepBonus)
            delta.sleepBonusSeeds += max(rules.quiet.sleepBonus, .zero)
            delta.calmNights += 1
        }
        state.calmNightCandidate = nil
    }

    /// Starts the counters of `day`. The day before counts as tended if
    /// Pofu observed any of it, and islands whose rule now holds drift
    /// close overnight.
    private func rollDay(_ state: inout GameState, to day: LocalDay, delta: inout WorldDelta) {
        if let today = state.today {
            guard today.day < day else { return }
            if today.observed {
                state.tendedDays += 1
            }
        }
        if state.firstDay == nil {
            state.firstDay = day
        }
        state.today = GameDay(day: day)
        delta.arrivals += state.stations.settleArrivals(
            tendedDays: state.tendedDays,
            calmNights: state.calmNights,
            released: rules.releasedIslands,
            catalog: rules.catalog
        )
        WonderIslands.roll(&state.wonders, to: day, tendedDays: state.tendedDays, harborOpen: state.stations.arrivalOrder.contains(.harbor))
        visitors.roll(&state.visitors, to: day, context: VisitorSchedule.context(of: state, catalog: rules.catalog, roster: visitors.roster))
    }

    // MARK: - Events

    private func apply(_ event: GameEvent, to state: inout GameState, frame cached: inout DayFrame?, delta: inout WorldDelta) {
        let floor = Self.minuteFloor(event.at)
        let at = max(floor, state.clock ?? floor)
        let frame = self.frame(containing: at, cached: &cached)
        rollDay(&state, to: frame.day, delta: &delta)
        switch event.kind {
        case .signOfLife:
            noteSignal(&state, at: at)
        case .returned:
            noteReturn(&state, at: at)
        case .foregroundBegan:
            state.foregroundSince = at
            noteReturn(&state, at: at)
            state.visitors.noteSeen()
        case .foregroundEnded:
            state.foregroundSince = nil
        case .resisted:
            noteSignal(&state, at: at)
            state.care.skipped(on: frame.day, rules: rules.care)
            delta.skipSeeds += state.stations.giftSkip(on: frame.day, rules: rules.seeds)
            state.rounds.earnForResist(on: frame.day, rules: rules.rounds)
            delta.resisted += 1
            state.today?.resistedReaches += 1
        case .opened(let pass):
            open(pass, at: at, in: &state, delta: &delta)
        case .passEndedEarly(let passID), .shieldRestored(let passID):
            guard let index = state.guarded.firstIndex(where: { $0.passID == passID }) else { return }
            state.guarded.remove(at: index)
            if state.guarded.isEmpty {
                // Ended in Pofu, or closed by the shield: the user is out.
                state.awaitingReturn = false
            }
        case .greetedVisitor:
            state.visitors.greet()
        case .openedGift:
            guard !isBedtime(at), case .seeds(let seeds)? = state.visitors.openGift() else { return }
            // A parcel of seeds joins the pouch like the other seeds: world
            // material, never screen time (ADR-0015).
            state.stations.gather(Energy(seeds))
            delta.giftSeeds += Energy(seeds)
        case .helped:
            state.visitors.help()
        case .invited(let resident):
            state.visitors.invite(resident, on: frame.day)
        case .tendedWonder(let wonder):
            // The islands sleep at night: a visit at bedtime changes nothing.
            guard !isBedtime(at) else { return }
            let resisted = (state.today?.day == frame.day ? state.today?.resistedReaches : nil) ?? 0
            state.wonders.islands[wonder] = WonderIslands.advance(state: state.wonders[wonder], day: frame.day, resistedToday: resisted > 0)
        case .usageMeasured(let minutes):
            if let today = state.today, today.day == frame.day {
                state.today?.measuredGuardedMinutes = max(today.measuredGuardedMinutes, minutes)
            }
        }
    }

    private func noteSignal(_ state: inout GameState, at date: Date) {
        state.lastSignalAt = max(state.lastSignalAt ?? date, date)
        endReturn(&state, at: date)
    }

    private func noteReturn(_ state: inout GameState, at date: Date) {
        guard state.lastSignalAt != nil else { return }
        endReturn(&state, at: date)
    }

    /// The user is demonstrably back: passes that ended by now ended
    /// before this sign of life, so they leave no unobserved time behind.
    private func endReturn(_ state: inout GameState, at date: Date) {
        state.guarded.removeAll { $0.until <= date }
        state.awaitingReturn = false
    }

    private func open(_ pass: Pass, at date: Date, in state: inout GameState, delta: inout WorldDelta) {
        noteSignal(&state, at: date)
        let seconds = pass.expiresAt.timeIntervalSince(pass.grantedAt)
        guard seconds > 0 else { return }
        let minutes = max(1, Rounding.up(seconds / 60))
        let isEmergency = pass.source == .emergency
        if !isEmergency, rules.breath.isPastDailyHour(guardedMinutes: state.today?.guardedMinutes ?? 0) {
            state.today?.overLimitOpens += 1
        }
        let change = state.calm.opened(passMinutes: minutes, isEmergency: isEmergency, startedAt: date, rules: rules.calm)
        if change.lowered {
            switch change.kind {
            case .quickCheck: delta.calmHalvings += 1
            case .fullOpen: delta.calmResets += 1
            }
        }
        state.care.opened(rules: rules.care)
        let horizon = date.addingTimeInterval(-rules.care.escalationWindow)
        state.recentOpens.removeAll { $0 <= horizon }
        state.recentOpens.append(date)
        state.guarded.append(GuardedSpan(passID: pass.id, startedAt: date, until: date.addingTimeInterval(TimeInterval(minutes) * 60)))
        delta.opens += 1
    }

    // MARK: - Days

    /// One local day: its bounds and the bedtime windows that touch it.
    struct DayFrame {
        let day: LocalDay
        let start: Date
        let end: Date
        let nights: [(start: Date, end: Date)]

        func contains(_ date: Date) -> Bool {
            start <= date && date < end
        }

        func isBedtime(_ minute: Date) -> Bool {
            nights.contains { $0.start <= minute && minute < $0.end }
        }

        func startsBedtime(_ minute: Date) -> Bool {
            nights.contains { $0.start == minute }
        }

        func endsBedtime(_ instant: Date) -> Bool {
            nights.contains { $0.end == instant }
        }
    }

    private func frame(containing date: Date, cached: inout DayFrame?) -> DayFrame {
        if let cached, cached.contains(date) {
            return cached
        }
        let day = LocalDay(containing: date, in: calendar)
        let start = day.start(in: calendar) ?? date
        let end = day.adding(days: 1).start(in: calendar) ?? start.addingTimeInterval(86_400)
        // Windows that touch the day, including one ending exactly at its
        // end.
        let nights = self.nights.bedtimeIntervals(from: start.addingTimeInterval(-1), to: end.addingTimeInterval(1))
        let frame = DayFrame(day: day, start: start, end: max(end, date.addingTimeInterval(60)), nights: nights)
        cached = frame
        return frame
    }
}
