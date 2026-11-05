import Foundation
import Testing
@testable import PofuWorld

@Suite("Touch field (experience v1 §1.3)")
struct TouchFieldTests {
    private let props: [(id: String, base: WorldPoint)] = [
        (id: "near", base: WorldPoint(x: 10, y: 0)),
        (id: "far", base: WorldPoint(x: 200, y: 0)),
    ]

    @Test func aFingerPassingNearAPropStartsASway() {
        var field = TouchField()
        field.brush(at: WorldPoint(x: 0, y: 0), t: 0, props: props)
        field.brush(at: WorldPoint(x: 8, y: 4), t: 0.05, props: props)
        #expect(field.impulses.map(\.prop) == ["near"])
        #expect(field.impulses.first?.direction == 1)
        #expect(field.isActive(at: 0.1))
        #expect(abs(field.sway(of: "near", at: 0.05)) > 0)
        #expect(field.sway(of: "far", at: 0.05) == 0)
    }

    @Test func aPropOutOfReachStaysStill() {
        var field = TouchField()
        field.brush(at: WorldPoint(x: 0, y: 60), t: 0, props: props)
        #expect(field.impulses.isEmpty)
        #expect(!field.isActive(at: 0))
    }

    @Test func theSwayDecaysToZeroByTwelveTenths() {
        var field = TouchField()
        field.brush(at: WorldPoint(x: 0, y: 0), t: 10, props: props)
        let early = abs(field.sway(of: "near", at: 10.02))
        #expect(early > 0)
        #expect(field.isActive(at: 11.19))
        #expect(field.sway(of: "near", at: 11.21) == 0)
        #expect(field.sway(of: "near", at: 12) == 0)
        #expect(!field.isActive(at: 11.21))
        // Its envelope only shrinks.
        var peak = 0.0
        var t = 10.0
        while t < 11.2 {
            peak = max(peak, abs(field.sway(of: "near", at: t)))
            t += 0.01
        }
        #expect(peak <= TouchField.peakDegrees + 1e-9)
        #expect(abs(field.sway(of: "near", at: 11.15)) < early)
    }

    @Test func itKeepsAtMostSixteenImpulses() {
        let many = (0..<40).map { (id: "p\($0)", base: WorldPoint(x: Double($0), y: 0)) }
        var field = TouchField()
        field.brush(at: WorldPoint(x: 0, y: 0), t: 0, props: many)
        field.brush(at: WorldPoint(x: 40, y: 0), t: 0.1, props: many)
        #expect(field.impulses.count <= TouchField.capacity)
    }

    @Test func aRetriggeredPropReplacesItsImpulse() {
        var field = TouchField()
        field.brush(at: WorldPoint(x: 10, y: 0), t: 0, props: props)
        field.brush(at: WorldPoint(x: 10, y: 1), t: 0.3, props: props)
        #expect(field.impulses.filter { $0.prop == "near" }.count == 1)
        #expect(field.impulses.first?.t0 == 0.3)
    }

    @Test func pruningDropsTheExpired() {
        var field = TouchField()
        field.brush(at: WorldPoint(x: 10, y: 0), t: 0, props: props)
        field.prune(at: 5)
        #expect(field.impulses.isEmpty)
    }

    @Test func aLeftwardStrokeSwaysTheOtherWay() {
        var field = TouchField()
        field.brush(at: WorldPoint(x: 30, y: 0), t: 0, props: props)
        field.brush(at: WorldPoint(x: 6, y: 0), t: 0.05, props: props)
        #expect(field.impulses.first?.direction == -1)
    }
}
