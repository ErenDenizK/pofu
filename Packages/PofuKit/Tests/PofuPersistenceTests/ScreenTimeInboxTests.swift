import Foundation
import PofuCore
import Testing
@testable import PofuPersistence

private let instagram = ShieldedApp(token: "token-instagram")

@Suite("Screen Time inbox")
struct ScreenTimeInboxTests {
    @Test func aMissingFolderIsAnEmptyInbox() throws {
        let directory = try TemporaryDirectory()
        let inbox = ScreenTimeInbox(directory: directory.subdirectory("missing"))
        let contents = inbox.read()
        #expect(contents.records.isEmpty)
        #expect(contents.consumable.isEmpty)
    }

    @Test func recordsComeBackOldestFirst() throws {
        let directory = try TemporaryDirectory()
        let inbox = ScreenTimeInbox(location: StorageLocation(directory: directory.url))
        let base = Date(timeIntervalSinceReferenceDate: 815_000_000)
        let late = ScreenTimeRecord(at: base.addingTimeInterval(60), kind: .usageThresholdReached(minutes: 30))
        let early = ScreenTimeRecord(at: base, kind: .shieldResisted(app: instagram))
        try inbox.post(late)
        try inbox.post(early)

        let contents = inbox.read()
        #expect(contents.records == [early, late])
        #expect(contents.consumable.count == 2)
        #expect(contents.newerVersionCount == 0)
    }

    @Test func removingConsumedFilesEmptiesTheInbox() throws {
        let directory = try TemporaryDirectory()
        let inbox = ScreenTimeInbox(directory: directory.url)
        try inbox.post(ScreenTimeRecord(at: Date(timeIntervalSinceReferenceDate: 0), kind: .shieldRestored(passID: UUID())))
        inbox.remove(inbox.read().consumable)
        #expect(inbox.read().records.isEmpty)
    }

    @Test func recordsFromANewerVersionStayForAnUpdatedApp() throws {
        let directory = try TemporaryDirectory()
        let inbox = ScreenTimeInbox(directory: directory.url)
        let newer = """
            {"version":99,"id":"4B4C3B0E-7D3B-4C47-9B44-1B0C3E1F2A10","at":0,"kind":{"future":{}}}
            """
        try Data(newer.utf8).write(to: directory.url.appendingPathComponent("000000000000000-newer.json"))
        try Data("not json".utf8).write(to: directory.url.appendingPathComponent("000000000000001-torn.json"))

        let contents = inbox.read()
        #expect(contents.records.isEmpty)
        #expect(contents.newerVersionCount == 1)
        #expect(contents.consumable.map(\.lastPathComponent) == ["000000000000001-torn.json"])
        inbox.remove(contents.consumable)
        #expect(inbox.read().newerVersionCount == 1)
    }
}

@Suite("JSON file")
struct JSONFileTests {
    @Test func aValueRoundTrips() throws {
        let directory = try TemporaryDirectory()
        let file = JSONFile<ScreenTimeLedger>(url: directory.subdirectory("nested").appendingPathComponent("ledger.json"))
        #expect(file.read() == nil)
        let ledger = ScreenTimeLedger(usage: GuardedUsageDay(day: LocalDay(year: 2026, month: 11, day: 14), measuredMinutes: 45))
        try file.write(ledger)
        #expect(file.read() == ledger)
        file.remove()
        #expect(file.read() == nil)
    }
}

@Suite("Shield directory")
struct ShieldDirectoryTests {
    @Test func entriesFillInWhatTheShieldActionCannotSee() throws {
        let directory = try TemporaryDirectory()
        let shieldDirectory = ShieldDirectory(location: StorageLocation(directory: directory.url))
        try shieldDirectory.record(
            ShieldDirectoryEntry(token: instagram.token, bundleIdentifier: "com.burbn.instagram", displayName: "Instagram")
        )
        let resolved = shieldDirectory.resolve(instagram)
        #expect(resolved.bundleIdentifier == "com.burbn.instagram")
        #expect(resolved.displayName == "Instagram")
        #expect(resolved.protectedApp == .instagram)
    }

    @Test func unknownTokensStayAsTheyAre() throws {
        let directory = try TemporaryDirectory()
        let shieldDirectory = ShieldDirectory(directory: directory.url)
        let unknown = ShieldedApp(token: "never-seen")
        #expect(shieldDirectory.resolve(unknown) == unknown)
    }

    @Test func anEntryForAnotherTokenIsIgnored() throws {
        let directory = try TemporaryDirectory()
        let shieldDirectory = ShieldDirectory(directory: directory.url)
        // Simulates a key collision: the file for this token's key holds
        // another token's entry.
        let file = directory.url.appendingPathComponent("\(instagram.tokenKey).json")
        let foreign = ShieldDirectoryEntry(token: "someone-else", bundleIdentifier: "com.google.ios.youtube", displayName: "YouTube")
        try JSONEncoder().encode(foreign).write(to: file)
        #expect(shieldDirectory.entry(for: instagram.token) == nil)
        #expect(shieldDirectory.resolve(instagram) == instagram)
    }
}
