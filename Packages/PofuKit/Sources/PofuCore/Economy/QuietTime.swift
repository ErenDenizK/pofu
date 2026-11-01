import Foundation

/// The persisted state of quiet-time earning (ADR-0014): when the current
/// quiet stretch began, how far accrual has been computed, what Pofu has
/// observed, and the seeds waiting in its cheeks.
///
/// A ledger is plain data. Every change goes through `QuietTimeAccrual`,
/// which enforces the rules; the setters are therefore internal to
/// PofuCore.
public struct QuietTimeLedger: Hashable, Sendable {
    /// When the current quiet stretch began: the first sign of life after
    /// the last pass, the moment a pass was ended early in Pofu, or the
    /// first sign of life from the automation. `nil` while a pass runs,
    /// after a pass expired until the next sign of life (that time is
    /// unobserved), and before Pofu has heard from the automation at all.
    public internal(set) var quietSince: Date?
    /// The instant accrual has been computed through.
    public internal(set) var accruedThrough: Date?
    /// When the current, unbroken stretch of observation began.
    public internal(set) var observedSince: Date?
    /// The most recent sign of life from the automation: a check-in or a
    /// pass-through.
    public internal(set) var lastSignalAt: Date?
    /// Seeds from quiet blocks, waiting in Pofu's cheeks to be collected.
    public internal(set) var pendingQuietSeeds: Energy
    /// Slept-on-it bonuses waiting in Pofu's cheeks to be collected.
    public internal(set) var pendingSleepBonus: Energy
    /// Quiet-block seeds credited per local day (the day each block
    /// started on), for the daily cap. Pruned like the wallet's history.
    public internal(set) var quietSeedsByDay: [LocalDay: Energy]
    /// The local day on which the last rewarded bedtime window ended, so a
    /// night is never rewarded twice.
    public internal(set) var lastSleepBonusDay: LocalDay?

    public init() {
        self.quietSince = nil
        self.accruedThrough = nil
        self.observedSince = nil
        self.lastSignalAt = nil
        self.pendingQuietSeeds = .zero
        self.pendingSleepBonus = .zero
        self.quietSeedsByDay = [:]
        self.lastSleepBonusDay = nil
    }

    /// Everything waiting in Pofu's cheeks.
    public var pending: Energy {
        pendingQuietSeeds + pendingSleepBonus
    }

    /// Quiet-block seeds credited for `day`.
    public func quietSeeds(on day: LocalDay) -> Energy {
        quietSeedsByDay[day, default: .zero]
    }
}

extension QuietTimeLedger: Codable {
    private enum CodingKeys: String, CodingKey {
        case quietSince, accruedThrough, observedSince, lastSignalAt
        case pendingQuietSeeds, pendingSleepBonus, quietSeedsByDay, lastSleepBonusDay
    }

    /// Every field is optional on decode, so a ledger written by another
    /// version of the app always loads.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        quietSince = try container.decodeIfPresent(Date.self, forKey: .quietSince)
        accruedThrough = try container.decodeIfPresent(Date.self, forKey: .accruedThrough)
        observedSince = try container.decodeIfPresent(Date.self, forKey: .observedSince)
        lastSignalAt = try container.decodeIfPresent(Date.self, forKey: .lastSignalAt)
        pendingQuietSeeds = max(try container.decodeIfPresent(Energy.self, forKey: .pendingQuietSeeds) ?? .zero, .zero)
        pendingSleepBonus = max(try container.decodeIfPresent(Energy.self, forKey: .pendingSleepBonus) ?? .zero, .zero)
        quietSeedsByDay = try container.decodeIfPresent([LocalDay: Energy].self, forKey: .quietSeedsByDay) ?? [:]
        lastSleepBonusDay = try container.decodeIfPresent(LocalDay.self, forKey: .lastSleepBonusDay)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(quietSince, forKey: .quietSince)
        try container.encodeIfPresent(accruedThrough, forKey: .accruedThrough)
        try container.encodeIfPresent(observedSince, forKey: .observedSince)
        try container.encodeIfPresent(lastSignalAt, forKey: .lastSignalAt)
        try container.encode(pendingQuietSeeds, forKey: .pendingQuietSeeds)
        try container.encode(pendingSleepBonus, forKey: .pendingSleepBonus)
        try container.encode(quietSeedsByDay, forKey: .quietSeedsByDay)
        try container.encodeIfPresent(lastSleepBonusDay, forKey: .lastSleepBonusDay)
    }
}

