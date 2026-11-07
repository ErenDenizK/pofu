import Foundation
import Testing
@testable import PofuCore

/// The Economy still grants the emergency pass; no rung offers it since the
/// pay rung left (ADR-0015), so these tests do not go through the gate.
@Suite("Emergency pass")
struct EmergencyPassTests {
    let economy = Economy(calendar: .istanbul)
    let noon = instant(2026, 11, 2, 12)

    @Test func neverWorksTwiceWhenTheClockMovesBackwards() {
        var wallet = Wallet()
        let tomorrow = instant(2026, 11, 3, 9)
        #expect(economy.grantEmergencyPass(for: testTarget, at: tomorrow, from: &wallet) != nil)
        #expect(economy.grantEmergencyPass(for: testTarget, at: noon, from: &wallet) == nil)
        #expect(economy.nextEmergencyPassDay(for: wallet, at: noon) == LocalDay(year: 2026, month: 11, day: 4))
    }

    @Test func canBeSwitchedOff() {
        let off = Economy(
            configuration: EconomyConfiguration(friction: FrictionRules(emergencyPassMinutes: 0)),
            calendar: .istanbul
        )
        var wallet = Wallet()
        #expect(!off.isEmergencyPassAvailable(in: wallet, at: noon))
        #expect(off.grantEmergencyPass(for: testTarget, at: noon, from: &wallet) == nil)
    }

    @Test func availabilityCrossesMidnightInLocalTime() {
        var wallet = Wallet()
        let lateNight = instant(2026, 11, 2, 23, 59)
        #expect(economy.grantEmergencyPass(for: testTarget, at: lateNight, from: &wallet) != nil)
        #expect(!economy.isEmergencyPassAvailable(in: wallet, at: instant(2026, 11, 2, 23, 59, 59)))
        #expect(economy.isEmergencyPassAvailable(in: wallet, at: instant(2026, 11, 3, 0, 0)))
    }
}
