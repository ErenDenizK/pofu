import Foundation
import PofuCore
import PofuScreenTime
import Testing

private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
private let instagram = ShieldedApp(kind: .application, token: "instagram")
private let social = ShieldedApp(kind: .category, token: "social")

@Suite("Live shield state: lifts that ended")
struct LiveShieldEndedLiftTests {
    @Test func prunedLiftsAreRememberedForAnHour() {
        let lift = ShieldLift(passID: UUID(), app: instagram, from: start, until: start.addingTimeInterval(180), origin: .shieldQuickCheck)
        var state = LiveShieldState(lifts: [lift])
        #expect(state.pruneLifts(at: start.addingTimeInterval(60)).isEmpty)
        #expect(state.pruneLifts(at: start.addingTimeInterval(200)) == [lift.passID])
        #expect(state.lifts.isEmpty)
        #expect(state.endedLifts == [lift])
        #expect(state.lastEndedLift(for: ["instagram"], at: start.addingTimeInterval(200)) == lift)
        #expect(state.lastQuickCheckEnd == lift.until)
        state.pruneLifts(at: start.addingTimeInterval(180 + LiveShieldState.endedLiftMemory + 1))
        #expect(state.endedLifts.isEmpty)
    }

    @Test func aLiftThatHasEndedButIsNotPrunedYetCounts() {
        let lift = ShieldLift(passID: UUID(), app: social, from: start, until: start.addingTimeInterval(900), origin: .hop)
        let state = LiveShieldState(lifts: [lift])
        #expect(state.lastEndedLift(for: ["social"], at: start.addingTimeInterval(600)) == nil)
        #expect(state.lastEndedLift(for: ["social"], at: start.addingTimeInterval(930))?.minutes == 15)
        #expect(state.lastEndedLift(for: ["instagram"], at: start.addingTimeInterval(930)) == nil)
        #expect(state.lastQuickCheckEnd == nil)
    }

    @Test func endingALiftEarlyRemembersWhenItEnded() {
        let lift = ShieldLift(passID: UUID(), app: instagram, from: start, until: start.addingTimeInterval(900), origin: .hop)
        var state = LiveShieldState(lifts: [lift])
        state.endLift(lift.passID, at: start.addingTimeInterval(300))
        #expect(state.lifts.isEmpty)
        #expect(state.endedLifts.first?.until == start.addingTimeInterval(300))
        #expect(state.endedLifts.first?.minutes == 5)
    }

    @Test func aStateFromBeforeGateV2Loads() throws {
        let json = #"{"version":1,"selection":{"applications":[],"categories":[],"webDomains":[]},"shields":{},"thresholds":[],"lifts":[{"passID":"4B4C3B0E-7D3B-4C47-9B44-1B0C3E1F2A10","app":{"kind":"application","token":"instagram"},"from":0,"until":60}]}"#
        let state = try JSONDecoder().decode(LiveShieldState.self, from: Data(json.utf8))
        #expect(state.lifts.count == 1)
        #expect(state.lifts.first?.origin == nil)
        #expect(state.endedLifts.isEmpty)
        let decoded = try JSONDecoder().decode(LiveShieldState.self, from: JSONEncoder().encode(state))
        #expect(decoded == state)
    }
}
