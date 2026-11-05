import Foundation

/// A resident of the archipelago (interaction spec §12.2). Lives in
/// `PofuCore` because the visitors' ledger counts hearts per resident;
/// `PofuWorld` reads it.
public struct ResidentID: RawRepresentable, Hashable, Sendable, Comparable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String {
        rawValue
    }

    public static func < (lhs: ResidentID, rhs: ResidentID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Mochi, the bunny who keeps the çay ocağı.
    public static let mochi = ResidentID(rawValue: "mochi")
    /// Fındık, the hedgehog of the workshop.
    public static let findik = ResidentID(rawValue: "findik")

    // The residents of the healed main islands, who visit (experience v1 §5).
    /// Gezgin, the whale: his postcard comes before any island is healed.
    public static let gezgin = ResidentID(rawValue: "gezgin")
    /// Sumi of Köke.
    public static let sumi = ResidentID(rawValue: "sumi")
    /// Damla of Çağlayan.
    public static let damla = ResidentID(rawValue: "damla")
    /// Boncuk of Emanet.
    public static let boncuk = ResidentID(rawValue: "boncuk")
    /// Yosun of Gezgin's island.
    public static let yosun = ResidentID(rawValue: "yosun")
    /// Tuli of Revontuli.
    public static let tuli = ResidentID(rawValue: "tuli")
    /// The bees' keeper of Arı.
    public static let keeper = ResidentID(rawValue: "keeper")
    /// Nane of Mehtap.
    public static let nane = ResidentID(rawValue: "nane")
}

/// Why a visitor came (experience v1 §5.1): one reason a visit.
public enum VisitReason: String, CaseIterable, Hashable, Sendable, Codable {
    /// A wrapped parcel; a tap opens it.
    case gift
    /// Something of theirs needs a tap: a thank-you line and a heart.
    case help
    /// Their island's day: +50 % at their favourite station.
    case festival
    /// A rumour or a letter.
    case news
    /// They sleep in the guest room (H4).
    case stayOver
    /// They sit with Pofu: warmth only.
    case justSitting
}

/// Where the visitor stands on the island (experience v1 §5.3).
public enum VisitSlot: String, CaseIterable, Hashable, Sendable, Codable {
    /// The front-lip guest spot, before the harbor.
    case v1
    /// The guest stall, from island level 3.
    case g1
    /// Beside the favourite station's worker (festival, invited).
    case v2
    /// The guest room, for stay-over nights.
    case h4
}

/// What a gift holds. Seeds are world material and a decor piece is a
/// keepsake: neither buys screen time (ADR-0015).
public enum VisitGift: Hashable, Sendable, Codable {
    case seeds(Int)
    case decor(String)
}

/// Where a visit is: drawn at the day's start and unseen, on the island,
/// greeted, then gone.
public enum VisitState: String, Hashable, Sendable, Codable {
    /// Drawn for the day; the player has not opened Pofu since.
    case arriving
    /// The player saw the arrival.
    case present
    /// The player greeted them (a heart counted).
    case greeted
    /// Left on a later day. Only history holds departed visits.
    case departed
}

/// One day's visitor.
public struct DailyVisit: Hashable, Sendable, Codable {
    public var day: LocalDay
    public var resident: ResidentID
    public var reason: VisitReason
    public var slot: VisitSlot
    public var gift: VisitGift?
    public var giftOpened = false
    public var helped = false
    /// The player asked for this visit on a quiet day: a bigger scene and
    /// the favourite-station bonus.
    public var isInvited = false
    public internal(set) var state: VisitState

    public init(
        day: LocalDay,
        resident: ResidentID,
        reason: VisitReason,
        slot: VisitSlot,
        gift: VisitGift? = nil,
        isInvited: Bool = false,
        state: VisitState = .arriving
    ) {
        self.day = day
        self.resident = resident
        self.reason = reason
        self.slot = slot
        self.gift = gift
        self.isInvited = isInvited
        self.state = state
    }

    /// Whether the favourite-station bonus runs today.
    public var hasStationBonus: Bool {
        reason == .festival || isInvited
    }
}

/// The player's request on a quiet day: this resident comes tomorrow. It
/// never expires and never costs anything (ADR-0017).
public struct Invitation: Hashable, Sendable, Codable {
    public var resident: ResidentID
    public var askedOn: LocalDay

    public init(resident: ResidentID, askedOn: LocalDay) {
        self.resident = resident
        self.askedOn = askedOn
    }
}

/// Who came, who is here, and the hearts they left. Hearts count visits,
/// never streaks (A4): a missed day costs nothing.
public struct VisitorLedger: Hashable, Sendable {
    /// Seeds the draw. The same seed and the same days draw the same
    /// visitors.
    public internal(set) var seed: UInt64
    /// The visitor here now; `nil` on a quiet day or before the first draw.
    public internal(set) var current: DailyVisit?
    /// A quiet day's letter, open until the player picks a resident.
    public internal(set) var inviteOpenSince: LocalDay?
    /// The resident the player asked for; they arrive on the next draw.
    public internal(set) var invitation: Invitation?
    /// The next quiet day, once two islands are healed.
    public internal(set) var nextQuietDay: LocalDay?
    public internal(set) var hearts: [ResidentID: Int]
    /// The reason of each resident's latest visit: no reason twice in a row.
    public internal(set) var lastReasons: [ResidentID: VisitReason]
    /// Decor pieces visitors gave.
    public internal(set) var decor: [String]
    /// Past visits, newest last, capped at `VisitorRules.historyLimit`.
    public internal(set) var history: [DailyVisit]