/// What one advance of quiet time put into Pofu's cheeks.
public struct QuietAccrual: Hashable, Sendable {
    /// Seeds from whole quiet blocks.
    public var quietSeeds: Energy
    /// Seeds the blocks were worth but did not get, because the day's quiet
    /// cap was reached.
    public var forfeitedToCap: Energy
    /// Slept-on-it bonuses for bedtime windows that ended without an open.
    public var sleepBonus: Energy

    public init(quietSeeds: Energy = .zero, forfeitedToCap: Energy = .zero, sleepBonus: Energy = .zero) {
        self.quietSeeds = quietSeeds
        self.forfeitedToCap = forfeitedToCap
        self.sleepBonus = sleepBonus
    }

    /// Everything credited.
    public var total: Energy {
        quietSeeds + sleepBonus
    }
}

/// Seeds moved from Pofu's cheeks to the balance.
public struct QuietCollection: Hashable, Sendable {
    public let quietSeeds: Energy
    public let sleepBonus: Energy

    public init(quietSeeds: Energy, sleepBonus: Energy) {
        self.quietSeeds = quietSeeds
        self.sleepBonus = sleepBonus
    }

    public var total: Energy {
        quietSeeds + sleepBonus
    }
}

/// The rules of quiet-time earning (ADR-0014), applied to a
/// `QuietTimeLedger`.
///
/// Staying away from the guarded apps earns seeds by itself: the absence is
/// the proof. A **quiet stretch** is time without a pass running. Only its
/// waking, observed part counts, in whole blocks of continuous time:
///
/// - A pass starting (any opened outcome) breaks the stretch. Ending a
///   pass early in Pofu resumes it at once. A pass that simply expires
///   does not: before Screen Time, nothing closes the guarded app at
///   expiry, and the automation does not fire while the user stays in it.
///   The time between expiry and the next sign of life (a check-in or
///   another automation run, Pofu coming to the foreground, or a tap on
///   the expiry notification) is unobserved and never counts; the next
///   stretch starts at that sign of life. A resisted attempt does not
///   break the stretch. Pass-throughs, like every sign of life while a
///   pass runs, keep Pofu observing but resume nothing.
/// - The bedtime window does not count. A whole bedtime window without an
///   open earns the slept-on-it bonus instead.
/// - Time counts only while Pofu is observing: within the observation
///   window after a sign of life from the automation. Seeds already in the
///   cheeks are held, not lost, while Pofu is not observing, and are
///   released by the next sign of life.
///
/// Like `Economy`, the accrual is stateless and every operation takes the
/// time it happens at. Accrual is prefix-consistent: advancing in many
/// small steps credits exactly what one advance over the same span does,
/// so the app may compute it whenever it likes. The rules are documented
/// in `docs/product/economy.md`.
public struct QuietTimeAccrual: Sendable {
    public let rules: QuietTimeRules
    /// The window excluded from quiet time; the one that prices night
    /// unlocks.
    public let bedtime: DailyWindow
    public let calendar: Calendar
    private let gregorian: Calendar

    public init(
        rules: QuietTimeRules = QuietTimeRules(),
        bedtime: DailyWindow = SpendingRules().bedtime,
        calendar: Calendar
    ) {
        self.rules = rules
        self.bedtime = bedtime
        self.calendar = calendar
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        self.gregorian = gregorian
    }

    public init(economy: Economy) {
        self.init(
            rules: economy.configuration.quietTime,
            bedtime: economy.configuration.spending.bedtime,
            calendar: economy.calendar
        )
    }

    /// The local day containing `date`.
    public func day(of date: Date) -> LocalDay {
        LocalDay(containing: date, in: calendar)
    }

    // MARK: - Observation

