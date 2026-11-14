import Foundation
import Testing
@testable import PofuWorld

@Suite("Plate hops")
struct PlateHopsTests {
    static let ids = ["mochi", "findik", "a"]

    /// Every hop start in the first `seconds` of a visit, sampled finely.
    static func hops(day: Int, seconds: Double) -> [PlateHops.Hop] {
        var seen: [Int: PlateHops.Hop] = [:]
        var t = 0.0
        while t < seconds {
            if let hop = PlateHops.hop(day: day, elapsed: t, ids: ids), seen[hop.slot] == nil { seen[hop.slot] = hop }
            t += 0.05
        }
        return seen.values.sorted { $0.slot < $1.slot }
    }

    @Test("same day and time give the same hop; days differ")
    func seeded() {
        for t in stride(from: 0.0, to: 120, by: 0.7) {
            #expect(PlateHops.hop(day: 9_000, elapsed: t, ids: Self.ids) == PlateHops.hop(day: 9_000, elapsed: t, ids: Self.ids))
        }
        let a = Self.hops(day: 9_000, seconds: 120).map(\.id)
        #expect((1...5).contains { Self.hops(day: 9_000 + $0, seconds: 120).map(\.id) != a })
    }

    @Test("one resident at a time, a hop every 6 to 14 seconds")
    func interval() {
        for day in [9_000, 9_001, 9_002] {
            var starts: [Double] = []
            var t = 0.0
            var inHop = false
            while t < 600 {
                let hop = PlateHops.hop(day: day, elapsed: t, ids: Self.ids)
                if hop != nil, !inHop { starts.append(t) }
                inHop = hop != nil
                t += 0.02
            }
            #expect(starts.count > 30)
            for (a, b) in zip(starts, starts.dropFirst()) {
                #expect(b - a >= 6 - 0.05 && b - a <= 14 + 0.05, "gap \(b - a)")
            }
        }
    }

    @Test("the lift is an arc that begins and ends on the ground")
    func arc() throws {
        let hop = try #require(Self.hops(day: 9_000, seconds: 30).first)
        #expect(hop.age < 0.1 && hop.lift < PlateHops.height * 0.5)
        for t in stride(from: 0.0, to: 300, by: 0.05) {
            if let h = PlateHops.hop(day: 9_000, elapsed: t, ids: Self.ids) {
                #expect(h.lift >= 0 && h.lift <= PlateHops.height + 1e-9)
            }
        }
    }

    @Test("nobody to hop, or no time, gives no hop")
    func empty() {
        #expect(PlateHops.hop(day: 9_000, elapsed: 3, ids: []) == nil)
        #expect(PlateHops.hop(day: 9_000, elapsed: -1, ids: Self.ids) == nil)
        #expect(PlateHops.hop(day: 9_000, elapsed: .nan, ids: Self.ids) == nil)
    }

    @Test("hops pause for a still frame, Reduce Motion, Low Power or heat and an inactive app")
    func pauses() {
        #expect(PlateHops.runs(isAmbient: true, reduceMotion: false, isStill: false))
        #expect(!PlateHops.runs(isAmbient: true, reduceMotion: true, isStill: false))
        #expect(!PlateHops.runs(isAmbient: true, reduceMotion: false, isStill: true))
        #expect(!PlateHops.runs(isAmbient: false, reduceMotion: false, isStill: false))
        #expect(!PlateHops.runs(isAmbient: true, reduceMotion: false, isStill: false, isActive: false))
    }
}
