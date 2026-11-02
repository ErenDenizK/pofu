import Foundation
import PofuCore

/// Everything the app persists in one value: the domain state, the game
/// state, and the user's profile. Written atomically as a whole, so they
/// can never disagree after a crash.
public struct PofuSnapshot: Hashable, Sendable {
    /// The format version this build writes. Version 2 added `game`.
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var state: PofuState
    public var profile: UserProfile
    /// The honor session running when the app was last saved, if any.
    public var activeSession: ActiveSession?
    /// The game model (game design v2); `nil` in snapshots from before it,
    /// and when the saved game could not be read (a newer build wrote it).
    /// The app then starts a fresh game rather than refuse to run the gate.
    public var game: GameState?

    public init(
        state: PofuState = PofuState(),
        profile: UserProfile = UserProfile(),
        activeSession: ActiveSession? = nil,
        game: GameState? = nil,
        schemaVersion: Int = PofuSnapshot.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.state = state
        self.profile = profile
        self.activeSession = activeSession
        self.game = game
    }
}

extension PofuSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, state, profile, activeSession, game
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            state: try container.decodeIfPresent(PofuState.self, forKey: .state) ?? PofuState(),
            profile: try container.decodeIfPresent(UserProfile.self, forKey: .profile) ?? UserProfile(),
            activeSession: try container.decodeIfPresent(ActiveSession.self, forKey: .activeSession),
            // The game never costs the gate its state: an unreadable game
            // is dropped, the passes and the profile are kept.
            game: try? container.decodeIfPresent(GameState.self, forKey: .game),
            schemaVersion: try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(state, forKey: .state)
        try container.encode(profile, forKey: .profile)
        try container.encodeIfPresent(activeSession, forKey: .activeSession)
        try container.encodeIfPresent(game, forKey: .game)
    }
}
