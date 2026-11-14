import Foundation
import Observation
import PofuCore

/// What the build moment asks of the camera.
@MainActor
public protocol WorldCamera: AnyObject {
    /// The sheet drops to compact and the camera pushes in (§2.4, t 0).
    func beginBuildFraming(_ station: StationID)
    /// The sheet returns to medium and the camera settles back (t 1.75 s).
    func endBuildFraming(_ station: StationID)
    /// The visit's news has spoken (its button was taken, or the visit has
    /// none): an island that grew waits no longer and grows now.
    func newsHasSpoken()
}

extension WorldCamera {
    public func newsHasSpoken() {}
}

/// A moment in progress: what it is and when it started.
public struct ActiveMoment<Moment: Hashable & Sendable>: Hashable, Sendable {
    public let moment: Moment
    public let start: Date
    /// Cues up to this time have played.
    var played: Double

    init(moment: Moment, start: Date) {
        self.moment = moment
        self.start = start
        self.played = -1
    }
}

/// Home's visit and its two moments, collect and build (app–game boundary
/// §6; interaction spec §2.4): the state the chrome and the scene read, and
/// the only place that calls the model's commits.
///
/// The model commits first (`WorldClock.collect`, `WorldClock.build`, passed
/// in as closures), then the moment plays as presentation: interruptible,
/// never gating input, and never replayed (§7.3). Cues fire from a timer
/// in the app and from `advance(to:)` in tests; both go through the same
/// code, and a cue never fires twice.
@MainActor
@Observable
public final class WorldHomeModel {
    // MARK: State

    public private(set) var visit: VisitProgress {
        didSet {
            if !holdsIslandGrowForNews {
                camera?.newsHasSpoken()
            }
        }
    }
    /// A visit has begun since the app started: before that, the news the
    /// plan will carry is not known yet.
    @ObservationIgnored public private(set) var hasBegunVisit = false
    public private(set) var collect: ActiveMoment<CollectMoment>?
    public private(set) var build: ActiveMoment<BuildMoment>?
    /// The station whose build is still in its compact phase: its sheet
    /// reads "Building…" and refuses a second tap (§2.6).
    public private(set) var buildingStation: StationID?
    /// When the visit settled, for A15's 15-minute rule.
    public private(set) var settledAt: Date?
    /// Which settled line Pofu is saying after a tap, if any.
    public private(set) var settledLine: Int?

    /// Bumped when Pofu should hop.
    public private(set) var celebrations = 0

    // Haptic triggers (interaction spec §6.1). Each counts its events.
    public private(set) var collectTaps = 0
    public private(set) var collectTicks = 0
    public private(set) var collectSuccesses = 0
    public private(set) var buildSwaps = 0
    public private(set) var buildSettles = 0
    /// The last level's settle: the celebration pattern instead of
    /// `.success`.
    public private(set) var finalBuilds = 0

    /// Reduce Motion, from the environment.
    public var reduceMotion = false

    /// A screenshot's moment time: moments render at this offset from
    /// their start, and their timers stop.
    public private(set) var frozenOffset: Double?

    @ObservationIgnored public weak var camera: (any WorldCamera)?
    private let now: @MainActor () -> Date
    private let schedulesCues: Bool
    @ObservationIgnored private var timers: [Task<Void, Never>] = []

    /// How many settled lines Pofu rotates through (fixed order, A17).
    public nonisolated static let settledLineCount = 3
    /// How long a settled line stays (interaction spec §7.2: the bubble).
    public nonisolated static let settledLineLife = 3.2

    /// - Parameters:
    ///   - now: The clock moments start from.
    ///   - schedulesCues: Whether cues fire on a timer; tests turn it off
    ///     and call `advance(to:)`.
    ///   - cheekLineDefaults: Where "once a day" for Pofu's huge-cheeks line
    ///     is remembered; `nil` keeps it in memory (tests, screenshots).
    public init(
        now: @escaping @MainActor () -> Date = { Date() },
        schedulesCues: Bool = true,
        cheekLineDefaults: UserDefaults? = nil,
        calendar: Calendar = .current,
        cheekLineHistory: CheekLineHistory = CheekLineHistory()
    ) {
        self.cheekLineHistory = cheekLineHistory
        self.now = now
        self.schedulesCues = schedulesCues
        self.cheekLineDefaults = cheekLineDefaults
        self.calendar = calendar
        self.visit = VisitProgress(plan: VisitPlan(landing: .settled, showsRepairBanner: false, beats: []))
        if let stored = cheekLineDefaults?.array(forKey: Self.cheekLineKey) as? [Int] {
            self.cheekLineHistory = CheekLineHistory(stored: stored)
        }
    }

    // MARK: - Cheeks (the Living Diorama)

    /// The Home objects' timing (tuning `home.*`).
    public var timing = HomeTiming()
    /// Pofu's cheeks before the collect, held while he presses his paws.
    public private(set) var collectCheeks: CheekStep = .empty
    /// The cheeks have stepped down to empty (the paws pressed).
    public private(set) var cheeksReleased = false
    /// Pofu's paws are pressed to his cheeks.
    public private(set) var pawsPressed = false
    /// This visit's first beat is Pofu saying his cheeks are huge.
    public private(set) var saysCheeksHuge = false
    /// Which of his lines (`CheekLineHistory.variant`).
    public private(set) var cheeksHugeVariant = 0

