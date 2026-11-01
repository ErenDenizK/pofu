import Foundation

/// Something the Screen Time shield stands in front of, as the shield
/// extensions report it to the app.
///
/// The system identifies picked apps only by opaque tokens (platform
/// constraints, section 3). `token` is that token, encoded by the live
/// Screen Time layer into a string; Pofu never interprets it, it only hands
/// it back to lift or restore the shield. The bundle identifier and name
/// are known only when the shield configuration extension could record
/// them, and are used to hand the user back to a known app after Hop!.
public struct ShieldedApp: Hashable, Sendable, Codable {
    /// What kind of token `token` is.
    public enum Kind: String, Hashable, Sendable, Codable {
        /// An app the user picked.
        case application
        /// An app shielded through a picked category. ShieldAction only
        /// sees the category, so the whole category is the unit.
        case category
        /// A web domain.
        case webDomain
    }

    public var kind: Kind
    /// The encoded system token. Opaque.
    public var token: String
    public var bundleIdentifier: String?
    public var displayName: String?

    public init(kind: Kind = .application, token: String, bundleIdentifier: String? = nil, displayName: String? = nil) {
        self.kind = kind
        self.token = token
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }

    /// The known app this is, from its bundle identifier, or `.other` when
    /// Pofu cannot tell (Hop! then asks the user to return to it
    /// themselves).
    public var protectedApp: ProtectedApp {
        bundleIdentifier.flatMap(ProtectedApp.init(bundleIdentifier:)) ?? .other
    }

    /// The pass and ladder identity of the reach: the known app's, so the
    /// shield and the soft gate share passes, or one of its own for an app
    /// Pofu cannot name, so a pass for one unknown app never covers
    /// another.
    public var target: TargetGroupID {
        let app = protectedApp
        return app == .other ? TargetGroupID(rawValue: "shield.\(tokenKey)") : app.target
    }

    /// A short, stable key for the token, safe as a file name. Stable across
    /// processes and launches, unlike `hashValue`.
    public var tokenKey: String {
        Self.key(forToken: token)
    }

    /// The key `tokenKey` produces for `token`: FNV-1a over its UTF-8 bytes,
    /// in hex.
    public static func key(forToken token: String) -> String {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in token.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        let hex = String(hash, radix: 16)
        return String(repeating: "0", count: max(0, 16 - hex.count)) + hex
    }
}

/// What the shield configuration extension learned about a token: the
/// system tells it the app's bundle identifier and name, which the shield
/// action extension does not get.
public struct ShieldDirectoryEntry: Hashable, Sendable, Codable {
    public static let currentVersion = 1

    public var version: Int
    public var token: String
    public var bundleIdentifier: String?
    public var displayName: String?

    public init(token: String, bundleIdentifier: String?, displayName: String?, version: Int = ShieldDirectoryEntry.currentVersion) {
        self.version = version
        self.token = token
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}

extension ProtectedApp {
    /// The App Store bundle identifiers of each known app.
    public var bundleIdentifiers: [String] {
        switch self {
        case .instagram: ["com.burbn.instagram"]
        case .youtube: ["com.google.ios.youtube"]
        case .tiktok: ["com.zhiliaoapp.musically"]
        case .x: ["com.atebits.Tweetie2"]
        case .snapchat: ["com.toyopagroup.picaboo"]
        case .reddit: ["com.reddit.Reddit"]
        case .facebook: ["com.facebook.Facebook"]
        case .other: []
        }
    }

    /// The known app with `bundleIdentifier`, compared case-insensitively;
    /// `nil` for any other app.
    public init?(bundleIdentifier: String) {
        let wanted = bundleIdentifier.lowercased()
        guard
            let match = Self.allCases.first(where: { app in
                app.bundleIdentifiers.contains { $0.lowercased() == wanted }
            })
        else { return nil }
        self = match
    }
}
