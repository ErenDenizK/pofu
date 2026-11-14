import Foundation

/// A resident who can visit once their island is healed (home layout §5).
public struct VisitorProfile: Hashable, Sendable {
    public var resident: ResidentID
    public var island: IslandID
    /// Their own day: 0 is Monday, 6 is Sunday.
    public var weekday: Int
    /// The station they work in the guest slot on their day.
    public var favourite: StationID

    public init(resident: ResidentID, island: IslandID, weekday: Int, favourite: StationID) {
        self.resident = resident
        self.island = island
        self.weekday = weekday
        self.favourite = favourite
    }
}

/// The tunable numbers of the visiting day (experience v1 §5; kept in sync
/// with `economy.md`).
public struct VisitorRules: Hashable, Sendable {
    /// A resident's weight on their own weekday, against 1 on other days
    /// (in tenths, so hearts can nudge it exactly).
    public var ownDayWeight = 60
    public var otherDayWeight = 10
    /// Each heart adds this many percent to a resident's weight, up to
    /// `heartCap` hearts.
    public var heartPercent = 5
    public var heartCap = 10
    /// Reason weights; a festival is `festivalOwnDayFactor` times likelier
    /// on the resident's own day.
    public var reasonWeights: [VisitReason: Int] = [
        .gift: 3, .help: 2, .festival: 1, .news: 2, .stayOver: 1, .justSitting: 2,
    ]
    public var festivalOwnDayFactor = 4
    /// Healed islands before quiet days and invitations begin.
    public var minHealedForInvitations = 2
    /// Days between quiet days: this many, plus 0 or 1. At least 7 apart
    /// means at most one in any seven.
    public var quietGap = 7
    /// The festival's bonus at the favourite station, in percent.
    public var stationBonusPercent = 50
    /// A seed gift holds this many seeds (ADR-0015: seeds are world
    /// material and never buy screen time).
    public var giftSeeds = 2...5
    /// Whether a gift parcel can hold a decor piece. Off while nothing in
    /// the world can place decor: a parcel then holds seeds only.
    public var decorGifts = false
    /// Island level from which the guest stall (G1), the guest room (H4)
    /// and festivals exist.
    public var guestLevel = 3
    public var historyLimit = 60
    /// Who may visit: `nil` is every resident of the roster. A resident
    /// outside the set never visits, is never drawn for an invitation and
    /// is not on the letter, because the game shows no stand-in for a
    /// visitor it has no painted art for (route R3).
    public var visiting: Set<ResidentID>?

    public init() {}

    /// The rules the game ships with: the residents whose painted
    /// `visitor-<id>` sprite exists, and no `help` visit while the kite has
    /// no painted art. `VisitorArtTests` (PofuWorld) holds `visiting` to the
    /// art that is baked, so a resident is added here only with their art.
    public static let shipped: VisitorRules = {
        var rules = VisitorRules()
        // Damla (batch 78, the erase by script) and Gezgin's postcard. Sumi
        // waits for batch 83: her take reads as Damla's twin.
        rules.visiting = [.damla, .gezgin]
        rules.reasonWeights[.help] = 0
        return rules
    }()
}

/// Who visits on a day: deterministic from the ledger's seed and the day,
/// weighted by weekday and hearts, never the same reason twice in a row for
/// one resident (experience v1 §5).
public struct VisitorSchedule: Sendable {
    public var roster: [VisitorProfile]
    public var rules: VisitorRules

    /// Decor pieces a gift can hold (art follows with the decor batch).
    public static let giftDecor = [
        "decor-moss-stool", "decor-wind-chime", "decor-teacup-plant", "decor-lantern-string",
        "decor-woven-mat", "decor-seed-jar", "decor-pebble-stack", "decor-paper-kite",
    ]

    /// The seven main islands in story order, one per weekday (home layout
    /// §5).
    public static let standardRoster: [VisitorProfile] = [
        VisitorProfile(resident: .sumi, island: "koke", weekday: 0, favourite: .garden),
        VisitorProfile(resident: .damla, island: "caglayan", weekday: 1, favourite: .pond),
        VisitorProfile(resident: .boncuk, island: "emanet", weekday: 2, favourite: .workshop),
        VisitorProfile(resident: .yosun, island: "gezgin", weekday: 3, favourite: .pier),
        VisitorProfile(resident: .tuli, island: "revontuli", weekday: 4, favourite: .lighthouse),
        VisitorProfile(resident: .keeper, island: "ari", weekday: 5, favourite: "hive"),
        VisitorProfile(resident: .nane, island: "mehtap", weekday: 6, favourite: .windmill),
    ]

    public init(roster: [VisitorProfile] = standardRoster, rules: VisitorRules = VisitorRules()) {
        self.roster = roster
        self.rules = rules
    }