    public static let defaultSeed: UInt64 = 0x706F_6675_C0FF_EE01

    public init(seed: UInt64 = Self.defaultSeed) {
        self.seed = seed
        current = nil
        inviteOpenSince = nil
        invitation = nil
        nextQuietDay = nil
        hearts = [:]
        lastReasons = [:]
        decor = []
        history = []
    }

    /// Whether the player has met `resident` (a heart or a past visit).
    public func hasMet(_ resident: ResidentID) -> Bool {
        (hearts[resident] ?? 0) > 0 || history.contains { $0.resident == resident } || current?.resident == resident
    }

    /// Residents the player has met, for the invitation letter.
    public var met: [ResidentID] {
        var seen = Set(hearts.filter { $0.value > 0 }.keys)
        seen.formUnion(history.map(\.resident))
        if let current { seen.insert(current.resident) }
        return seen.sorted()
    }

    public func hearts(of resident: ResidentID) -> Int {
        hearts[resident] ?? 0
    }
}

extension VisitorLedger: Codable {
    private enum CodingKeys: String, CodingKey {
        case seed, current, inviteOpenSince, invitation, nextQuietDay, hearts, lastReasons, decor, history
    }

    /// Every field is optional on read, so a save from before visitors
    /// existed (or from an older shape) loads as a fresh ledger.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(seed: try container.decodeIfPresent(UInt64.self, forKey: .seed) ?? Self.defaultSeed)
        current = try container.decodeIfPresent(DailyVisit.self, forKey: .current)
        inviteOpenSince = try container.decodeIfPresent(LocalDay.self, forKey: .inviteOpenSince)
        invitation = try container.decodeIfPresent(Invitation.self, forKey: .invitation)
        nextQuietDay = try container.decodeIfPresent(LocalDay.self, forKey: .nextQuietDay)
        hearts = (try container.decodeIfPresent([ResidentID: Int].self, forKey: .hearts) ?? [:]).mapValues { max(0, $0) }
        lastReasons = try container.decodeIfPresent([ResidentID: VisitReason].self, forKey: .lastReasons) ?? [:]
        decor = try container.decodeIfPresent([String].self, forKey: .decor) ?? []
        history = try container.decodeIfPresent([DailyVisit].self, forKey: .history) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(seed, forKey: .seed)
        try container.encodeIfPresent(current, forKey: .current)
        try container.encodeIfPresent(inviteOpenSince, forKey: .inviteOpenSince)
        try container.encodeIfPresent(invitation, forKey: .invitation)
        try container.encodeIfPresent(nextQuietDay, forKey: .nextQuietDay)
        try container.encode(hearts, forKey: .hearts)
        try container.encode(lastReasons, forKey: .lastReasons)
        try container.encode(decor, forKey: .decor)
        try container.encode(history, forKey: .history)
    }
}

// MARK: - Changes

extension VisitorLedger {
    /// The player opened Pofu: an unseen arrival lands.
    mutating func noteSeen() {
        if current?.state == .arriving {
            current?.state = .present
        }
    }

    /// The player greeted today's visitor.
    mutating func greet() {
        guard var visit = current, visit.state != .greeted else { return }
        visit.state = .greeted
        current = visit
        hearts[visit.resident, default: 0] += 1
    }

    /// The player opened the parcel.
    /// - Returns: The gift, once.
    mutating func openGift() -> VisitGift? {
        guard var visit = current, let gift = visit.gift, !visit.giftOpened else { return nil }
        visit.giftOpened = true
        current = visit
        if case .decor(let piece) = gift, !decor.contains(piece) {
            decor.append(piece)
        }
        return gift
    }

    /// The player tapped the thing that needed help: +1 heart.
    /// - Returns: Whether it counted.
    @discardableResult
    mutating func help() -> Bool {
        guard var visit = current, visit.reason == .help, !visit.helped else { return false }
        visit.helped = true
        current = visit
        hearts[visit.resident, default: 0] += 1
        return true
    }

    /// The player picked a resident they have met from the letter.
    /// - Returns: Whether the invitation was taken.
    @discardableResult
    mutating func invite(_ resident: ResidentID, on day: LocalDay) -> Bool {
        guard inviteOpenSince != nil, hasMet(resident) else { return false }
        invitation = Invitation(resident: resident, askedOn: day)
        inviteOpenSince = nil
        return true
    }

    /// Retires the visitor of an earlier day. An unseen arrival stays:
    /// nothing is missed and nothing expires.
    /// - Returns: Whether the visitor left (or none was here).
    mutating func retireCurrent(limit: Int) -> Bool {
        guard let visit = current else { return true }
        guard visit.state != .arriving else { return false }
        var gone = visit
        gone.state = .departed
        history.append(gone)
        if history.count > limit {
            history.removeFirst(history.count - limit)
        }
        current = nil
        return true
    }

    /// Records a drawn visit as today's.
    mutating func settle(_ visit: DailyVisit) {
        current = visit
        lastReasons[visit.resident] = visit.reason
        if visit.isInvited {
            invitation = nil
        }
    }
}
