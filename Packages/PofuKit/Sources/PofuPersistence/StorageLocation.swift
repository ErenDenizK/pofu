import Foundation

/// Where Pofu keeps its files (ADR-0003).
///
/// The App Group container is preferred, because extensions (the shield,
/// the device activity monitor) will need to read and append to the same
/// files. A free Personal Team cannot use App Groups, so until the paid
/// membership is active the app falls back to its own Application Support
/// directory. When the group becomes available later, `migrateIfNeeded`
/// moves the existing files over once.
public struct StorageLocation: Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case appGroup
        case applicationSupport
        case custom
    }

    /// The App Group shared by the app and its future extensions.
    public static let appGroupIdentifier = "group.com.erendenizk.pofu"
    /// The folder inside the container that holds Pofu's files.
    public static let folderName = "Pofu"

    public let directory: URL
    public let kind: Kind

    public init(directory: URL, kind: Kind = .custom) {
        self.directory = directory
        self.kind = kind
    }

    /// The App Group container if this build is entitled to it, else
    /// Application Support.
    public static func resolve(
        appGroupIdentifier: String = StorageLocation.appGroupIdentifier,
        fileManager: FileManager = .default
    ) -> StorageLocation {
        if let group = appGroupDirectory(identifier: appGroupIdentifier, fileManager: fileManager) {
            return StorageLocation(directory: group, kind: .appGroup)
        }
        return applicationSupport(fileManager: fileManager)
    }

    /// The app's own Application Support folder.
    public static func applicationSupport(fileManager: FileManager = .default) -> StorageLocation {
        let base =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return StorageLocation(directory: base.appendingPathComponent(folderName, isDirectory: true), kind: .applicationSupport)
    }

    static func appGroupDirectory(identifier: String, fileManager: FileManager) -> URL? {
        #if canImport(Darwin)
        // Returns nil when the app lacks the App Group entitlement, which
        // is the case for builds signed by a free Personal Team.
        return fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)?
            .appendingPathComponent(folderName, isDirectory: true)
        #else
        return nil
        #endif
    }

    /// Moves files from `legacy` into this location once: only when this
    /// location holds no snapshot yet and `legacy` does. Existing data in
    /// this location always wins, so running it again is harmless.
    ///
    /// - Returns: Whether anything was moved.
    @discardableResult
    public func migrateIfNeeded(from legacy: StorageLocation, fileManager: FileManager = .default) throws -> Bool {
        guard legacy.directory.standardizedFileURL != directory.standardizedFileURL else { return false }
        let snapshotName = PofuStore.snapshotFileName
        let legacySnapshot = legacy.directory.appendingPathComponent(snapshotName)
        let currentSnapshot = directory.appendingPathComponent(snapshotName)
        guard
            fileManager.fileExists(atPath: legacySnapshot.path),
            !fileManager.fileExists(atPath: currentSnapshot.path)
        else { return false }

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        for name in [snapshotName, EventLog.fileName, EventLog.archiveFileName] {
            let source = legacy.directory.appendingPathComponent(name)
            let destination = directory.appendingPathComponent(name)
            guard fileManager.fileExists(atPath: source.path), !fileManager.fileExists(atPath: destination.path) else {
                continue
            }
            try fileManager.copyItem(at: source, to: destination)
        }
        // Remove the legacy copies only after every copy succeeded.
        for name in [snapshotName, EventLog.fileName, EventLog.archiveFileName] {
            let source = legacy.directory.appendingPathComponent(name)
            if fileManager.fileExists(atPath: source.path) {
                try? fileManager.removeItem(at: source)
            }
        }
        return true
    }
}
