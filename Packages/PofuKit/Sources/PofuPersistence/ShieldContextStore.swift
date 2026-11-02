import Foundation
import PofuCore

/// The small App Group files the shield extensions read to draw a shield
/// that speaks (gate v2, E2). Each file has one writer:
///
/// - `appState`: the app, on every save.
/// - `memory`: the shield configuration extension.
/// - `openRequest`: the shield action extension; the app removes it when
///   Hop! answers it.
/// - `usage`: the monitor extension, when a usage threshold fires.
public struct ShieldContextStore: Sendable {
    public static let usageFileName = "shield-guarded-usage.json"

    public let directory: URL

    public init(location: StorageLocation) {
        self.directory = location.directory
    }

    public var appState: JSONFile<ShieldAppState> {
        JSONFile(url: directory.appendingPathComponent(ShieldAppState.fileName))
    }

    public var memory: JSONFile<ShieldMemory> {
        JSONFile(url: directory.appendingPathComponent(ShieldMemory.fileName))
    }

    public var openRequest: JSONFile<ShieldOpenRequestNote> {
        JSONFile(url: directory.appendingPathComponent(ShieldOpenRequestNote.fileName))
    }

    public var usage: JSONFile<GuardedUsageDay> {
        JSONFile(url: directory.appendingPathComponent(Self.usageFileName))
    }

    /// Records `minutes` of measured guarded time on `day`, keeping the
    /// day's highest step. For the monitor extension.
    public func noteMeasured(_ minutes: Int, on day: LocalDay) throws {
        if let current = usage.read() {
            if current.day > day { return }
            if current.day == day, current.measuredMinutes >= minutes { return }
        }
        try usage.write(GuardedUsageDay(day: day, measuredMinutes: minutes))
    }
}
