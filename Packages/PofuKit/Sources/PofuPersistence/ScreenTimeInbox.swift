import Foundation
import PofuCore

/// The App Group folder where Screen Time extensions leave records for the
/// app (ADR-0003).
///
/// Each record is its own small file, written atomically, so several
/// extension processes and the app never write the same file: there is
/// nothing to lock and nothing to tear. The app reads every file, ingests
/// the records, and then deletes what it took in.
public struct ScreenTimeInbox: Sendable {
    public static let folderName = "ScreenTimeInbox"

    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// The inbox inside `location`.
    public init(location: StorageLocation) {
        self.init(directory: location.directory.appendingPathComponent(Self.folderName, isDirectory: true))
    }

    /// Writes `record` as a new file. Names sort by time, then id.
    public func post(_ record: ScreenTimeRecord) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let milliseconds = Int64((record.at.timeIntervalSince1970 * 1000).rounded(.down))
        let stamp = String(max(0, milliseconds))
        let padded = String(repeating: "0", count: max(0, 15 - stamp.count)) + stamp
        let url = directory.appendingPathComponent("\(padded)-\(record.id.uuidString).json")
        let data = try PofuCoding.makeEncoder(pretty: false).encode(record)
        try data.write(to: url, options: [.atomic])
    }

    /// What the inbox holds.
    public struct Contents: Sendable {
        /// Readable records, oldest first.
        public let records: [ScreenTimeRecord]
        /// Files that were read (or are unreadable for good) and can be
        /// deleted once their records are ingested.
        public let consumable: [URL]
        /// Records from a newer version of Pofu, left in place.
        public let newerVersionCount: Int
    }

    /// Reads every file in the inbox. Never throws: a missing folder is an
    /// empty inbox, and a file that cannot be decoded is reported as
    /// consumable (so it does not linger) unless a newer version wrote it.
    public func read() -> Contents {
        let fileManager = FileManager.default
        guard
            let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        else {
            return Contents(records: [], consumable: [], newerVersionCount: 0)
        }
        let decoder = PofuCoding.makeDecoder()
        var records: [ScreenTimeRecord] = []
        var consumable: [URL] = []
        var newer = 0
        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url) else { continue }
            do {
                records.append(try decoder.decode(ScreenTimeRecord.self, from: data))
                consumable.append(url)
            } catch ScreenTimeRecordError.unsupportedVersion {
                newer += 1
            } catch {
                consumable.append(url)
            }
        }
        records.sort { ($0.at, $0.id.uuidString) < ($1.at, $1.id.uuidString) }
        return Contents(records: records, consumable: consumable, newerVersionCount: newer)
    }

    /// Deletes files the app has taken in.
    public func remove(_ urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

/// A single Codable value in a JSON file, written atomically. For small
/// shared state with one writer, such as the shield state the app writes
/// for the extensions.
public struct JSONFile<Value: Codable>: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// The value, or `nil` when the file is missing or unreadable.
    public func read() -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? PofuCoding.makeDecoder().decode(Value.self, from: data)
    }

    public func write(_ value: Value) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try PofuCoding.makeEncoder(pretty: false).encode(value)
        try data.write(to: url, options: [.atomic])
    }

    public func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

/// What the shield configuration extension learned about each token (its
/// bundle identifier and name), one file per token, for the shield action
/// extension to attach to its records.
public struct ShieldDirectory: Sendable {
    public static let folderName = "ShieldDirectory"

    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public init(location: StorageLocation) {
        self.init(directory: location.directory.appendingPathComponent(Self.folderName, isDirectory: true))
    }

    private func file(for token: String) -> JSONFile<ShieldDirectoryEntry> {
        JSONFile(url: directory.appendingPathComponent("\(ShieldedApp.key(forToken: token)).json"))
    }

    /// The entry for `token`, if one was recorded and it is for this token.
    public func entry(for token: String) -> ShieldDirectoryEntry? {
        guard let entry = file(for: token).read(), entry.token == token else { return nil }
        return entry
    }

    /// Records `entry`, unless the same entry is already there.
    public func record(_ entry: ShieldDirectoryEntry) throws {
        guard self.entry(for: entry.token) != entry else { return }
        try file(for: entry.token).write(entry)
    }

    /// `app` with the bundle identifier and name filled in from the
    /// directory, where they are missing.
    public func resolve(_ app: ShieldedApp) -> ShieldedApp {
        guard let entry = entry(for: app.token) else { return app }
        var resolved = app
        resolved.bundleIdentifier = app.bundleIdentifier ?? entry.bundleIdentifier
        resolved.displayName = app.displayName ?? entry.displayName
        return resolved
    }
}
