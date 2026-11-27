import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The voyage row (ADR-0028, plan row 2c): the route as data, what each stop is, where the islands stand in
/// the row and what a swipe or a tap does.
struct VoyageRouteTests {
    private func status(_ phase: WonderStatus.Phase, stage: Int = 0) -> WonderStatus {
        WonderStatus(phase: phase, stage: stage)
    }

    private let layout = VoyageRowLayout(width: 402, height: 874, data: .fallback)

    @Test func theRouteIsDataInTheShippedMap() throws {
        let data = try #require(VoyageData.shipped, "world-map.json carries `voyage`")
        #expect(data == .fallback)
        #expect(data.order == ["home", "koke", "caglayan"])
    }

    @Test func theRowGrowsWithTheStory() {
        let none = WonderStatus()
        let day1 = VoyageRoute.stops(koke: none, caglayan: none)
        #expect(day1.map(\.island) == [.home, .koke])
        #expect(day1.map(\.status) == [.home, .locked])
        let koke = VoyageRoute.stops(koke: status(.arrived), caglayan: none)
        #expect(koke.map(\.status) == [.home, .open, .locked])
        let healed = status(.arrived, stage: WonderIslands.healedStage)
        let both = VoyageRoute.stops(koke: healed, caglayan: status(.arrived))
        #expect(both.map(\.status) == [.home, .healed, .open])
    }

    @Test func aLockedStopCannotSailAndEveryStopHasALine() {
        let stops = VoyageRoute.stops(koke: WonderStatus(), caglayan: WonderStatus())
        #expect(stops[0].canSail)
        #expect(!stops[1].canSail)
        #expect(stops.map(\.lineKey) == ["voyage.line.home.home", "voyage.line.koke.locked"])
    }

    @Test func theIslandInViewIsSeventyPercentOfTheWidthAtTheMiddle() {
        let p = layout.place(index: 1, position: 1)
        #expect(abs(p.width - 0.7 * 402) < 0.001)
        #expect(abs(p.x - 201) < 0.001)
        #expect(p.weight == 1)
    }

    @Test func neighboursAreCutByTheEdgesAndStaySmaller() {
        for side in [0, 2] {
            let share = layout.visibleShare(index: side, position: 1)
            #expect(share > 0.05 && share < 0.4, "neighbour \(side) shows \(share)")
            let p = layout.place(index: side, position: 1)
            #expect(p.width < layout.place(index: 1, position: 1).width)
            #expect(p.y < layout.place(index: 1, position: 1).y)
        }
        // The edge cuts it: part of its art is outside the screen.
        let right = layout.place(index: 2, position: 1)
        #expect(right.x + right.width / 2 > 402)
    }

    @Test func aSwipeIsOneIslandAndSnaps() {
        // A short slow drag stays; a long one goes one stop; a flick goes one stop; never two.
        #expect(layout.settle(from: 1, position: layout.position(from: 1, translation: -40, count: 3), velocity: 0, count: 3) == 1)
        #expect(layout.settle(from: 1, position: layout.position(from: 1, translation: -200, count: 3), velocity: 0, count: 3) == 2)
        #expect(layout.settle(from: 1, position: layout.position(from: 1, translation: -30, count: 3), velocity: -900, count: 3) == 2)
        #expect(layout.settle(from: 1, position: layout.position(from: 1, translation: 30, count: 3), velocity: 900, count: 3) == 0)
        #expect(layout.settle(from: 0, position: layout.position(from: 0, translation: -900, count: 3), velocity: -4000, count: 3) == 1)
    }

    @Test func theRowBandsPastItsEnds() {
        let beyond = layout.position(from: 0, translation: 300, count: 3)
        #expect(beyond < 0 && beyond > -0.5)
        #expect(layout.settle(from: 0, position: beyond, velocity: 800, count: 3) == 0)
        #expect(layout.settle(from: 2, position: 2.3, velocity: -800, count: 3) == 2)
    }

    @Test func aTapOnANeighbourGlidesThereAndAnywhereElseDoesNothing() {
        #expect(layout.tapTarget(x: 395, selected: 1, count: 3) == 2)
        #expect(layout.tapTarget(x: 5, selected: 1, count: 3) == 0)
        #expect(layout.tapTarget(x: 201, selected: 1, count: 3) == nil)
        #expect(layout.tapTarget(x: 5, selected: 0, count: 3) == nil)
    }

    @MainActor
    @Test func theRowOpensOnTheIslandTheCameraIsAt() {
        let state = VoyageRowState()
        state.open(on: .koke)
        #expect(state.island == .koke && state.origin == .koke)
        state.choose(.home)
        #expect(state.island == .home && state.origin == .koke)
    }
}