    /// Whether Pofu is observing at `date`: inside the observation window
    /// that began with an unbroken run of signs of life.
    public func isObserving(_ ledger: QuietTimeLedger, at date: Date) -> Bool {
        guard let since = ledger.observedSince, let last = ledger.lastSignalAt else { return false }
        return since <= date && date < last.addingTimeInterval(rules.observationWindow)
    }

    /// Whether the automation has been silent for longer than the
    /// observation window, so Home should ask the user to check the setup.
    /// Never true before the first sign of life: that is plain setup.
    public func isAwaitingSignOfLife(_ ledger: QuietTimeLedger, at date: Date) -> Bool {
        guard let last = ledger.lastSignalAt else { return false }
        return date >= last.addingTimeInterval(rules.observationWindow)
    }

    /// Whether seeds are waiting in the cheeks but cannot be collected,
    /// because Pofu is not observing.
    public func isHolding(_ ledger: QuietTimeLedger, at date: Date) -> Bool {
        ledger.pending > .zero && !isObserving(ledger, at: date)
    }

    /// How long the current quiet stretch has lasted at `date`, or `nil`
    /// while a pass runs, after a pass until the next sign of life, or
    /// while Pofu is not observing.
    public func quietStretch(_ ledger: QuietTimeLedger, at date: Date) -> TimeInterval? {
        guard let since = ledger.quietSince, since <= date, isObserving(ledger, at: date) else { return nil }
        return date.timeIntervalSince(since)
    }

    // MARK: - Events

    /// The automation showed a sign of life at `date` (a check-in or a
    /// pass-through).
    ///
    /// The first sign of life starts the first quiet stretch, unless a
    /// pass is running. Any sign of life with no pass running starts a
    /// stretch paused by an earlier pass. A sign of life after the
    /// observation window lapsed starts a new observation; the silent time
    /// in between never counts.
    public func recordSignal(at date: Date, in ledger: inout QuietTimeLedger, passes: PassLedger) {
        guard let last = ledger.lastSignalAt else {
            ledger.observedSince = date
            ledger.lastSignalAt = date
            ledger.accruedThrough = max(ledger.accruedThrough ?? date, date)
            resumeQuiet(at: date, in: &ledger, passes: passes)
            return
        }
        advance(&ledger, to: date)
        // A sign of life after the window closed starts a new observation;
        // one exactly at its end keeps the observation unbroken.
        if date > last.addingTimeInterval(rules.observationWindow) {
            ledger.observedSince = date
        }
        ledger.lastSignalAt = max(last, date)
        resumeQuiet(at: date, in: &ledger, passes: passes)
    }

    /// The user is back in Pofu at `date`: it came to the foreground, or
    /// they tapped the pass-expiry notification. With no pass running, this
    /// starts a quiet stretch paused by an earlier pass.
    ///
    /// It is not a sign of life from the automation: it neither extends
    /// observation nor releases held seeds, because opening Pofu says
    /// nothing about whether the automation still guards the apps.
    public func userReturned(at date: Date, in ledger: inout QuietTimeLedger, passes: PassLedger) {
        guard ledger.lastSignalAt != nil else { return }
        advance(&ledger, to: date)
        resumeQuiet(at: date, in: &ledger, passes: passes)
    }

    /// `pass` started: the guarded app opened. Credits the stretch up to
    /// that moment, then pauses quiet until the next sign of life after the
    /// pass, or until the pass is ended early.
    public func passStarted(_ pass: Pass, in ledger: inout QuietTimeLedger) {
        advance(&ledger, to: pass.grantedAt)
        ledger.quietSince = nil
    }

    /// A pass ended before its expiry at `date`, in Pofu (ended early, or
    /// voided from its grant). The user is demonstrably not in the guarded
    /// app, so quiet resumes at once, unless another pass in `passes` is
    /// still running.
    public func passEnded(at date: Date, in ledger: inout QuietTimeLedger, remaining passes: PassLedger) {
        advance(&ledger, to: date)
        guard ledger.lastSignalAt != nil, ledger.quietSince == nil, Self.latestEnd(of: passes, at: date) == nil else {
            return
        }
        ledger.quietSince = date
    }