    /// The lines he has said this week (screenshots replay it across days).
    @ObservationIgnored public private(set) var cheekLineHistory: CheekLineHistory
    @ObservationIgnored private let cheekLineDefaults: UserDefaults?
    @ObservationIgnored private let calendar: Calendar
    nonisolated static let cheekLineKey = "pofu.home.cheeksHuge.history"

    /// The cheek fill for the companion: the pre-collect step until the
    /// paws have pressed, then empty; otherwise from the seeds waiting.
    public func cheekEnergy(uncollected seeds: Int) -> Double {
        if collect != nil {
            return cheeksReleased ? 0 : collectCheeks.companionEnergy
        }
        return CheekStep(uncollected: seeds).companionEnergy
    }

    private func decideCheekLine(for plan: VisitPlan) {
        saysCheeksHuge = false
        guard case .collect(let pouch)? = plan.beats.first else { return }
        // A morning with news: the news speaks first, and the cheeks keep
        // their line for another morning.
        let hasNews = plan.beats.contains { beat in
            if case .news = beat { return true }
            return false
        }
        guard !hasNews else { return }
        let step = CheekStep(uncollected: pouch.total.units)
        let date = now()
        let dayIndex = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        guard cheekLineHistory.allows(step: step, dayIndex: dayIndex) else { return }
        cheeksHugeVariant = cheekLineHistory.variant(dayIndex: dayIndex)
        cheekLineHistory.record(dayIndex: dayIndex, variant: cheeksHugeVariant)
        cheekLineDefaults?.set(cheekLineHistory.stored, forKey: Self.cheekLineKey)
        saysCheeksHuge = true
    }

    // MARK: - The visit

    /// Starts a visit with `plan` (an app landing).
    public func beginVisit(_ plan: VisitPlan) {
        hasBegunVisit = true
        visit = VisitProgress(plan: plan)
        decideCheekLine(for: plan)
        settledLine = nil
        settledAt = visit.isSettled ? now() : nil
    }

    /// The beat whose primary action shows, if any.
    public var currentBeat: VisitBeat? {
        visit.current
    }

    /// The island's growth has news for this visit and it has not been
    /// taken yet.
    public var hasStageNewsWaiting: Bool {
        visit.plan.beats.dropFirst(visit.played).contains { beat in
            if case .news(.stageGrew) = beat { return true }
            return false
        }
    }

    /// An island that grew while the app was closed waits for the news beat's
    /// button: until the visit's plan is known, and while the beat waits.
    public var holdsIslandGrowForNews: Bool {
        !hasBegunVisit || hasStageNewsWaiting
    }

    /// Settled: no bubble, no primary; "Ada sensiz de çalışıyor."
    public var isSettled: Bool {
        visit.isSettled
    }

    /// The primary action of a beat that only needs acknowledging (care,
    /// news, the recap) or that hands over to the island (build).
    public func acknowledgeCurrentBeat() {
        guard visit.current != nil else { return }
        visit.skip()
        noteIfSettled()
    }

