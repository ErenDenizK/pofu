import Foundation

/// One thing a Screen Time extension saw, written to the App Group inbox
/// for the app to ingest into its state and event log (ADR-0003).
///
/// Records are small, immutable, and versioned: an extension from a newer
/// build can write a record an older app cannot read, and the app must
/// leave it alone rather than misread it. `version` is decoded first, and a
/// record from a newer version fails with `unsupportedVersion`.
public struct ScreenTimeRecord: Hashable, Sendable, Identifiable {
    /// The format this build writes and the newest it reads.
    public static let currentVersion = 1

    public enum Kind: Hashable, Sendable, Codable {
        /// The user tapped the shield's primary button ("Skip it"): an
        /// impulse resisted at the shield.
        case shieldResisted(app: ShieldedApp)
        /// The user tapped "Talk to Pofu": they want to open the app, and
        /// Hop! should run for it when they come to Pofu.
        case openRequested(app: ShieldedApp)
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
