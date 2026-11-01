import Foundation
import PofuCore

/// Whether the user has granted Screen Time access (FamilyControls,
/// individual authorization).
public enum ScreenTimeAuthorizationStatus: String, Hashable, Sendable, Codable {
    case notDetermined
    case denied
    case approved
}

/// An opaque, system-issued reference to one app. The live implementation
/// wraps FamilyControls' `ApplicationToken`; Pofu never learns which app it
/// is, only that the user picked it.
public struct ApplicationToken: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { "app:\(rawValue)" }
}

/// An opaque reference to an App Store category, such as Social.
public struct CategoryToken: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { "category:\(rawValue)" }
}

/// An opaque reference to a web domain.
public struct WebDomainToken: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { "web:\(rawValue)" }
}

/// The apps, categories, and web domains the user marked as distracting,
/// as returned by the system activity picker.
public struct DistractionSelection: Hashable, Sendable, Codable {
    public var applications: Set<ApplicationToken>
    public var categories: Set<CategoryToken>
    public var webDomains: Set<WebDomainToken>

    public init(
        applications: Set<ApplicationToken> = [],
        categories: Set<CategoryToken> = [],
        webDomains: Set<WebDomainToken> = []
    ) {
        self.applications = applications
        self.categories = categories
        self.webDomains = webDomains
    }

    public static let empty = DistractionSelection()

    public var isEmpty: Bool {
        applications.isEmpty && categories.isEmpty && webDomains.isEmpty
    }

    /// Whether the selection covers `application`, either directly or
    /// through its category.
    public func covers(_ application: ApplicationToken, category: CategoryToken?) -> Bool {
        if applications.contains(application) {
            return true
        }
        if let category {
            return categories.contains(category)
        }
        return false
    }
}

/// Names a set of shields, like a named `ManagedSettingsStore`, so that
/// independent features (a bedtime schedule, an exhausted budget) can apply
/// and remove their own shields without touching each other's.
public struct ShieldID: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral,
    CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String { rawValue }
}

/// Names a usage threshold, like a `DeviceActivityEvent.Name`.
public struct ThresholdID: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral,
    CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String { rawValue }
}

/// "Tell me when the user has spent `threshold` in `selection` today,
/// counting only usage inside `window`", like a `DeviceActivitySchedule`
/// with one event.
public struct ThresholdSchedule: Hashable, Sendable, Codable, Identifiable {
    public var id: ThresholdID
    public var selection: DistractionSelection
    /// Usage that triggers the event, in seconds.
    public var threshold: TimeInterval
    /// The local-time window in which usage counts; `nil` for all day.
    public var window: DailyWindow?

    public init(
        id: ThresholdID,
        selection: DistractionSelection,
        threshold: TimeInterval,
        window: DailyWindow? = nil
    ) {
        self.id = id
        self.selection = selection
        self.threshold = threshold
        self.window = window
    }
}

/// Something that happened on the Screen Time side. In the live app these
/// arrive from extensions through the App Group event log (ADR-0003).
public enum ScreenTimeEvent: Hashable, Sendable, Codable {
    case authorizationChanged(ScreenTimeAuthorizationStatus)
    case thresholdReached(ThresholdID)
    case shieldShown(ShieldID, application: ApplicationToken)
}

/// Why a Screen Time operation failed.
public enum ScreenTimeError: Error, Hashable, Sendable {
    /// The operation needs approved authorization.
    case notAuthorized
    /// A shield or schedule needs a non-empty selection.
    case emptySelection
    /// A threshold must be positive.
    case invalidThreshold
    /// The system could not complete the request.
    case unavailable
    /// A shield can only be lifted for a pass that has not ended.
    case invalidLift
}
