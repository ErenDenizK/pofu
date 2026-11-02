import Foundation
import PofuCore

/// One piece of news a visit may carry (app–game boundary §6.2, priority 4).
public enum VisitNews: Hashable, Sendable {
    /// The home island grew a stage overnight.
    case stageGrew(Int)
    /// A new island drifted close.
    case islandArrived(IslandID)
}

/// One beat of a visit, in the queue's priority order (§6.2).
public enum VisitBeat: Hashable, Sendable {
    /// Wellbeing is low: Pofu asks to put the phone down together. Once a
    /// day.
    case care
    /// The away delta and Collect, whenever seeds wait.
    case collect(SeedPouch)
    /// One piece of news a visit.
    case news(VisitNews)
    /// One build a visit, only when the seeds cover it.
    case build(StationID, level: Int)
    /// The weekly recap, first visit after Sunday 18:00.
    case weeklyRecap
}

/// How the app lands (§6.1).
public enum VisitLanding: Hashable, Sendable {
    /// Beats are waiting: Pofu faces you with the first one.
    case visit
    /// Nothing is waiting: the world goes on without you.
    case settled
    /// Bedtime to morning: the islands sleep; nothing new (A21).
    case night
}

/// What the queue is built from: the world now and what the visit's past
/// already showed. All of it is plain data so the rules stay testable.
public struct VisitInputs: Sendable {
    public var now: Date
    public var world: WorldSnapshot
    /// An app's guard is not set up or silent: the repair banner shows
    /// while it is true (never inside the minute).
    public var isGuardBroken: Bool
    /// The visit is "a minute with Pofu" (§3.3), not an icon landing.
    public var isMinute: Bool
    /// When the last visit settled; a reopen within 15 minutes lands
    /// settled (A15).
    public var lastSettled: Date?
    /// When the care beat last played (once a day).
    public var lastCareBeat: Date?
    /// When the weekly recap was last seen; `nil` means never due (a new
    /// user's first week has nothing to recap).
    public var lastRecapSeen: Date?
    public var news: VisitNews?
    public var calendar: Calendar

    public init(
        now: Date,
        world: WorldSnapshot,
        isGuardBroken: Bool = false,
        isMinute: Bool = false,
        lastSettled: Date? = nil,
        lastCareBeat: Date? = nil,
        lastRecapSeen: Date? = nil,
        news: VisitNews? = nil,
        calendar: Calendar
    ) {
        self.now = now
        self.world = world
        self.isGuardBroken = isGuardBroken
        self.isMinute = isMinute
        self.lastSettled = lastSettled
        self.lastCareBeat = lastCareBeat
        self.lastRecapSeen = lastRecapSeen
        self.news = news
        self.calendar = calendar
    }
}

/// The plan for one landing.
public struct VisitPlan: Hashable, Sendable {
    public var landing: VisitLanding
    /// The native repair banner replaces the pill row (priority 1). It
    /// counts toward the three beats but is not the primary action.
    public var showsRepairBanner: Bool
    public var beats: [VisitBeat]

    public init(landing: VisitLanding, showsRepairBanner: Bool, beats: [VisitBeat]) {
        self.landing = landing
        self.showsRepairBanner = showsRepairBanner
        self.beats = beats
    }
}

/// The visit queue (app–game boundary §6.2): at most three beats, in
/// priority order, then the world settles. Pure: the same inputs always
/// give the same plan (A17).
public enum VisitQueue {
    public static let maxBeats = 3
    /// A reopen this soon after settling lands settled (A15).
    public static let reopenGrace: TimeInterval = 15 * 60
    /// Below this wellbeing Pofu asks for care (§6.2, priority 2).
    public static let careThreshold = 25.0

