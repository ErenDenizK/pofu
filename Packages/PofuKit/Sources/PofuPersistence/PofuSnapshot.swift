import Foundation
import PofuCore

/// Everything the app persists in one value: the domain state and the
/// user's profile. Written atomically as a whole, so the two can never
/// disagree after a crash.
public struct PofuSnapshot: Hashable, Sendable {
    /// The format version this build writes.
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var state: PofuState
    public var profile: UserProfile
    /// The honor session running when the app was last saved, if any.
    public var activeSession: ActiveSession?

    public init(
        state: PofuState = PofuState(),
        profile: UserProfile = UserProfile(),
        activeSession: ActiveSession? = nil,
        schemaVersion: Int = PofuSnapshot.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.state = state
        self.profile = profile
        self.activeSession = activeSession
    }
}

extension PofuSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, state, profile, activeSession
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            state: try container.decodeIfPresent(PofuState.self, forKey: .state) ?? PofuState(),
            profile: try container.decodeIfPresent(UserProfile.self, forKey: .profile) ?? UserProfile(),
            activeSession: try container.decodeIfPresent(ActiveSession.self, forKey: .activeSession),
            schemaVersion: try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(state, forKey: .state)
        try container.encode(profile, forKey: .profile)
        try container.encodeIfPresent(activeSession, forKey: .activeSession)
    }
}