    /// Pofu tapped: in the settled state he says one line (rationed, in a
    /// fixed order).
    public func pofuTapped() {
        guard visit.isSettled else { return }
        let next = ((settledLine ?? -1) + 1) % Self.settledLineCount
        settledLine = next
        guard schedulesCues else { return }
        let life = Self.settledLineLife
        timers.append(Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(life))
            guard !Task.isCancelled, let self, self.settledLine == next else { return }
            self.settledLine = nil
        })
    }

    private func noteIfSettled() {
        if visit.isSettled, settledAt == nil {
            settledAt = now()
        }
    }

    // MARK: - Collect

    /// Collects: commits through `commit` (`WorldClock.collect`), then plays
    /// the moment from `sources` to the pill at `target`.
    ///
    /// - Returns: Whether a moment started. A tap during a collect is
    ///   ignored; a collect with nothing to take ends its beat quietly.
    @discardableResult
    public func collectSeeds(
        jarBefore: Int,
        sources: [MomentPoint],
        target: MomentPoint,
        commit: @MainActor () -> SeedPouch?
    ) -> Bool {
        guard collect == nil else { return false }
        collectTaps += 1
        guard let pouch = commit(), pouch.total.units > 0 else {
            completeCollectBeat()
            return false
        }
        let moment = CollectMoment(
            total: pouch.total.units,
            jarBefore: jarBefore,
            sources: sources,
            target: target,
            reduceMotion: reduceMotion
        )
        let active = ActiveMoment(moment: moment, start: now())
        collect = active
        // Pofu presses his paws to his cheeks, then the cheeks step down.
        collectCheeks = CheekStep(uncollected: pouch.total.units)
        cheeksReleased = false
        pawsPressed = !reduceMotion && collectCheeks > .empty
        schedule(moment.cueTimes + [timing.pawsPress, timing.pawsPress + timing.cheekRelease], from: active.start)
        return true
    }

    /// The collect moment's time at `date`.
    public func collectTime(at date: Date) -> Double? {
        guard let collect else { return nil }
        return frozenOffset ?? date.timeIntervalSince(collect.start)
    }

    private func completeCollectBeat() {
        if case .collect = visit.current {
            visit.skip()
            noteIfSettled()
        }
    }

    // MARK: - Build

    /// Builds `station`'s next level: commits through `commit`
    /// (`WorldClock.build`), then plays the moment.
    ///
    /// - Returns: Whether a moment started. Refused while a build is still
    ///   in its compact phase (§2.6: the one input that is refused) or when
    ///   the commit fails.
    @discardableResult
    public func buildStation(
        _ station: StationID,
        maxLevel: Int,
        commit: @MainActor (StationID) -> BuildReceipt?
    ) -> Bool {
        guard buildingStation == nil else { return false }
        guard let receipt = commit(station) else { return false }
        let moment = BuildMoment(
            station: station,
            fromLevel: receipt.level - 1,
            toLevel: receipt.level,
            maxLevel: maxLevel,
            reduceMotion: reduceMotion,
            lowPower: Self.isLowPowerMode,
            cost: receipt.cost.units
        )
        // Celebrations never stack: a new build replaces the last one's
        // tag and adds no second burst.
        let active = ActiveMoment(moment: moment, start: now())
        build = active
        buildingStation = station
        if case .build = visit.current {
            visit.skip()
            noteIfSettled()
        }
        let times = BuildMoment.Cue.allCases.compactMap { moment.time(of: $0) }
        schedule(times, from: active.start)
        // The push-in starts on the tap.
        advance(to: active.start)
        return true
    }

    /// Low Power Mode shortens the build's ceremony of light.
    private static var isLowPowerMode: Bool {
        #if os(iOS)
        ProcessInfo.processInfo.isLowPowerModeEnabled
        #else
        false
        #endif
    }

    /// The build moment's time at `date`.
    public func buildTime(at date: Date) -> Double? {
        guard let build else { return nil }
        return frozenOffset ?? date.timeIntervalSince(build.start)
    }

    // MARK: - Time

    /// Plays every cue due by `date`, once.
    public func advance(to date: Date) {
        if var active = collect {
            let t = frozenOffset ?? date.timeIntervalSince(active.start)
            let cues = active.moment.cues(after: active.played, through: t)
            active.played = max(active.played, t)
            collect = active
            let beat = CheekCollectBeat(from: collectCheeks, timing: timing)
            cheeksReleased = t >= timing.pawsPress
            pawsPressed = !reduceMotion && beat.pawsPressed(at: t)
            for cue in cues {
                play(cue)
            }
        }
        if var active = build {
            let t = frozenOffset ?? date.timeIntervalSince(active.start)
            let cues = active.moment.cues(after: active.played, through: t)
            active.played = max(active.played, t)
            build = active
            for cue in cues {
                play(cue, of: active.moment)
            }
        }
    }

    private func play(_ cue: CollectMoment.Cue) {
        switch cue {
        case .tick:
            collectTicks += 1
        case .success:
            collectSuccesses += 1
        case .end:
            collect = nil
            pawsPressed = false
            completeCollectBeat()
        }
    }

    /// Pofu hops proud, as for a finished build (the payoff at the door).
    public func hopProud() {
        celebrations += 1
    }

    private func play(_ cue: BuildMoment.Cue, of moment: BuildMoment) {
        switch cue {
        case .pushIn:
            camera?.beginBuildFraming(moment.station)
        case .swap:
            buildSwaps += 1
        case .pofuHop:
            celebrations += 1
        case .settle:
            if moment.isFinalLevel {
                finalBuilds += 1
            } else {
                buildSettles += 1
            }
        case .sheetBack:
            buildingStation = nil
            camera?.endBuildFraming(moment.station)
        case .end:
            build = nil
        case .anticipation, .sparkles, .tag, .residentHop:
            break
        }
    }

    /// Stops the moments at `offset` seconds from their start, playing the
    /// cues up to it (screenshots).
    public func freeze(at offset: Double) {
        cancelTimers()
        frozenOffset = offset
        advance(to: now())
    }

    private func schedule(_ times: [Double], from start: Date) {
        guard schedulesCues, frozenOffset == nil else { return }
        let sorted = times.sorted()
        timers.append(Task { @MainActor [weak self] in
            for time in sorted {
                guard let self else { return }
                let wait = start.addingTimeInterval(time).timeIntervalSince(self.now())
                if wait > 0 {
                    try? await Task.sleep(for: .seconds(wait))
                }
                guard !Task.isCancelled, self.frozenOffset == nil else { return }
                self.advance(to: self.now())
            }
        })
        timers.removeAll { $0.isCancelled }
    }

    private func cancelTimers() {
        for timer in timers {
            timer.cancel()
        }
        timers = []
    }
}
