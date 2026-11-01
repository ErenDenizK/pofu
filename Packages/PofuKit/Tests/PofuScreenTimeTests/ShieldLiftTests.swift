import Foundation
import PofuCore
import PofuPersistence
import PofuScreenTime
import Testing

private let instagram = ApplicationToken("instagram")
private let tiktok = ApplicationToken("tiktok")
private let social = CategoryToken("social")
private let news = WebDomainToken("news")
private let feeds = DistractionSelection(applications: [instagram, tiktok])
private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

private func shielded(_ token: ApplicationToken) -> ShieldedApp {
    ShieldedApp(kind: .application, token: token.rawValue)
}

@Suite("Simulated Screen Time: passes lift shields")
struct SimulatedLiftTests {
    private func gatedService() async throws -> SimulatedScreenTimeService {
        let service = SimulatedScreenTimeService(authorizationStatus: .approved)
        try await service.applyShield("pofu.gate", to: feeds)
        return service
    }

    @Test func aPassLetsItsAppThroughUntilItEnds() async throws {
        let service = try await gatedService()
        let passID = UUID()
        try await service.liftShields(from: shielded(instagram), passID: passID, at: start, until: start.addingTimeInterval(180))

        #expect(await service.simulateOpen(of: instagram, at: start.addingTimeInterval(60)) == nil)
        #expect(await service.simulateOpen(of: tiktok, at: start.addingTimeInterval(60)) == "pofu.gate")
        #expect(await service.simulateOpen(of: instagram, at: start.addingTimeInterval(180)) == "pofu.gate")
        #expect(await service.shieldLifts().map(\.passID) == [passID])
    }

    @Test func endingThePassEarlyRestoresTheShield() async throws {
        let service = try await gatedService()
        let passID = UUID()
        try await service.liftShields(from: shielded(instagram), passID: passID, at: start, until: start.addingTimeInterval(900))
        await service.restoreShields(passID: passID)
        #expect(await service.simulateOpen(of: instagram, at: start.addingTimeInterval(60)) == "pofu.gate")
        #expect(await service.shieldLifts().isEmpty)
    }

    @Test func aCategoryLiftCoversItsApps() async throws {
        let service = SimulatedScreenTimeService(authorizationStatus: .approved, applicationCategories: [instagram: social])
        try await service.applyShield("pofu.gate", to: DistractionSelection(categories: [social]))
        try await service.liftShields(
            from: ShieldedApp(kind: .category, token: social.rawValue),
            passID: UUID(),
            at: start,
            until: start.addingTimeInterval(300)
        )
        #expect(await service.simulateOpen(of: instagram, at: start.addingTimeInterval(10)) == nil)
        #expect(await service.simulateOpen(of: instagram, at: start.addingTimeInterval(301)) == "pofu.gate")
    }

    @Test func liftingNeedsAuthorizationAndAFutureEnd() async throws {
        let unauthorized = SimulatedScreenTimeService()
        await #expect(throws: ScreenTimeError.notAuthorized) {
            try await unauthorized.liftShields(from: shielded(instagram), passID: UUID(), at: start, until: start.addingTimeInterval(60))
        }
        let service = try await gatedService()
        await #expect(throws: ScreenTimeError.invalidLift) {
            try await service.liftShields(from: shielded(instagram), passID: UUID(), at: start, until: start)
        }
    }

    @Test func revokingAuthorizationDropsLifts() async throws {
        let service = try await gatedService()
        try await service.liftShields(from: shielded(instagram), passID: UUID(), at: start, until: start.addingTimeInterval(60))
        await service.setAuthorizationStatus(.denied)
        #expect(await service.shieldLifts().isEmpty)
    }
}

@Suite("Live shield state")
struct LiveShieldStateTests {
    private func state(lifts: [ShieldLift]) -> LiveShieldState {
        LiveShieldState(
            selection: feeds,
            shields: ["pofu.gate": DistractionSelection(applications: [instagram, tiktok], categories: [social], webDomains: [news])],
            lifts: lifts
        )
    }

    @Test func withoutPassesEverythingIsShielded() {
        let shields = state(lifts: []).effectiveShields(at: start)
        let gate = shields["pofu.gate"]
        #expect(gate?.applications == [instagram, tiktok])
        #expect(gate?.categories == [social])
        #expect(gate?.exceptApplications.isEmpty == true)
        #expect(gate?.webDomains == [news])
    }

    @Test func aLiftedAppLeavesTheShieldAndItsCategory() {
        let lift = ShieldLift(passID: UUID(), app: shielded(instagram), from: start, until: start.addingTimeInterval(300))
        let gate = state(lifts: [lift]).effectiveShields(at: start.addingTimeInterval(1))["pofu.gate"]
        #expect(gate?.applications == [tiktok])
        #expect(gate?.exceptApplications == [instagram])
        #expect(gate?.categories == [social])
    }

    @Test func theEndedPassNoLongerCountsEvenIfTheCallbackIsEarly() {
        let lift = ShieldLift(passID: UUID(), app: shielded(instagram), from: start, until: start.addingTimeInterval(300))
        let gate = state(lifts: [lift]).effectiveShields(at: start.addingTimeInterval(299), excluding: lift.passID)["pofu.gate"]
        #expect(gate?.applications == [instagram, tiktok])
        #expect(gate?.exceptApplications.isEmpty == true)
    }

    @Test func expiredLiftsArePruned() {
        let ended = ShieldLift(passID: UUID(), app: shielded(instagram), from: start, until: start.addingTimeInterval(60))
        let running = ShieldLift(passID: UUID(), app: shielded(tiktok), from: start, until: start.addingTimeInterval(600))
        var state = state(lifts: [ended, running])
        #expect(state.effectiveShields(at: start.addingTimeInterval(120))["pofu.gate"]?.applications == [instagram])
        let pruned = state.pruneLifts(at: start.addingTimeInterval(120))
        #expect(pruned == [ended.passID])
        #expect(state.lifts == [running])
    }

    @Test func aLiftedDomainOrCategoryLeavesItsShield() {
        let lifts = [
            ShieldLift(passID: UUID(), app: ShieldedApp(kind: .category, token: social.rawValue), from: start, until: start.addingTimeInterval(60)),
            ShieldLift(passID: UUID(), app: ShieldedApp(kind: .webDomain, token: news.rawValue), from: start, until: start.addingTimeInterval(60)),
        ]
        let gate = state(lifts: lifts).effectiveShields(at: start)["pofu.gate"]
        #expect(gate?.categories.isEmpty == true)
        #expect(gate?.webDomains.isEmpty == true)
        #expect(gate?.isEmpty == false)
    }

    @Test func theStateRoundTripsThroughTheAppGroupFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LiveShieldStateTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = LiveShieldState.file(in: StorageLocation(directory: directory))
        let lift = ShieldLift(passID: UUID(), app: shielded(instagram), from: start, until: start.addingTimeInterval(300))
        let original = LiveShieldState(
            selection: feeds,
            pickerData: Data([1, 2, 3]),
            shields: ["pofu.gate": feeds],
            thresholds: [ThresholdSchedule(id: "pofu.usage.15", selection: feeds, threshold: 900)],
            lifts: [lift]
        )
        try file.write(original)
        #expect(file.read() == original)
    }
}
