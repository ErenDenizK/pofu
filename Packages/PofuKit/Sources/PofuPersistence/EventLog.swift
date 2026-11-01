import Foundation
import PofuCore

/// An append-only log of `LoggedEvent`s in JSON Lines: one JSON object per
/// line (ADR-0003).
///
/// Appends never rewrite earlier lines, so a crash can at worst leave one
/// torn line at the end, which reading skips. When the file grows past
/// `maximumBytes`, it is rotated to a single archive (the previous archive
/// is dropped), which bounds the log's disk use to about twice that size.
public struct EventLog: Sendable {
    public static let fileName = "events.jsonl"
    public static let archiveFileName = "events.1.jsonl"

    public let fileURL: URL
    public let archiveURL: URL
    public let maximumBytes: Int

    public init(directory: URL, maximumBytes: Int = 1_000_000) {
        self.fileURL = directory.appendingPathComponent(Self.fileName)
        self.archiveURL = directory.appendingPathComponent(Self.archiveFileName)
        self.maximumBytes = maximumBytes
    }

    /// Appends `event` as one line.
    public func append(_ event: LoggedEvent) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try rotateIfNeeded(fileManager: fileManager)

        var line = try PofuCoding.makeEncoder(pretty: false).encode(event)
        line.append(0x0A)
        if !fileManager.fileExists(atPath: fileURL.path) {
            try line.write(to: fileURL, options: .atomic)
            return
        }
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }

    /// Every readable event, oldest first, from the archive and the
    /// current file. Lines that do not decode (a torn final line, or an
    /// event from a newer version) are skipped.
    public func readAll() throws -> [LoggedEvent] {
        let decoder = PofuCoding.makeDecoder()
        var events: [LoggedEvent] = []
        for url in [archiveURL, fileURL] where FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            for line in data.split(separator: 0x0A, omittingEmptySubsequences: true) {
                if let event = try? decoder.decode(LoggedEvent.self, from: Data(line)) {
                    events.append(event)
                }
            }
        }
        return events
    }

    private func rotateIfNeeded(fileManager: FileManager) throws {
        // A fresh URL, because URL instances cache resource values.
        let current = URL(fileURLWithPath: fileURL.path)
        guard
            let size = try? current.resourceValues(forKeys: [.fileSizeKey]).fileSize,
            size >= maximumBytes
        else { return }
        if fileManager.fileExists(atPath: archiveURL.path) {
            try fileManager.removeItem(at: archiveURL)
        }
        try fileManager.moveItem(at: fileURL, to: archiveURL)
    }
}

/// The JSON settings every Pofu file uses.
///
/// Dates are encoded as seconds since the reference date (the default
/// strategy), which round-trips `Date` exactly; ISO 8601 would drop
/// sub-second precision and make passes end a fraction early.
public enum PofuCoding {
    public static func makeEncoder(pretty: Bool) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = pretty ? [.sortedKeys, .prettyPrinted] : [.sortedKeys]
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        JSONDecoder()
    }
}
