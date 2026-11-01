import AppIntents
import PofuCore

/// The app an automation guards, as Shortcuts shows it. Each automation
/// passes its own app, so Pofu never depends on Shortcuts input to know
/// which app was opened (one automation per app).
enum TargetApp: String, AppEnum {
    case instagram
    case youtube
    case tiktok
    case x
    case snapchat
    case reddit
    case facebook
    case other

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "App")

    static let caseDisplayRepresentations: [TargetApp: DisplayRepresentation] = [
        .instagram: DisplayRepresentation(title: "Instagram"),
        .youtube: DisplayRepresentation(title: "YouTube"),
        .tiktok: DisplayRepresentation(title: "TikTok"),
        .x: DisplayRepresentation(title: "X"),
        .snapchat: DisplayRepresentation(title: "Snapchat"),
        .reddit: DisplayRepresentation(title: "Reddit"),
        .facebook: DisplayRepresentation(title: "Facebook"),
        .other: DisplayRepresentation(title: "Another app"),
    ]

    var protectedApp: ProtectedApp {
        switch self {
        case .instagram: .instagram
        case .youtube: .youtube
        case .tiktok: .tiktok
        case .x: .x
        case .snapchat: .snapchat
        case .reddit: .reddit
        case .facebook: .facebook
        case .other: .other
        }
    }
}
