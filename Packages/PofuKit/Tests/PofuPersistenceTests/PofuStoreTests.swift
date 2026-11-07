import Foundation
import PofuCore
import Testing
@testable import PofuPersistence

/// A fresh, empty directory under the system temporary directory, removed
/// when the test ends.
final class TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PofuPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func subdirectory(_ name: String) -> URL {
        url.appendingPathComponent(name, isDirectory: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}

/// A snapshot with something in every part of the state.
func sampleSnapshot() throws -> PofuSnapshot {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
    let economy = Economy(calendar: calendar)
    let gatekeeper = Gatekeeper(economy: economy)
    // 2026-11-02 12:00 in Istanbul (UTC+3).
    let noon = Date(timeIntervalSince1970: 1_793_610_000)
    var state = PofuState()
    if case .intervene(let attempt) = gatekeeper.beginCheckIn(for: "instagram", at: noon, state: &state) {
        try gatekeeper.resolve(attempt, with: .proceed, at: noon.addingTimeInterval(4.25), state: &state, reason: .lookUp)
    }
    _ = gatekeeper.beginCheckIn(for: "instagram", at: noon.addingTimeInterval(61.5), state: &state)
    // Back in Pofu after the pass: quiet time starts counting again.
    gatekeeper.noteUserReturned(at: noon.addingTimeInterval(1_200), state: &state)
    let walk = ActivitySession(kind: .walk, verification: .honor, startedAt: noon.addingTimeInterval(3_600), endedAt: noon.addingTimeInterval(5_400))
    economy.earn(walk, into: &state.wallet)
    // Three quiet hours later, seeds are waiting in Pofu's cheeks.
    gatekeeper.advanceQuietTime(to: noon.addingTimeInterval(3 * 3_600), state: &state)
    state.vitality.settle(through: economy.day(of: noon), model: VitalityModel()) { _ in VitalityInput() }
    let profile = UserProfile(
        companionName: "Fıstık",
        protectedApps: [.instagram, .youtube, .tiktok],
        hasCompletedOnboarding: true,
        lastCheckIn: [.instagram: noon]
    )
    let session = ActiveSession(kind: .focus, startedAt: noon.addingTimeInterval(7_200), plannedMinutes: 25)
    return PofuSnapshot(state: state, profile: profile, activeSession: session)
}

@Suite("Snapshot store")
struct PofuStoreTests {
    @Test func aFirstLaunchFindsNothing() throws {
        let directory = try TemporaryDirectory()
        let store = PofuStore(location: StorageLocation(directory: directory.subdirectory("missing")))
        guard case .empty = store.load() else {
            Issue.record("Expected an empty store")
            return
        }
    }

    @Test func stateSurvivesARelaunch() throws {
        let directory = try TemporaryDirectory()
        let snapshot = try sampleSnapshot()
        try PofuStore(location: StorageLocation(directory: directory.url)).save(snapshot)

        // A new store instance stands in for a new process.
        let relaunched = PofuStore(location: StorageLocation(directory: directory.url))
        guard case .loaded(let loaded) = relaunched.load() else {
            Issue.record("Expected the saved snapshot")
            return
        }
        #expect(loaded == snapshot)
        #expect(loaded.state.wallet.balance == snapshot.state.wallet.balance)
        #expect(loaded.state.passes.passes.count == 1)
        #expect(loaded.state.checkIns.first?.reason == .lookUp)
        #expect(loaded.state.passThroughs.count == 1)
        #expect(loaded.profile.companionName == "Fıstık")
        #expect(loaded.activeSession?.plannedMinutes == 25)
        #expect(loaded.state.quietTime == snapshot.state.quietTime)
        #expect(loaded.state.quietTime.lastSignalAt != nil)
        #expect(loaded.state.quietTime.pendingQuietSeeds > .zero)
    }

