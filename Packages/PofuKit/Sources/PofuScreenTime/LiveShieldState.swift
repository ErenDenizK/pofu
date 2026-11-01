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
public struct LiveShieldState: Hashable, Sendable, Codable {
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

    public init(
        selection: DistractionSelection = .empty,
        pickerData: Data? = nil,
        shields: [String: DistractionSelection] = [:],
        thresholds: [ThresholdSchedule] = [],
        lifts: [ShieldLift] = [],
        version: Int = LiveShieldState.currentVersion
    ) {
        self.version = version
        self.selection = selection
        self.pickerData = pickerData
        self.shields = shields
        self.thresholds = thresholds
        self.lifts = lifts
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

    /// Drops lifts that have ended by `date`.
    ///
    /// - Returns: The passes whose lifts were dropped.
    @discardableResult
    public mutating func pruneLifts(at date: Date) -> [UUID] {
        let ended = lifts.filter { $0.until <= date }.map(\.passID)
        lifts.removeAll { $0.until <= date }
        return ended
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