    /// Starts the ledger of a user who used Pofu before quiet time
    /// existed, from their history: observed and quiet since the last sign
    /// of life, unless their last pass outlasted it; quiet then waits for
    /// the next sign of life. Does nothing once the ledger has heard a sign
    /// of life.
    public func bootstrap(_ ledger: inout QuietTimeLedger, lastSignal: Date, checkIns: [CheckInRecord]) {
        guard ledger.lastSignalAt == nil else { return }
        let lastPassEnd = checkIns.compactMap(\.outcome.pass?.expiresAt).max() ?? lastSignal
        ledger.quietSince = lastPassEnd > lastSignal ? nil : lastSignal
        ledger.observedSince = lastSignal
        ledger.lastSignalAt = lastSignal
        ledger.accruedThrough = lastSignal
    }

    // MARK: - Accrual

    /// Credits every whole quiet block and every slept-on-it bonus
    /// completed after `accruedThrough`, up to `date`, into the cheeks.
    ///
    /// A `date` at or before `accruedThrough` (including a clock that moved
    /// backwards) changes nothing.
    @discardableResult
    public func advance(_ ledger: inout QuietTimeLedger, to date: Date) -> QuietAccrual {
        guard let from = ledger.accruedThrough, date > from else { return QuietAccrual() }
        defer {
            ledger.accruedThrough = date
            let cutoff = day(of: date).adding(days: -Economy.historyRetentionDays)
            ledger.quietSeedsByDay = ledger.quietSeedsByDay.filter { $0.key >= cutoff }
        }
        guard
            let since = ledger.quietSince,
            let observedSince = ledger.observedSince,
            let lastSignal = ledger.lastSignalAt
        else {
            return QuietAccrual()
        }

        let upper = min(date, lastSignal.addingTimeInterval(rules.observationWindow))
        let lower = max(since, observedSince)
        var result = QuietAccrual()
        creditBlocks(from: from, lower: lower, upper: upper, into: &ledger, result: &result)
        creditSleepBonus(from: from, upper: upper, quietSince: since, observedSince: observedSince, into: &ledger, result: &result)
        return result
    }

    /// Moves everything waiting in the cheeks to the balance, after
    /// accruing up to `date`.
    ///
    /// - Returns: What was collected, or `nil` when the cheeks are empty or
    ///   the seeds are held because Pofu is not observing.
    @discardableResult
    public func collect(_ ledger: inout QuietTimeLedger, into wallet: inout Wallet, at date: Date) -> QuietCollection? {
        advance(&ledger, to: date)
        guard ledger.pending > .zero, isObserving(ledger, at: date) else { return nil }
        let collection = QuietCollection(quietSeeds: ledger.pendingQuietSeeds, sleepBonus: ledger.pendingSleepBonus)
        wallet.balance += collection.total
        ledger.pendingQuietSeeds = .zero
        ledger.pendingSleepBonus = .zero
        return collection
    }

    // MARK: - Private

    private var blockLength: TimeInterval {
        TimeInterval(rules.blockMinutes) * 60
    }

    private func creditBlocks(
        from: Date,
        lower: Date,
        upper: Date,
        into ledger: inout QuietTimeLedger,
        result: inout QuietAccrual
    ) {
        guard rules.blockMinutes > 0, rules.seedsPerBlock > .zero, upper > max(lower, from) else { return }
        let block = blockLength
        // Segments that can hold new blocks start at or after the waking
        // segment around `from`, so the walk starts there, not at the
        // possibly long-ago start of the stretch.
        let walkStart = max(lower, latestBedtimeEnd(atOrBefore: from) ?? lower)
        for segment in wakingSegments(from: walkStart, to: upper) {
            let total = Self.wholeBlocks(segment.end.timeIntervalSince(segment.start), of: block)
            let done = from > segment.start
                ? Self.wholeBlocks(min(from, segment.end).timeIntervalSince(segment.start), of: block)
                : 0
            guard total > done else { continue }
            for index in done..<total {
                let blockStart = segment.start.addingTimeInterval(Double(index) * block)
                let blockDay = day(of: blockStart)
                let already = ledger.quietSeeds(on: blockDay)
                let room = max(rules.dailyCap - already, .zero)
                let credited = min(rules.seedsPerBlock, room)
                result.forfeitedToCap += rules.seedsPerBlock - credited
                guard credited > .zero else { continue }
                ledger.quietSeedsByDay[blockDay] = already + credited
                ledger.pendingQuietSeeds += credited
                result.quietSeeds += credited
            }
        }
    }

