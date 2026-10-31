import Foundation
import PofuCore
import PofuScreenTime
import Testing

private let instagram = ApplicationToken("instagram")
private let tiktok = ApplicationToken("tiktok")
private let notes = ApplicationToken("notes")
private let social = CategoryToken("social")
private let feeds = DistractionSelection(applications: [instagram, tiktok])

private let istanbul: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
    return calendar
}()

private func at(_ hour: Int, _ minute: Int = 0) -> Date {
    let components = DateComponents(year: 2026, month: 11, day: 2, hour: hour, minute: minute)
    guard let date = istanbul.date(from: components) else {
        fatalError("Invalid date")
    }
    return date
}

/// A service that is already authorized.
private func authorizedService(categories: [ApplicationToken: CategoryToken] = [:]) -> SimulatedScreenTimeService {
    SimulatedScreenTimeService(
        authorizationStatus: .approved,
        selection: feeds,
        applicationCategories: categories,
        calendar: istanbul
    )
}

@Suite("Simulated Screen Time: authorization")
struct AuthorizationTests {
    @Test func requestingApprovesAndAnnouncesIt() async throws {
        let service = SimulatedScreenTimeService(authorizationResponse: .approved, calendar: istanbul)
        #expect(await service.authorizationStatus() == .notDetermined)
        let status = try await service.requestAuthorization()
        #expect(status == .approved)
        #expect(await service.authorizationStatus() == .approved)
        #expect(await service.eventLog == [.authorizationChanged(.approved)])
    }

    @Test func decliningIsAStatusNotAnError() async throws {
        let service = SimulatedScreenTimeService(authorizationResponse: .denied, calendar: istanbul)
        let status = try await service.requestAuthorization()
        #expect(status == .denied)
    }

    @Test func theSystemAsksOnlyOnce() async throws {
        let service = SimulatedScreenTimeService(authorizationStatus: .denied, authorizationResponse: .approved, calendar: istanbul)
        let status = try await service.requestAuthorization()
        #expect(status == .denied)
        #expect(await service.eventLog.isEmpty)
    }

    @Test func operationsRequireAuthorization() async {
        let service = SimulatedScreenTimeService(calendar: istanbul)
        await #expect(throws: ScreenTimeError.notAuthorized) {
            try await service.applyShield("bedtime", to: feeds)
        }
        await #expect(throws: ScreenTimeError.notAuthorized) {
            try await service.updateDistractingSelection(feeds)
        }
        await #expect(throws: ScreenTimeError.notAuthorized) {
            try await service.scheduleThreshold(ThresholdSchedule(id: "budget", selection: feeds, threshold: 60))
        }
    }

    @Test func revokingRemovesShieldsAndSchedules() async throws {
        let service = authorizedService()
        try await service.applyShield("bedtime", to: feeds)
        try await service.scheduleThreshold(ThresholdSchedule(id: "budget", selection: feeds, threshold: 60))
        await service.setAuthorizationStatus(.denied)
        #expect(await service.activeShields().isEmpty)
        #expect(await service.scheduledThresholds().isEmpty)
        #expect(await service.eventLog == [.authorizationChanged(.denied)])
    }
}

@Suite("Simulated Screen Time: selection and shields")
struct ShieldTests {
    @Test func selectionIsStored() async throws {
        let service = authorizedService()
        let updated = DistractionSelection(applications: [instagram], categories: [social])
        try await service.updateDistractingSelection(updated)
        #expect(await service.distractingSelection() == updated)
    }

    @Test func shieldedAppsShowTheShield() async throws {
        let service = authorizedService()
        try await service.applyShield("bedtime", to: feeds)
        #expect(await service.simulateOpen(of: instagram) == "bedtime")
        #expect(await service.simulateOpen(of: notes) == nil)
        #expect(await service.eventLog == [.shieldShown("bedtime", application: instagram)])
    }

    @Test func categoryShieldsCoverTheirApps() async throws {
        let service = authorizedService(categories: [instagram: social])
        try await service.applyShield("study", to: DistractionSelection(categories: [social]))
        #expect(await service.simulateOpen(of: instagram) == "study")
        #expect(await service.simulateOpen(of: tiktok) == nil)
    }

    @Test func namedShieldsAreIndependent() async throws {
        let service = authorizedService()
        try await service.applyShield("bedtime", to: feeds)
        try await service.applyShield("budget", to: DistractionSelection(applications: [instagram]))
        // Deterministic: the first name wins when several shields match.
        #expect(await service.simulateOpen(of: instagram) == "bedtime")
        await service.removeShield("bedtime")
        #expect(await service.activeShields() == ["budget": DistractionSelection(applications: [instagram])])
        #expect(await service.simulateOpen(of: instagram) == "budget")
        #expect(await service.simulateOpen(of: tiktok) == nil)
    }

    @Test func emptySelectionsCannotBeShielded() async {
        let service = authorizedService()
        await #expect(throws: ScreenTimeError.emptySelection) {
            try await service.applyShield("bedtime", to: .empty)
        }
    }
}

