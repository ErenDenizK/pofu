import Foundation

/// One thing a Screen Time extension saw, written to the App Group inbox
/// for the app to ingest into its state and event log (ADR-0003).
///
/// Records are small, immutable, and versioned: an extension from a newer
/// build can write a record an older app cannot read, and the app must
/// leave it alone rather than misread it. `version` is decoded first, and a
/// record from a newer version fails with `unsupportedVersion`.
public struct ScreenTimeRecord: Hashable, Sendable, Identifiable {
    /// The format this build writes and the newest it reads. Version 2
    /// added `shieldShown`, `quickCheckStarted`, `passEndedClosed`, and
    /// `openRequestCancelled` (gate v2); version 1 records stay readable.
    public static let currentVersion = 2

    public enum Kind: Hashable, Sendable, Codable {
        /// The configuration extension drew the shield over `app` in
        /// `scene`. A reach, unless the scene says otherwise; the app
        /// resolves it with whatever the user did next (or did not do).
        case shieldShown(app: ShieldedApp, scene: ShieldScene)
        /// The user tapped the shield's primary button ("Skip it"): an
        /// impulse resisted at the shield.
        case shieldResisted(app: ShieldedApp)
        /// The user tapped "Open with Pofu" (or "Breathe with Pofu"): they
        /// want to open the app, and Hop! should run for it when they come
        /// to Pofu.
        case openRequested(app: ShieldedApp)
        /// The user tapped "Skip it" while the shield waited for the
        /// notification tap: the request is withdrawn and the reach
        /// resisted.
        case openRequestCancelled(app: ShieldedApp)
        /// "Just 3 minutes" on the shield: the action extension lifted the
        /// shield from `app` until `until`, for the pass `passID`.
        case quickCheckStarted(app: ShieldedApp, passID: UUID, until: Date)
        /// "Done, close it" on the shield that returned when a pass ended.
        /// Closing an app whose time is up is not a resisted reach.
        case passEndedClosed(app: ShieldedApp)
        /// DeviceActivity measured `minutes` of guarded use today.
        case usageThresholdReached(minutes: Int)
        /// The monitor put the shield back when the pass `passID` ended.
        case shieldRestored(passID: UUID)
    }

    public let version: Int
    public let id: UUID
    public let at: Date
    public let kind: Kind

    public init(id: UUID = UUID(), at: Date, kind: Kind, version: Int = ScreenTimeRecord.currentVersion) {
        self.version = version
        self.id = id
        self.at = at
        self.kind = kind
    }
}

extension ScreenTimeRecord {
    /// The app the record is about, if it is about one.
    public var app: ShieldedApp? {
        switch kind {
        case .shieldShown(let app, _), .shieldResisted(let app), .openRequested(let app),
            .openRequestCancelled(let app), .quickCheckStarted(let app, _, _), .passEndedClosed(let app):
            app
        case .usageThresholdReached, .shieldRestored:
            nil
        }
    }

    /// The same record with its app replaced by `transform(app)`, for
    /// filling in names the shield directory learned.
    public func mappingApp(_ transform: (ShieldedApp) -> ShieldedApp) -> ScreenTimeRecord {
        let mapped: Kind
        switch kind {
        case .shieldShown(let app, let scene): mapped = .shieldShown(app: transform(app), scene: scene)
        case .shieldResisted(let app): mapped = .shieldResisted(app: transform(app))
        case .openRequested(let app): mapped = .openRequested(app: transform(app))
        case .openRequestCancelled(let app): mapped = .openRequestCancelled(app: transform(app))
        case .quickCheckStarted(let app, let passID, let until): mapped = .quickCheckStarted(app: transform(app), passID: passID, until: until)
        case .passEndedClosed(let app): mapped = .passEndedClosed(app: transform(app))
        case .usageThresholdReached, .shieldRestored: return self
        }
        return ScreenTimeRecord(id: id, at: at, kind: mapped, version: version)
    }
}

/// Which shield the configuration extension drew (gate v2, section 5).
public enum ShieldScene: String, Hashable, Sendable, Codable, CaseIterable {
    /// A reach: the default shield, with its copy ladder.
    case reach
    /// A reach past the daily hour: the breathing state.
    case breath
    /// The shield waiting for the notification tap after "Open with Pofu".
    /// A redraw of a reach already counted.
    case waiting
    /// The shield that came back when a pass ended. Not a reach.
    case passEnded

    /// Whether showing this shield is a new reach.
    public var countsAsReach: Bool {
        switch self {
        case .reach, .breath: true
        case .waiting, .passEnded: false
        }
    }
}

/// Why a record could not be read.
public enum ScreenTimeRecordError: Error, Hashable, Sendable {
    /// Written by a newer build; leave it for an updated app.
    case unsupportedVersion(Int)
}

extension ScreenTimeRecord: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, id, at, kind
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version <= Self.currentVersion else {
            throw ScreenTimeRecordError.unsupportedVersion(version)
        }
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            at: try container.decode(Date.self, forKey: .at),
            kind: try container.decode(Kind.self, forKey: .kind),
            version: version
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(id, forKey: .id)
        try container.encode(at, forKey: .at)
        try container.encode(kind, forKey: .kind)
    }
}

/// The names Pofu gives DeviceActivity monitors and events, shared by the
/// app (which schedules them) and the monitor extension (which receives
/// them), so neither has to guess what the other meant.
public enum ScreenTimeNames {
    /// The prefix of the one-off activity that ends a pass.
    public static let passActivityPrefix = "pofu.pass."

    /// The activity whose interval ends when pass `passID` does.
    public static func passActivity(_ passID: UUID) -> String {
        passActivityPrefix + passID.uuidString
    }

    /// The pass a pass activity belongs to; `nil` for any other activity.
    public static func passID(fromActivity name: String) -> UUID? {
        guard name.hasPrefix(passActivityPrefix) else { return nil }
        return UUID(uuidString: String(name.dropFirst(passActivityPrefix.count)))
    }
}