    @Test func savingReplacesTheWholeFileAndLeavesNoTemporaryFiles() throws {
        let directory = try TemporaryDirectory()
        let store = PofuStore(location: StorageLocation(directory: directory.url))
        var snapshot = try sampleSnapshot()
        try store.save(snapshot)
        snapshot.profile.companionName = "Lokum"
        snapshot.profile.protectedApps = [.reddit]
        try store.save(snapshot)

        guard case .loaded(let loaded) = store.load() else {
            Issue.record("Expected the saved snapshot")
            return
        }
        #expect(loaded.profile.companionName == "Lokum")
        #expect(loaded.profile.protectedApps == [.reddit])
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.url.path)
        #expect(files == [PofuStore.snapshotFileName])
    }

    @Test func anUnreadableSnapshotIsQuarantinedNotOverwritten() throws {
        let directory = try TemporaryDirectory()
        let store = PofuStore(location: StorageLocation(directory: directory.url))
        let garbage = Data("{ not json".utf8)
        try garbage.write(to: store.snapshotURL)

        guard case .recovered(_, let quarantined) = store.load() else {
            Issue.record("Expected a recovery")
            return
        }
        let moved = try #require(quarantined)
        #expect(try Data(contentsOf: moved) == garbage)
        #expect(!FileManager.default.fileExists(atPath: store.snapshotURL.path))
        guard case .empty = store.load() else {
            Issue.record("Expected a fresh start after quarantine")
            return
        }
    }