    /// The schedule the game ships with (`VisitorRules.shipped`).
    public static let shipped = VisitorSchedule(rules: .shipped)

    /// The roster's residents who may visit (`VisitorRules.visiting`).
    var eligible: [VisitorProfile] {
        guard let visiting = rules.visiting else { return roster }
        return roster.filter { visiting.contains($0.resident) }
    }

    /// What the draw needs to know about the island.
    public struct Context: Hashable, Sendable {
        /// Islands of the roster that are healed.
        public var healed: Set<IslandID>
        public var islandLevel: Int
        /// Stations built at least once.
        public var built: Set<StationID>

        public init(healed: Set<IslandID> = [], islandLevel: Int = 1, built: Set<StationID> = []) {
            self.healed = healed
            self.islandLevel = islandLevel
            self.built = built
        }
    }

    // MARK: - The days

    /// The weekday of `day`: 0 is Monday, 6 is Sunday.
    public static func weekday(of day: LocalDay) -> Int {
        ((daysSinceEpoch(day) % 7) + 7 + 3) % 7
    }

    /// Whole days from 1970-01-01 (proleptic Gregorian).
    static func daysSinceEpoch(_ day: LocalDay) -> Int {
        let y = day.month <= 2 ? day.year - 1 : day.year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let m = day.month
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + day.day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    // MARK: - Drawing

    /// The visit `day` would bring for a game in `state`, drawn with `seed`.
    /// Pure: nothing in `state` changes. `nil` on a quiet day. It assumes
    /// the day before was seen to its end (an unseen visitor from an earlier
    /// day waits and holds the slot until the player opens Pofu).
    public func visit(for day: LocalDay, state: GameState, seed: UInt64) -> DailyVisit? {
        var ledger = state.visitors
        ledger.seed = seed
        ledger.current = nil
        roll(&ledger, to: day, context: Self.context(of: state, catalog: ArchipelagoCatalog.standard, roster: roster))
        return ledger.current
    }

    /// The island as the draw reads it.
    public static func context(of state: GameState, catalog: ArchipelagoCatalog, roster: [VisitorProfile] = standardRoster) -> Context {
        let rosterIslands = Set(roster.map(\.island))
        var healed = Set(state.stations.arrivalOrder).intersection(rosterIslands)
        // A healed wonder island sends its resident: Damla comes on Tuesdays once Çağlayan flows.
        for (wonder, island) in state.wonders.islands where island.stage >= WonderIslands.healedStage {
            let id = IslandID(rawValue: wonder.rawValue)
            if rosterIslands.contains(id) { healed.insert(id) }
        }
        let built = Set(state.stations.levels.filter { $0.value > 0 }.keys)
        return Context(
            healed: healed,
            islandLevel: state.stations.islandLevel(tendedDays: state.tendedDays, catalog: catalog),
            built: built
        )
    }

    /// Starts `day`: the last visitor leaves (if they were seen) and the
    /// new one is drawn. An unseen visitor of an earlier day stays instead,
    /// and today's draw waits (nothing expires, ADR-0017).
    public func roll(_ ledger: inout VisitorLedger, to day: LocalDay, context: Context) {
        if let current = ledger.current, current.day >= day { return }
        guard ledger.retireCurrent(limit: rules.historyLimit) else { return }
        let invitable = context.healed.count >= rules.minHealedForInvitations
        if invitable, ledger.nextQuietDay == nil {
            ledger.nextQuietDay = day.adding(days: quietGap(after: day, seed: ledger.seed))
        }
        if let invitation = ledger.invitation, let profile = eligible.first(where: { $0.resident == invitation.resident }) {
            ledger.settle(visit(of: profile, reason: .festival, day: day, invited: true, context: context, ledger: ledger))
            return
        }
        if invitable, ledger.inviteOpenSince == nil, let quiet = ledger.nextQuietDay, day >= quiet {
            // A quiet day: nobody comes, Pofu hands over the letter.
            ledger.inviteOpenSince = day
            ledger.nextQuietDay = day.adding(days: quietGap(after: day, seed: ledger.seed))
            return
        }
        let candidates = eligible.filter { context.healed.contains($0.island) }
        guard !candidates.isEmpty else {
            ledger.settle(postcard(day: day, context: context, ledger: ledger))
            return
        }
        let weekday = Self.weekday(of: day)
        let weights = candidates.map { profile -> Int in
            let base = profile.weekday == weekday ? rules.ownDayWeight : rules.otherDayWeight
            return base * (100 + rules.heartPercent * min(ledger.hearts(of: profile.resident), rules.heartCap)) / 100
        }
        let profile = candidates[Self.pick(weights, hash: Self.hash(ledger.seed, day, salt: 1))]
        let reason = drawReason(for: profile, day: day, context: context, ledger: ledger)
        ledger.settle(visit(of: profile, reason: reason, day: day, invited: false, context: context, ledger: ledger))
    }

    // MARK: - Pieces

    private func quietGap(after day: LocalDay, seed: UInt64) -> Int {
        rules.quietGap + Int(Self.hash(seed, day, salt: 7) % 2)
    }

    /// Gezgin's postcard, before any island is healed: it drifts in on a
    /// dandelion seed to the front-lip spot.
    private func postcard(day: LocalDay, context: Context, ledger: VisitorLedger) -> DailyVisit {
        let last = ledger.lastReasons[.gezgin]
        // The first one is the postcard itself: the visit's news beat.
        if last == nil {
            return DailyVisit(day: day, resident: .gezgin, reason: .news, slot: context.islandLevel < rules.guestLevel ? .v1 : .g1)
        }
        let options: [(VisitReason, Int)] = [(.news, 5), (.justSitting, 2), (.gift, 1)].filter { $0.0 != last }
        let reason = options[Self.pick(options.map(\.1), hash: Self.hash(ledger.seed, day, salt: 2))].0
        return DailyVisit(
            day: day,
            resident: .gezgin,
            reason: reason,
            slot: context.islandLevel < rules.guestLevel ? .v1 : .g1,
            gift: reason == .gift ? gift(day: day, ledger: ledger, seedsOnly: true) : nil
        )
    }

    private func drawReason(for profile: VisitorProfile, day: LocalDay, context: Context, ledger: VisitorLedger) -> VisitReason {
        let last = ledger.lastReasons[profile.resident]
        let own = profile.weekday == Self.weekday(of: day)
        let options: [(VisitReason, Int)] = VisitReason.allCases.compactMap { reason in
            guard reason != last, var weight = rules.reasonWeights[reason], weight > 0 else { return nil }
            switch reason {
            case .festival:
                // Only where the favourite station stands; their own day
                // is the festival's day.
                guard context.built.contains(profile.favourite), context.islandLevel >= rules.guestLevel else { return nil }
                if own { weight *= rules.festivalOwnDayFactor }
            case .stayOver:
                guard context.islandLevel >= rules.guestLevel else { return nil }
            default:
                break
            }
            return (reason, weight)
        }
        // `news` is always available, so the list is never empty unless it
        // was the last reason; `justSitting` then covers.
        guard !options.isEmpty else { return last == .justSitting ? .news : .justSitting }
        return options[Self.pick(options.map(\.1), hash: Self.hash(ledger.seed, day, salt: 3))].0
    }

    private func visit(
        of profile: VisitorProfile,
        reason: VisitReason,
        day: LocalDay,
        invited: Bool,
        context: Context,
        ledger: VisitorLedger
    ) -> DailyVisit {
        let slot: VisitSlot
        if invited || reason == .festival {
            slot = .v2
        } else if reason == .stayOver {
            slot = .h4
        } else {
            slot = context.islandLevel < rules.guestLevel ? .v1 : .g1
        }
        return DailyVisit(
            day: day,
            resident: profile.resident,
            reason: reason,
            slot: slot,
            gift: reason == .gift ? gift(day: day, ledger: ledger, seedsOnly: false) : nil,
            isInvited: invited
        )
    }

    private func gift(day: LocalDay, ledger: VisitorLedger, seedsOnly: Bool) -> VisitGift {
        let h = Self.hash(ledger.seed, day, salt: 4)
        let unowned = Self.giftDecor.filter { !ledger.decor.contains($0) }
        if rules.decorGifts, !seedsOnly, !unowned.isEmpty, h % 5 < 2 {
            return .decor(unowned[Int((h >> 8) % UInt64(unowned.count))])
        }
        let span = rules.giftSeeds.upperBound - rules.giftSeeds.lowerBound + 1
        return .seeds(rules.giftSeeds.lowerBound + Int((h >> 8) % UInt64(span)))
    }

    // MARK: - Hashing

    /// A well-mixed 64-bit value from the seed, the day and a salt
    /// (SplitMix64 over the day number).
    static func hash(_ seed: UInt64, _ day: LocalDay, salt: UInt64) -> UInt64 {
        var z = seed &+ UInt64(bitPattern: Int64(daysSinceEpoch(day))) &* 0x9E37_79B9_7F4A_7C15 &+ salt &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// The index a hash lands on among `weights`.
    static func pick(_ weights: [Int], hash: UInt64) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else { return 0 }
        var r = Int(hash % UInt64(total))
        for (index, weight) in weights.enumerated() {
            if r < weight { return index }
            r -= weight
        }
        return weights.count - 1
    }
}