    public static func plan(_ inputs: VisitInputs) -> VisitPlan {
        let world = inputs.world
        let banner = inputs.isGuardBroken && !inputs.isMinute
        let budget = maxBeats - (banner ? 1 : 0)

        if world.isBedtime {
            return VisitPlan(landing: .night, showsRepairBanner: banner, beats: [])
        }
        if let settled = inputs.lastSettled, inputs.now.timeIntervalSince(settled) < reopenGrace, inputs.now >= settled {
            return VisitPlan(landing: .settled, showsRepairBanner: banner, beats: [])
        }

        var beats: [VisitBeat] = []
        if world.wellbeing < careThreshold, !sameDay(inputs.lastCareBeat, inputs.now, calendar: inputs.calendar) {
            beats.append(.care)
        }
        let collects = !world.pending.isEmpty && !world.isHolding
        if collects {
            beats.append(.collect(world.pending))
        }
        if let news = inputs.news {
            beats.append(.news(news))
        }
        // The collect beat comes first, so its seeds count toward the build.
        let seeds = world.jar + (collects ? world.pending.total : .zero)
        if let build = affordableBuild(in: world, seeds: seeds) {
            beats.append(build)
        }
        if recapDue(now: inputs.now, lastSeen: inputs.lastRecapSeen, calendar: inputs.calendar) {
            beats.append(.weeklyRecap)
        }
        let kept = Array(beats.prefix(max(budget, 0)))
        return VisitPlan(landing: kept.isEmpty ? .settled : .visit, showsRepairBanner: banner, beats: kept)
    }

    /// The cheapest next level the seeds cover, among open stations on
    /// the islands that arrived; ties go to the catalog's order.
    public static func affordableBuild(in world: WorldSnapshot, seeds: Energy) -> VisitBeat? {
        var best: (status: StationStatus, cost: Energy)?
        for status in world.stations where status.isOpen && world.islands.contains(status.island) {
            guard let cost = status.nextCost, cost <= seeds else { continue }
            if let current = best, current.cost <= cost {
                continue
            }
            best = (status, cost)
        }
        guard let best else { return nil }
        return .build(best.status.id, level: best.status.level + 1)
    }

    /// The recap is due once the most recent Sunday 18:00 has passed since
    /// it was last seen.
    public static func recapDue(now: Date, lastSeen: Date?, calendar: Calendar) -> Bool {
        guard let lastSeen else { return false }
        guard let sunday = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 18, minute: 0, second: 0, weekday: 1),
            matchingPolicy: .nextTime,
            direction: .backward
        ) else { return false }
        return lastSeen < sunday && sunday <= now
    }

    static func sameDay(_ date: Date?, _ other: Date, calendar: Calendar) -> Bool {
        guard let date else { return false }
        return calendar.isDate(date, inSameDayAs: other)
    }
}

/// Where a visit is: its plan and the beats already played.
public struct VisitProgress: Hashable, Sendable {
    public private(set) var plan: VisitPlan
    public private(set) var played: Int

    public init(plan: VisitPlan) {
        self.plan = plan
        self.played = 0
    }

    /// The beat Pofu is on, or `nil` once settled.
    public var current: VisitBeat? {
        played < plan.beats.count ? plan.beats[played] : nil
    }

    /// Settled: no beat left, no primary action (§6.2).
    public var isSettled: Bool {
        current == nil
    }

    /// Marks `beat` played if it is the current one. Returns whether the
    /// visit moved on.
    @discardableResult
    public mutating func complete(_ beat: VisitBeat) -> Bool {
        guard current == beat else { return false }
        played += 1
        return true
    }

    /// Marks the current beat played, whatever it is.
    public mutating func skip() {
        if current != nil {
            played += 1
        }
    }

    /// Settles at once (a station sheet opened mid-visit, the app left).
    public mutating func settle() {
        played = plan.beats.count
    }
}

/// Today's honest readout for Home's Today card (gate v2 §8): beads, one
/// per reach (filled when skipped), and guarded minutes in DeviceActivity's
/// 15-minute steps, never finer than Pofu can know.
public struct TodaySummary: Hashable, Sendable {
    /// One per reach today, in order; `true` when it was skipped.
    public var beads: [Bool]
    public var guardedMinutes: Int
    public var dailyHourMinutes: Int

    public static let step = 15

    public init(beads: [Bool], guardedMinutes: Int, dailyHourMinutes: Int) {
        self.beads = beads
        self.guardedMinutes = max(guardedMinutes, 0)
        self.dailyHourMinutes = max(dailyHourMinutes, Self.step)
    }

    public var reaches: Int {
        beads.count
    }

    public var skips: Int {
        beads.filter { $0 }.count
    }

    /// "At least" this many minutes: the measured time floored to a step.
    public var guardedAtLeast: Int {
        guardedMinutes / Self.step * Self.step
    }

    /// The daily hour in steps (four for an hour).
    public var segments: Int {
        max(1, (dailyHourMinutes + Self.step - 1) / Self.step)
    }

    /// Steps used, at most every segment.
    public var filledSegments: Int {
        min(segments, guardedAtLeast / Self.step)
    }
}