@Suite("Simulated Screen Time: thresholds")
struct ThresholdTests {
    @Test func thresholdFiresOnceWhenCrossed() async throws {
        let service = authorizedService()
        try await service.scheduleThreshold(ThresholdSchedule(id: "budget", selection: feeds, threshold: 15 * 60))
        await service.simulateUsage(of: instagram, for: 10 * 60, at: at(14))
        #expect(await service.eventLog.isEmpty)
        await service.simulateUsage(of: tiktok, for: 5 * 60, at: at(14, 30))
        #expect(await service.eventLog == [.thresholdReached("budget")])
        await service.simulateUsage(of: instagram, for: 30 * 60, at: at(15))
        #expect(await service.eventLog == [.thresholdReached("budget")])
        #expect(await service.recordedUsage(for: "budget") == 45 * 60)
    }

    @Test func usageOfOtherAppsDoesNotCount() async throws {
        let service = authorizedService()
        try await service.scheduleThreshold(ThresholdSchedule(id: "budget", selection: feeds, threshold: 60))
        await service.simulateUsage(of: notes, for: 3_600, at: at(14))
        #expect(await service.recordedUsage(for: "budget") == 0)
        #expect(await service.eventLog.isEmpty)
    }

    @Test func onlyUsageInsideTheWindowCounts() async throws {
        let service = authorizedService()
        let bedtime = DailyWindow(start: LocalTime(hour: 23), end: LocalTime(hour: 6))
        try await service.scheduleThreshold(
            ThresholdSchedule(id: "night", selection: feeds, threshold: 10 * 60, window: bedtime)
        )
        await service.simulateUsage(of: instagram, for: 20 * 60, at: at(21))
        #expect(await service.recordedUsage(for: "night") == 0)
        await service.simulateUsage(of: instagram, for: 10 * 60, at: at(23, 15))
        #expect(await service.eventLog == [.thresholdReached("night")])
    }

    @Test func aNewDayResetsUsageAndRearms() async throws {
        let service = authorizedService()
        try await service.scheduleThreshold(ThresholdSchedule(id: "budget", selection: feeds, threshold: 60))
        await service.simulateUsage(of: instagram, for: 60, at: at(10))
        await service.simulateNewDay()
        #expect(await service.recordedUsage(for: "budget") == 0)
        await service.simulateUsage(of: instagram, for: 60, at: at(10))
        #expect(await service.eventLog == [.thresholdReached("budget"), .thresholdReached("budget")])
    }

    @Test(arguments: [0.0, -60, .infinity, .nan])
    func invalidThresholdsAreRejected(threshold: TimeInterval) async {
        let service = authorizedService()
        await #expect(throws: ScreenTimeError.invalidThreshold) {
            try await service.scheduleThreshold(ThresholdSchedule(id: "budget", selection: feeds, threshold: threshold))
        }
    }

    @Test func cancellingStopsMonitoring() async throws {
        let service = authorizedService()
        try await service.scheduleThreshold(ThresholdSchedule(id: "b", selection: feeds, threshold: 60))
        try await service.scheduleThreshold(ThresholdSchedule(id: "a", selection: feeds, threshold: 120))
        #expect(await service.scheduledThresholds().map(\.id) == ["a", "b"])
        await service.cancelThreshold("b")
        await service.simulateUsage(of: instagram, for: 600, at: at(10))
        #expect(await service.eventLog == [.thresholdReached("a")])
    }
}

@Suite("Simulated Screen Time: event stream")
struct EventStreamTests {
    @Test(.timeLimit(.minutes(1)))
    func everySubscriberReceivesEventsInOrder() async throws {
        let service = authorizedService()
        try await service.applyShield("bedtime", to: feeds)
        let first = await service.events()
        let second = await service.events()

        await service.simulateOpen(of: instagram)
        await service.setAuthorizationStatus(.denied)
        await service.finishEvents()

        var firstEvents: [ScreenTimeEvent] = []
        for await event in first {
            firstEvents.append(event)
        }
        var secondEvents: [ScreenTimeEvent] = []
        for await event in second {
            secondEvents.append(event)
        }
        let expected: [ScreenTimeEvent] = [
            .shieldShown("bedtime", application: instagram),
            .authorizationChanged(.denied),
        ]
        #expect(firstEvents == expected)
        #expect(secondEvents == expected)
    }

    @Test(.timeLimit(.minutes(1)))
    func subscribersOnlySeeEventsAfterSubscribing() async throws {
        let service = authorizedService()
        try await service.applyShield("bedtime", to: feeds)
        await service.simulateOpen(of: instagram)
        let late = await service.events()
        await service.simulateOpen(of: tiktok)
        await service.finishEvents()

        var events: [ScreenTimeEvent] = []
        for await event in late {
            events.append(event)
        }
        #expect(events == [.shieldShown("bedtime", application: tiktok)])
    }

    @Test func eventsAreCodable() throws {
        let events: [ScreenTimeEvent] = [
            .authorizationChanged(.approved),
            .thresholdReached("budget"),
            .shieldShown("bedtime", application: instagram),
        ]
        let decoded = try JSONDecoder().decode([ScreenTimeEvent].self, from: JSONEncoder().encode(events))
        #expect(decoded == events)
    }
}