    private func creditSleepBonus(
        from: Date,
        upper: Date,
        quietSince: Date,
        observedSince: Date,
        into ledger: inout QuietTimeLedger,
        result: inout QuietAccrual
    ) {
        guard rules.sleepBonus > .zero, upper > from else { return }
        for night in bedtimeIntervals(from: from, to: upper) where night.end > from && night.end <= upper {
            // No pass ran during the night, and Pofu watched all of it.
            guard quietSince <= night.start, observedSince <= night.start else { continue }
            let morning = day(of: night.end)
            if let last = ledger.lastSleepBonusDay, morning <= last { continue }
            ledger.lastSleepBonusDay = morning
            ledger.pendingSleepBonus += rules.sleepBonus
            result.sleepBonus += rules.sleepBonus
        }
    }

    /// The parts of `[from, to)` outside the bedtime window, in order.
    func wakingSegments(from: Date, to: Date) -> [(start: Date, end: Date)] {
        guard to > from else { return [] }
        var segments: [(start: Date, end: Date)] = []
        var cursor = from
        for night in bedtimeIntervals(from: from, to: to) {
            if night.start > cursor {
                segments.append((start: cursor, end: min(night.start, to)))
            }
            cursor = max(cursor, night.end)
            if cursor >= to { break }
        }
        if cursor < to {
            segments.append((start: cursor, end: to))
        }
        return segments
    }

    /// Bedtime windows, as instants, that overlap `[from, to)`, in order.
    /// Local wall-clock times follow DST changes.
    func bedtimeIntervals(from: Date, to: Date) -> [(start: Date, end: Date)] {
        guard !bedtime.isEmpty, to > from else { return [] }
        var intervals: [(start: Date, end: Date)] = []
        var current = day(of: from).adding(days: -1)
        let last = day(of: to)
        while current <= last {
            let endDay = bedtime.crossesMidnight ? current.adding(days: 1) : current
            if let start = instant(current, bedtime.start), let end = instant(endDay, bedtime.end),
                end > start, end > from, start < to
            {
                intervals.append((start: start, end: end))
            }
            current = current.adding(days: 1)
        }
        return intervals.sorted { $0.start < $1.start }
    }

    /// The end of the latest bedtime window that ended at or before `date`.
    private func latestBedtimeEnd(atOrBefore date: Date) -> Date? {
        bedtimeIntervals(from: date.addingTimeInterval(-2 * 86_400), to: date.addingTimeInterval(1))
            .map(\.end)
            .filter { $0 <= date }
            .max()
    }

    private func instant(_ day: LocalDay, _ time: LocalTime) -> Date? {
        gregorian.date(
            from: DateComponents(year: day.year, month: day.month, day: day.day, hour: time.hour, minute: time.minute)
        )
    }

    private static func wholeBlocks(_ duration: TimeInterval, of block: TimeInterval) -> Int {
        guard block > 0, duration > 0 else { return 0 }
        return max(0, Rounding.down(duration / block))
    }

    /// Starts a quiet stretch at `date` (or where accrual already is, if
    /// the clock moved backwards) when none is running and no pass in
    /// `passes` is.
    private func resumeQuiet(at date: Date, in ledger: inout QuietTimeLedger, passes: PassLedger) {
        guard ledger.quietSince == nil, Self.latestEnd(of: passes, at: date) == nil else { return }
        ledger.quietSince = max(date, ledger.accruedThrough ?? date)
    }

    private static func latestEnd(of passes: PassLedger, at date: Date) -> Date? {
        passes.passes.filter { $0.isValid(at: date) }.map(\.expiresAt).max()
    }
}
