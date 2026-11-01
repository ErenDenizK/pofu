import Foundation
import PofuCore
import PofuPersistence

/// What the live Screen Time gate has set up, in one small file in the App
/// Group: the user's selection, the named shields, the usage schedules, and
/// the passes that lift shields.
///
/// The app is its only writer. The monitor extension reads it to put the
/// shields back when a pass ends, so it holds everything needed to rebuild
/// the shields without the app running.
public struct LiveShieldState: Hashable, Sendable {
    public static let currentVersion = 1
    public static let fileName = "screen-time-gate.json"

    public var version: Int
    /// What the user picked, as Pofu's opaque tokens.
    public var selection: DistractionSelection
    /// The picker's own encoding of the selection, so the picker can show
    /// it again exactly as the user left it. Opaque.
    public var pickerData: Data?
    /// Shields by name.
    public var shields: [String: DistractionSelection]
    /// Usage schedules being monitored.
    public var thresholds: [ThresholdSchedule]
    /// Passes that lift shields until they end.
    public var lifts: [ShieldLift]
    /// Lifts that ended recently, kept for `endedLiftMemory` so the
    /// returning shield can speak of the pass that just ended and the
    /// chain rule can see the last quick check (gate v2).
    public var endedLifts: [ShieldLift]

    /// How long ended lifts are remembered.
    public static let endedLiftMemory: TimeInterval = 60 * 60

    public init(
        selection: DistractionSelection = .empty,
        pickerData: Data? = nil,
        shields: [String: DistractionSelection] = [:],
        thresholds: [ThresholdSchedule] = [],
        lifts: [ShieldLift] = [],
        endedLifts: [ShieldLift] = [],
        version: Int = LiveShieldState.currentVersion
    ) {
        self.version = version
        self.selection = selection
        self.pickerData = pickerData
        self.shields = shields
        self.thresholds = thresholds
        self.lifts = lifts
        self.endedLifts = endedLifts
    }

    /// The file in `location`.
    public static func file(in location: StorageLocation) -> JSONFile<LiveShieldState> {
        JSONFile(url: location.directory.appendingPathComponent(fileName))
    }

    /// What each named shield should cover at `date`, with the lifts of
    /// running passes taken out. `excluding` names a pass that has just
    /// ended, whose lift no longer counts even if its callback came early.
    public func effectiveShields(at date: Date, excluding passID: UUID? = nil) -> [ShieldID: EffectiveShield] {
        let exempt = lifts.exemptTokens(at: date, excluding: passID)
        let exemptApplications = Set((exempt[.application] ?? []).map { ApplicationToken($0) })
        let exemptCategories = Set((exempt[.category] ?? []).map { CategoryToken($0) })
        let exemptDomains = Set((exempt[.webDomain] ?? []).map { WebDomainToken($0) })
        var result: [ShieldID: EffectiveShield] = [:]
        for (name, selection) in shields {
            result[ShieldID(rawValue: name)] = EffectiveShield(
                applications: selection.applications.subtracting(exemptApplications),
                categories: selection.categories.subtracting(exemptCategories),
                exceptApplications: exemptApplications,
                webDomains: selection.webDomains.subtracting(exemptDomains)
            )
        }
        return result
    }

    /// Drops lifts that have ended by `date`, remembering them for a while
    /// in `endedLifts`.
    ///
    /// - Returns: The passes whose lifts were dropped.
    @discardableResult
    public mutating func pruneLifts(at date: Date) -> [UUID] {
        let ended = lifts.filter { $0.until <= date }
        lifts.removeAll { $0.until <= date }
        endedLifts.removeAll { lift in ended.contains { $0.passID == lift.passID } }
        endedLifts.append(contentsOf: ended)
        endedLifts.removeAll { date.timeIntervalSince($0.until) > Self.endedLiftMemory }
        return ended.map(\.passID)
    }

    /// Ends the lift of `passID` early, remembering it as ended at `date`.
    public mutating func endLift(_ passID: UUID, at date: Date) {
        guard let index = lifts.firstIndex(where: { $0.passID == passID }) else { return }
        let lift = lifts.remove(at: index)
        let end = min(lift.until, max(lift.from, date))
        endedLifts.append(ShieldLift(passID: lift.passID, app: lift.app, from: lift.from, until: end, origin: lift.origin))
        endedLifts.removeAll { date.timeIntervalSince($0.until) > Self.endedLiftMemory }
    }

    /// The pass that ended last for any of `tokens` by `date`, whether
    /// the app has pruned it yet or not.
    public func lastEndedLift(for tokens: Set<String>, at date: Date) -> ShieldLift? {
        (lifts + endedLifts)
            .filter { tokens.contains($0.app.token) && $0.until <= date.addingTimeInterval(1) }
            .max { $0.until < $1.until }
    }

    /// When the latest quick check from the shield ends or ended.
    public var lastQuickCheckEnd: Date? {
        (lifts + endedLifts)
            .filter { $0.origin == .shieldQuickCheck }
            .map(\.until)
            .max()
    }
}

extension LiveShieldState: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, selection, pickerData, shields, thresholds, lifts, endedLifts
    }

    /// Fields added after version 1 are optional, so an older file loads.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            selection: try container.decodeIfPresent(DistractionSelection.self, forKey: .selection) ?? .empty,
            pickerData: try container.decodeIfPresent(Data.self, forKey: .pickerData),
            shields: try container.decodeIfPresent([String: DistractionSelection].self, forKey: .shields) ?? [:],
            thresholds: try container.decodeIfPresent([ThresholdSchedule].self, forKey: .thresholds) ?? [],
            lifts: try container.decodeIfPresent([ShieldLift].self, forKey: .lifts) ?? [],
            endedLifts: try container.decodeIfPresent([ShieldLift].self, forKey: .endedLifts) ?? [],
            version: try container.decodeIfPresent(Int.self, forKey: .version) ?? LiveShieldState.currentVersion
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(selection, forKey: .selection)
        try container.encodeIfPresent(pickerData, forKey: .pickerData)
        try container.encode(shields, forKey: .shields)
        try container.encode(thresholds, forKey: .thresholds)
        try container.encode(lifts, forKey: .lifts)
        try container.encode(endedLifts, forKey: .endedLifts)
    }
}

/// One named shield as it should be applied right now.
public struct EffectiveShield: Hashable, Sendable {
    /// Apps shielded by name.
    public var applications: Set<ApplicationToken>
    /// Categories shielded as a whole.
    public var categories: Set<CategoryToken>
    /// Apps a pass lifted, exempt even from their category's shield.
    public var exceptApplications: Set<ApplicationToken>
    public var webDomains: Set<WebDomainToken>

    public init(
        applications: Set<ApplicationToken>,
        categories: Set<CategoryToken>,
        exceptApplications: Set<ApplicationToken>,
        webDomains: Set<WebDomainToken>
    ) {
        self.applications = applications
        self.categories = categories
        self.exceptApplications = exceptApplications
        self.webDomains = webDomains
    }

    /// Whether nothing is shielded.
    public var isEmpty: Bool {
        applications.isEmpty && categories.isEmpty && webDomains.isEmpty
    }
}
