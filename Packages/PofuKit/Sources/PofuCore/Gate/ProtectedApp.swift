import Foundation

/// An app the soft gate can stand in front of.
///
/// Each Shortcuts automation passes its own app to `CheckInIntent`, so the
/// identity of the reach never depends on Shortcuts input (one automation
/// per app). The raw value is persisted and is also the app's
/// `TargetGroupID`: passes are per app, the friction ladder is shared.
public enum ProtectedApp: String, CaseIterable, Hashable, Sendable, Codable, Identifiable {
    case instagram
    case youtube
    case tiktok
    case x
    case snapchat
    case reddit
    case facebook
    /// Any other app. Pofu cannot open it on its own, so the user returns
    /// to it themselves after Hop!.
    case other

    public var id: String { rawValue }

    /// The pass and ladder identity of this app.
    public var target: TargetGroupID {
        TargetGroupID(rawValue: rawValue)
    }

    /// The app's brand name, which is the same in every language. `nil` for
    /// `.other`, whose label is localized by the app.
    public var brandName: String? {
        switch self {
        case .instagram: "Instagram"
        case .youtube: "YouTube"
        case .tiktok: "TikTok"
        case .x: "X"
        case .snapchat: "Snapchat"
        case .reddit: "Reddit"
        case .facebook: "Facebook"
        case .other: nil
        }
    }

    /// Custom URL schemes that launch the app, most reliable first.
    ///
    /// Sources: Instagram (`instagram://`, Meta's sharing docs), Snapchat
    /// (`snapchat://`, Snap Kit), Facebook (`fb://`, Facebook SDK), TikTok
    /// (`snssdk1233://` and `snssdk1180://`, which TikTok's Open SDK lists as
    /// its install-check schemes), YouTube (`youtube://`), X (`twitter://`,
    /// the scheme the app has registered since it was Twitter), Reddit
    /// (`reddit://`). Each one still needs confirming on a device; the
    /// universal link below is the fallback when none answers.
    public var urlSchemes: [String] {
        switch self {
        case .instagram: ["instagram"]
        case .youtube: ["youtube"]
        case .tiktok: ["snssdk1233", "snssdk1180", "tiktok"]
        case .x: ["twitter", "x"]
        case .snapchat: ["snapchat"]
        case .reddit: ["reddit"]
        case .facebook: ["fb"]
        case .other: []
        }
    }

    /// URLs that open the app's home through its custom schemes, in the
    /// order to try them.
    public var launchURLs: [URL] {
        urlSchemes.compactMap { URL(string: "\($0)://") }
    }

    /// A universal link the app claims. Opened with "universal links only",
    /// it launches the app if installed and does nothing otherwise, without
    /// any `LSApplicationQueriesSchemes` entry.
    public var universalLink: URL? {
        switch self {
        case .instagram: URL(string: "https://www.instagram.com/")
        case .youtube: URL(string: "https://www.youtube.com/")
        case .tiktok: URL(string: "https://www.tiktok.com/")
        case .x: URL(string: "https://x.com/home")
        case .snapchat: URL(string: "https://www.snapchat.com/")
        case .reddit: URL(string: "https://www.reddit.com/")
        case .facebook: URL(string: "https://www.facebook.com/")
        case .other: nil
        }
    }

    /// Whether Pofu can hand the user back to this app by itself.
    public var canBeOpenedByPofu: Bool {
        !launchURLs.isEmpty || universalLink != nil
    }

    /// Every custom scheme Pofu may query with `canOpenURL`. The app's
    /// `LSApplicationQueriesSchemes` must list exactly these.
    public static var allQueriedSchemes: [String] {
        allCases.flatMap(\.urlSchemes)
    }
}
