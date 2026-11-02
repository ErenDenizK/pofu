import Foundation
import PofuCore
import Testing
@testable import PofuPersistence

@Suite("Shield context store")
struct ShieldContextStoreTests {
    private let day = LocalDay(year: 2026, month: 11, day: 14)

    @Test func theMonitorKeepsTheDaysHighestStep() throws {
        let directory = try TemporaryDirectory()
        let store = ShieldContextStore(location: StorageLocation(directory: directory.url))
        #expect(store.usage.read() == nil)
        try store.noteMeasured(30, on: day)
        try store.noteMeasured(15, on: day)
        #expect(store.usage.read() == GuardedUsageDay(day: day, measuredMinutes: 30))
        try store.noteMeasured(15, on: day.adding(days: 1))
        #expect(store.usage.read() == GuardedUsageDay(day: day.adding(days: 1), measuredMinutes: 15))
        // A late record from yesterday does not overwrite today.
        try store.noteMeasured(60, on: day)
        #expect(store.usage.read()?.day == day.adding(days: 1))
    }

    @Test func eachFileRoundTrips() throws {
        let directory = try TemporaryDirectory()
        let store = ShieldContextStore(location: StorageLocation(directory: directory.url))
        let at = Date(timeIntervalSinceReferenceDate: 815_000_000)
        let state = ShieldAppState(writtenAt: at, day: day, reachesToday: 3, resistedToday: 2, recentReaches: [at], dailyHourMinutes: 90)
        try store.appState.write(state)
        #expect(store.appState.read() == state)
        let note = ShieldOpenRequestNote(token: "token", requestedAt: at, notificationsAllowed: false, breath: true)
        try store.openRequest.write(note)
        #expect(store.openRequest.read() == note)
        store.openRequest.remove()
        #expect(store.openRequest.read() == nil)
    }
}
