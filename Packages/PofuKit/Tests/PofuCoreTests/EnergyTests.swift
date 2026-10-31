import Foundation
import Testing
@testable import PofuCore

@Suite("Energy")
struct EnergyTests {
    @Test func arithmeticAndOrdering() {
        let a: Energy = 15
        let b = Energy(4)
        #expect(a + b == 19)
        #expect(a - b == 11)
        #expect(b < a)
        #expect(Energy.zero == Energy(0))
        var c = a
        c += b
        c -= 2
        #expect(c == 17)
        #expect(max(Energy(-3), .zero) == .zero)
    }

    @Test func encodesAsBareInteger() throws {
        let data = try JSONEncoder().encode(Energy(42))
        #expect(String(decoding: data, as: UTF8.self) == "42")
        #expect(try JSONDecoder().decode(Energy.self, from: Data("7".utf8)) == 7)
    }

    @Test func description() {
        #expect(Energy(3).description == "3 energy")
    }
}

@Suite("Rounding")
struct RoundingTests {
    @Test(arguments: [
        (12.5, 12), (12.0, 12), (11.999_999_999_99, 12), (0.4, 0), (-0.5, -1),
    ])
    func down(value: Double, expected: Int) {
        #expect(Rounding.down(value) == expected)
    }

    @Test(arguments: [
        (12.5, 13), (12.0, 12), (12.000_000_000_01, 12), (0.1, 1), (114.999_999_999_999_99, 115),
    ])
    func up(value: Double, expected: Int) {
        #expect(Rounding.up(value) == expected)
    }

    @Test func toleranceAbsorbsFloatingPointNoise() {
        // 1.15 * 100 is 114.99999999999999 in binary floating point.
        #expect(Rounding.down(1.15 * 100) == 115)
        // 1.1 * 10 is 11.000000000000002.
        #expect(Rounding.up(1.1 * 10) == 11)
    }

    @Test func saturatesInsteadOfTrapping() {
        #expect(Rounding.up(.infinity) == Int.max)
        #expect(Rounding.down(-.infinity) == Int.min)
        #expect(Rounding.up(.nan) == 0)
        #expect(Rounding.saturatingInt(1e300) == Int.max)
    }

    @Test func unitIntervalClamps() {
        #expect(Rounding.unitInterval(-1) == 0)
        #expect(Rounding.unitInterval(2) == 1)
        #expect(Rounding.unitInterval(.nan) == 0)
        #expect(Rounding.unitInterval(0.25) == 0.25)
    }
}
