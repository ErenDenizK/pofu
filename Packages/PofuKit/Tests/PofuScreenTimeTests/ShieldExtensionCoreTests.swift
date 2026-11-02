import Foundation
import PofuCore
import PofuPersistence
import PofuScreenTime
import Testing

/// The shield extensions' decisions, shared by the extensions and
/// Rehearsal mode's replica: one shield per reach, and each button's
/// records.
@Suite("Shield extension core")
struct ShieldExtensionCoreTests {
    let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
    let app = ShieldedApp(kind: .application, token: "instagram-token", bundleIdentifier: "com.burbn.instagram", displayName: "Instagram")
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        return calendar
    }()

    private func makeCore() throws -> (ShieldExtensionCore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShieldExtensionCoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (ShieldExtensionCore(location: StorageLocation(directory: directory), calendar: calendar), directory)
    }

    private func records(in core: ShieldExtensionCore) -> [ScreenTimeRecord.Kind] {
        ScreenTimeInbox(location: core.location).read().records.map(\.kind)
    }

    private func effects(lifted: @escaping (UUID, Date) -> Void = { _, _ in }, posted: Bool = true) -> ShieldExtensionCore.Effects {
        ShieldExtensionCore.Effects(
            liftForQuickCheck: { _, passID, _, until in lifted(passID, until) },
            postNotification: { _, _ in posted },
            withdrawNotification: {}
        )
    }

    @Test func aReachIsRecordedOnceAndARedrawIsTheSameShield() throws {
        let (core, directory) = try makeCore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = core.drawShield(for: app, at: now, language: .turkish, submenuAvailable: true)
        let redraw = core.drawShield(for: app, at: now.addingTimeInterval(2), language: .turkish, submenuAvailable: true)
        #expect(redraw == first)
        #expect(records(in: core) == [.shieldShown(app: app, scene: .reach)])
        #expect(core.shownShield(for: app, at: now.addingTimeInterval(5)) == first)
    }

    @Test func buttonsMeanWhatTheShieldSaid() throws {
        let (core, directory) = try makeCore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let shown = core.drawShield(for: app, at: now, language: .english, submenuAvailable: true)
        #expect(ShieldExtensionCore.intent(for: .primary, shown: shown) == .skip)
        #expect(ShieldExtensionCore.intent(for: .submenuItem(0), shown: shown) == .quickCheck)
        #expect(ShieldExtensionCore.intent(for: .submenuItem(1), shown: shown) == .openWithPofu)
        // Without a remembered shield, the defaults.
        #expect(ShieldExtensionCore.intent(for: .secondary, shown: nil) == .openWithPofu)
        #expect(ShieldExtensionCore.intent(for: .submenuItem(0), shown: nil) == .quickCheck)
    }

    @Test func skipClosesAndRecordsAResist() throws {
        let (core, directory) = try makeCore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let outcome = core.respond(to: .skip, for: app, at: now, effects: effects())
        #expect(outcome == .close)
        #expect(records(in: core) == [.shieldResisted(app: app)])
    }

    @Test func aQuickCheckLiftsAndRecordsItsPass() throws {
        let (core, directory) = try makeCore()
        defer { try? FileManager.default.removeItem(at: directory) }
        var lifted: (UUID, Date)?
        let outcome = core.respond(to: .quickCheck, for: app, at: now, effects: effects(lifted: { lifted = ($0, $1) }))
        #expect(outcome == .lifted)
        let pass = try #require(lifted)
        #expect(pass.1 == now.addingTimeInterval(3 * 60))
        #expect(records(in: core) == [.quickCheckStarted(app: app, passID: pass.0, until: pass.1)])
    }

    @Test func openWithPofuRequestsAndLeavesANote() throws {
        let (core, directory) = try makeCore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let outcome = core.respond(to: .openWithPofu, for: app, at: now, effects: effects(posted: false))
        #expect(outcome == .requested(tryOpenParentalControlsApp: false))
        #expect(records(in: core) == [.openRequested(app: app)])
        let note = try #require(ShieldContextStore(location: core.location).openRequest.read())
        #expect(note.token == app.token)
        #expect(!note.notificationsAllowed)
        #expect(!note.breath)

        // The redrawn shield waits for the user, by hand without
        // notifications, and is not a new reach.
        let waiting = core.drawShield(for: app, at: now.addingTimeInterval(1), language: .english, submenuAvailable: true)
        #expect(waiting.scene == .waiting)
        #expect(waiting.line == .waitingForHand)
        #expect(ShieldExtensionCore.intent(for: .primary, shown: waiting) == .cancelRequest)
    }
}