    @Test func snapshotsWrittenBeforeQuietTimeLoadWithAFreshLedger() throws {
        let directory = try TemporaryDirectory()
        let store = PofuStore(location: StorageLocation(directory: directory.url))
        let legacy = #"""
            {
              "schemaVersion" : 1,
              "profile" : { "companionName" : "Pamuk", "hasCompletedOnboarding" : true },
              "state" : {
                "wallet" : {
                  "balance" : 42,
                  "honorEarnedByDay" : [],
                  "stepEnergyByDay" : [],
                  "activityEnergyByDay" : [],
                  "unlockPurchases" : []
                },
                "checkIns" : [],
                "passThroughs" : []
              }
            }
            """#
        try Data(legacy.utf8).write(to: store.snapshotURL)
        guard case .loaded(let loaded) = store.load() else {
            Issue.record("Expected a snapshot")
            return
        }
        #expect(loaded.state.wallet.balance == 42)
        #expect(loaded.state.quietTime == QuietTimeLedger())
        #expect(loaded.profile.hasCompletedOnboarding)
    }

    @Test func olderSnapshotsWithMissingFieldsStillLoad() throws {
        let directory = try TemporaryDirectory()
        let store = PofuStore(location: StorageLocation(directory: directory.url))
        try Data(#"{"schemaVersion":1,"profile":{"companionName":"Pamuk"}}"#.utf8).write(to: store.snapshotURL)
        guard case .loaded(let loaded) = store.load() else {
            Issue.record("Expected a snapshot")
            return
        }
        #expect(loaded.profile.companionName == "Pamuk")
        #expect(loaded.state == PofuState())
    }
}

@Suite("Event log")
struct EventLogTests {
    let start = Date(timeIntervalSince1970: 1_793_610_000)

    func event(_ index: Int) -> LoggedEvent {
        LoggedEvent(at: start.addingTimeInterval(Double(index)), event: .hopUnavailable(app: .instagram))
    }

    @Test func appendsInOrderAndReadsBack() throws {
        let directory = try TemporaryDirectory()
        let log = EventLog(directory: directory.subdirectory("nested"))
        #expect(try log.readAll().isEmpty)
        let events = (0..<5).map(event)
        for item in events {
            try log.append(item)
        }
        #expect(try log.readAll() == events)
        let lines = try String(contentsOf: log.fileURL, encoding: .utf8).split(separator: "\n")
        #expect(lines.count == 5)
    }

    @Test func aTornFinalLineIsSkipped() throws {
        let directory = try TemporaryDirectory()
        let log = EventLog(directory: directory.url)
        let events = [event(0), event(1)]
        for item in events {
            try log.append(item)
        }
        let handle = try FileHandle(forWritingTo: log.fileURL)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(#"{"at":12,"ev"#.utf8))
        try handle.close()
        #expect(try log.readAll() == events)
    }

    @Test func rotatesAndBoundsItsSize() throws {
        let directory = try TemporaryDirectory()
        let log = EventLog(directory: directory.url, maximumBytes: 400)
        let events = (0..<40).map(event)
        for item in events {
            try log.append(item)
        }
        let all = try log.readAll()
        #expect(FileManager.default.fileExists(atPath: log.archiveURL.path))
        // Only the newest events survive, still in order and contiguous.
        #expect(!all.isEmpty)
        #expect(all.count < events.count)
        #expect(all == Array(events.suffix(all.count)))
    }

    @Test func everyKindOfEventRoundTrips() throws {
        let directory = try TemporaryDirectory()
        let log = EventLog(directory: directory.url)
        let snapshot = try sampleSnapshot()
        let record = try #require(snapshot.state.checkIns.first)
        let session = ActivitySession(kind: .focus, verification: .honor, startedAt: start, endedAt: start.addingTimeInterval(1_500))
        let kinds: [PofuEvent] = [
            .checkInRequested(app: .tiktok, foreground: false),
            .passThrough(app: .instagram, passID: UUID()),
            .hopShown(attemptID: UUID(), app: .youtube, rung: .intent),
            .hopUnavailable(app: .x),
            .reasonChosen(attemptID: UUID(), reason: .needBreak),
            .checkInResolved(record),
            .passEnded(passID: UUID(), refund: 6),
            .passVoided(passID: UUID(), refund: 13),
            .handoffFailed(app: .snapchat),
            .activityCredited(session, earned: 12, forfeited: 0),
            .quietSeedsCollected(quietSeeds: 12, sleepBonus: 10),
        ]
        let events = kinds.enumerated().map { LoggedEvent(at: start.addingTimeInterval(Double($0.offset)), event: $0.element) }
        for item in events {
            try log.append(item)
        }
        #expect(try log.readAll() == events)
    }
}

@Suite("Storage location")
struct StorageLocationTests {
    @Test func migratesLegacyFilesOnceAndNeverOverwrites() throws {
        let directory = try TemporaryDirectory()
        let legacy = PofuStore(location: StorageLocation(directory: directory.subdirectory("support"), kind: .applicationSupport))
        let group = StorageLocation(directory: directory.subdirectory("group"), kind: .appGroup)
        let snapshot = try sampleSnapshot()
        try legacy.save(snapshot)
        try legacy.log(.hopUnavailable(app: .reddit), at: Date(timeIntervalSince1970: 0))

        #expect(try group.migrateIfNeeded(from: legacy.location))
        let migrated = PofuStore(location: group)
        guard case .loaded(let loaded) = migrated.load() else {
            Issue.record("Expected the migrated snapshot")
            return
        }
        #expect(loaded == snapshot)
        #expect(try migrated.events.readAll().count == 1)
        #expect(!FileManager.default.fileExists(atPath: legacy.snapshotURL.path))

        // A second run, or a stale legacy file, never replaces group data.
        try legacy.save(PofuSnapshot())
        #expect(try !group.migrateIfNeeded(from: legacy.location))
        guard case .loaded(let again) = migrated.load() else {
            Issue.record("Expected the group snapshot")
            return
        }
        #expect(again == snapshot)
    }

    @Test func migratingFromItselfDoesNothing() throws {
        let directory = try TemporaryDirectory()
        let location = StorageLocation(directory: directory.url)
        try PofuStore(location: location).save(PofuSnapshot())
        #expect(try !location.migrateIfNeeded(from: location))
    }
}
