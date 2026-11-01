import Foundation

/// The user's choices about Pofu: its name, the apps it guards, and how far
/// setup has come.
public struct UserProfile: Hashable, Sendable {
    public static let defaultName = "Pofu"
    /// Names are short: they appear in headlines and speech bubbles.
    public static let maximumNameLength = 20

    /// What the user calls their companion. Always non-empty.
    public var companionName: String {
        didSet { companionName = Self.sanitizedName(companionName) }
    }
    /// The apps the user wants Pofu to guard, in the order they chose them.
    public var protectedApps: [ProtectedApp]
    public var hasCompletedOnboarding: Bool
    /// When each app's automation last reached Pofu. An app with an entry
    /// is verified: its automation fired at least once.
    public var lastCheckIn: [ProtectedApp: Date]

    public init(
        companionName: String = UserProfile.defaultName,
        protectedApps: [ProtectedApp] = [],
        hasCompletedOnboarding: Bool = false,
        lastCheckIn: [ProtectedApp: Date] = [:]
    ) {
        self.companionName = Self.sanitizedName(companionName)
        self.protectedApps = protectedApps
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.lastCheckIn = lastCheckIn
    }

    /// Whether the automation for `app` has reached Pofu at least once.
    public func isVerified(_ app: ProtectedApp) -> Bool {
        lastCheckIn[app] != nil
    }

    /// Records that the automation for `app` ran at `date`. Adds the app
    /// to the protected list if the user set up an automation for an app
    /// they did not pick in onboarding.
    public mutating func recordCheckIn(from app: ProtectedApp, at date: Date) {
        lastCheckIn[app] = max(lastCheckIn[app] ?? date, date)
        if !protectedApps.contains(app) {
            protectedApps.append(app)
        }
    }

    /// Trims whitespace and newlines, caps the length, and falls back to
    /// the default name when nothing is left.
    public static func sanitizedName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let capped = String(trimmed.prefix(maximumNameLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return capped.isEmpty ? defaultName : capped
    }
}

extension UserProfile: Codable {
    private enum CodingKeys: String, CodingKey {
        case companionName, protectedApps, hasCompletedOnboarding, lastCheckIn
    }

    private struct CheckInEntry: Codable {
        var app: ProtectedApp
        var at: Date
    }

    /// Tolerant decoding: missing fields take their defaults, and unknown
    /// apps (from a newer version) are dropped instead of failing the load.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawApps = try container.decodeIfPresent([String].self, forKey: .protectedApps) ?? []
        let entries = (try? container.decodeIfPresent([CheckInEntry].self, forKey: .lastCheckIn)) ?? []
        var lastCheckIn: [ProtectedApp: Date] = [:]
        for entry in entries {
            lastCheckIn[entry.app] = entry.at
        }
        self.init(
            companionName: try container.decodeIfPresent(String.self, forKey: .companionName) ?? Self.defaultName,
            protectedApps: rawApps.compactMap(ProtectedApp.init(rawValue:)),
            hasCompletedOnboarding: try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false,
            lastCheckIn: lastCheckIn
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(companionName, forKey: .companionName)
        try container.encode(protectedApps.map(\.rawValue), forKey: .protectedApps)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        let entries = lastCheckIn
            .map { CheckInEntry(app: $0.key, at: $0.value) }
            .sorted { $0.app.rawValue < $1.app.rawValue }
        try container.encode(entries, forKey: .lastCheckIn)
    }
}
