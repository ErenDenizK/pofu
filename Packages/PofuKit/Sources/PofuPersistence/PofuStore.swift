import Foundation
import PofuCore

/// What loading the snapshot found.
public enum SnapshotLoad: Sendable {
    /// No snapshot exists yet: a first launch.
    case empty
    case loaded(PofuSnapshot)
    /// The snapshot could not be read. It was moved aside to `quarantinedAt`
    /// so it is never overwritten, and the app starts fresh.
    case recovered(from: any Error, quarantinedAt: URL?)
}

/// File-based storage for Pofu (ADR-0003): one JSON snapshot written
/// atomically, plus an append-only event log beside it.
///
/// The store holds no state of its own, so it is cheap to create and safe
/// to share. Callers serialize writes (the app does all of them on the main
/// actor); each write is atomic, so readers never see a half-written file.
public struct PofuStore: Sendable {
    public static let snapshotFileName = "state.json"

    public let location: StorageLocation
    public let events: EventLog

    public init(location: StorageLocation) {
        self.location = location
        self.events = EventLog(directory: location.directory)
    }

    public var snapshotURL: URL {
        location.directory.appendingPathComponent(Self.snapshotFileName)
    }

    /// Reads the snapshot. Never throws: a missing file is a first launch,
    /// and an unreadable one is quarantined rather than lost.
    public func load() -> SnapshotLoad {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: snapshotURL.path) else {
            return .empty
        }
        do {
            let data = try Data(contentsOf: snapshotURL)
            let snapshot = try PofuCoding.makeDecoder().decode(PofuSnapshot.self, from: data)
            return .loaded(snapshot)
        } catch {
            return .recovered(from: error, quarantinedAt: quarantine())
        }
    }

    /// Writes `snapshot` atomically: the new file replaces the old one in a
    /// single rename, so a crash leaves either the old or the new state.
    public func save(_ snapshot: PofuSnapshot) throws {
        try FileManager.default.createDirectory(at: location.directory, withIntermediateDirectories: true)
        let data = try PofuCoding.makeEncoder(pretty: true).encode(snapshot)
        #if os(iOS)
        // Readable after the first unlock since boot, so an automation
        // running while the phone is locked again can still read passes.
        try data.write(to: snapshotURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: snapshotURL, options: [.atomic])
        #endif
    }

    /// Appends one event to the log.
    public func log(_ event: PofuEvent, at date: Date) throws {
        try events.append(LoggedEvent(at: date, event: event))
    }

    /// Moves an unreadable snapshot aside and returns where it went.
    private func quarantine() -> URL? {
        let stamp = Int(Date().timeIntervalSince1970)
        let destination = location.directory.appendingPathComponent("state.unreadable-\(stamp)-\(UUID().uuidString.prefix(8)).json")
        do {
            try FileManager.default.moveItem(at: snapshotURL, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}
