import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The voyage ride (ADR-0028, plan row 2d): the timeline, where she is, the passengers' hops, the cross-fade
/// under Reduce Motion, and the camera's flight of the ride's own length.
struct VoyageRideTests {
    private let ride = VoyageRide(from: .home, to: .koke, data: .fallback)
    private let start = VoyageRide.Spot(x: 0.8, y: 0.6, width: 0.2)

    @Test func theRideTakesThreeToFiveSeconds() throws {
        #expect((3.0 ... 5.0).contains(ride.duration))
        let data = try #require(VoyageData.shipped)
        #expect((3.0 ... 5.0).contains(VoyageRide(from: .home, to: .koke, data: data).duration))
    }

    @Test func theBeatsFollowInOrder() {
        #expect(ride.beat(at: 0).beat == .board)
        #expect(ride.beat(at: ride.board - 0.01).beat == .board)
        #expect(ride.beat(at: ride.board + 0.01).beat == .fly)
        #expect(ride.beat(at: ride.board + ride.fly + 0.01).beat == .moor)
        #expect(ride.beat(at: ride.duration + 0.01).beat == .done)
        #expect(ride.flightStart == ride.board)
        let mid = ride.beat(at: ride.board + ride.fly / 2)
        #expect(abs(mid.progress - 0.5) < 1e-9)
    }

    @Test func shePlaysFromTheMooringToTheCruiseToTheHover() {
        #expect(ride.whale(at: 0, start: start) == start)
        #expect(ride.whale(at: ride.board + ride.fly * 0.5, start: start) == VoyageRide.cruise)
        let end = ride.whale(at: ride.duration - 0.001, start: start)
        let hover = VoyageRide.hover(toTheRight: true)
        #expect(abs(end.x - hover.x) < 0.01 && abs(end.y - hover.y) < 0.01)
        #expect(ride.whaleOpacity(at: 0) == 1)
        #expect(ride.whaleOpacity(at: ride.duration + 1) == 0)
    }

    @Test func theRowGivesWayAsTheFlightLiftsOff() {
        #expect(ride.rowOpacity(at: ride.board - 0.01) == 1)
        #expect(ride.rowOpacity(at: ride.board + ride.fly) == 0)
    }

    @Test func shePointsTheWayShesGoing() {
        #expect(ride.toTheRight)
        #expect(!VoyageRide(from: .koke, to: .home, data: .fallback).toTheRight)
    }

    @Test func passengersHopOneAfterAnotherAndLandWhole() {
        for count in 1 ... 3 {
            for index in 0 ..< count {
                #expect(VoyageRide.hopProgress(index: index, count: count, beatProgress: 0) == 0)
                #expect(VoyageRide.hopProgress(index: index, count: count, beatProgress: 1) == 1)
            }
        }
        // The second leaves after the first.
        #expect(VoyageRide.hopProgress(index: 1, count: 2, beatProgress: 0.1) < VoyageRide.hopProgress(index: 0, count: 2, beatProgress: 0.1))
        let air = VoyageRide.hop(0.5)
        #expect(air.lift > 0.1)
        #expect(abs(VoyageRide.hop(0).lift) < 1e-9 && abs(VoyageRide.hop(1).lift) < 1e-9)
        #expect(VoyageRide.hop(1).along == 1)
    }

    @Test func passengersStandOnHerBackInFrontOfWhatShesCarrying() {
        // Seats are on the grass patch: in her body's middle third, above her middle.
        for index in 0 ..< 4 {
            let seat = VoyageRide.seat(index: index, count: 4, toTheRight: false)
            #expect(abs(seat.dx) < 0.3)
            #expect(seat.feetY > 0.4 && seat.feetY < 0.6)
        }
        // The pier is behind her as she goes: the island she leaves.
        #expect(VoyageRide.shore(index: 0, toTheRight: true).dx < 0)
        #expect(VoyageRide.shore(index: 0, toTheRight: false).dx > 0)
        // Mirrored with her.
        #expect(VoyageRide.seat(index: 0, count: 2, toTheRight: true).dx == -VoyageRide.seat(index: 0, count: 2, toTheRight: false).dx)
    }

    @Test func reduceMotionIsACrossFadeWithNoRide() {
        let reduced = VoyageRide(from: .home, to: .koke, data: .fallback, reduceMotion: true)
        #expect(reduced.reduced)
        #expect(reduced.board == 0 && reduced.moor == 0)
        #expect(reduced.duration == VoyageData.fallback.ride.reduced)
        #expect(reduced.beat(at: 0).beat == .fly)
    }

    @Test func theCameraFlightTakesTheRidesBeat() {
        var rig = CameraRig(framing: .map)
        let target = CameraPose(scale: rig.pose.scale * 1.8, look: WorldPoint(x: 900, y: 40), anchorY: 437)
        rig.startFlight(to: target, landing: .pose(target), seconds: ride.fly)
        #expect(rig.flight?.duration == ride.fly)
        var elapsed = 0.0
        while rig.flight != nil, elapsed < 6 {
            rig.advance(1.0 / 120)
            elapsed += 1.0 / 120
        }
        #expect(rig.flight == nil)
        #expect(abs(elapsed - ride.fly) < 0.03)
        #expect(abs(rig.pose.lookX - target.lookX) < 1e-6)
    }

    @Test func theRowsMooredSpotStaysOnTheScreenOnTheIslandsFoot() {
        let layout = VoyageRowLayout(width: 402, height: 874, data: .fallback)
        let place = layout.place(index: 0, position: 1)
        let spot = layout.mooredSpot(at: place)
        #expect(spot.x > 0 && spot.x < 1 && spot.y > 0.4 && spot.y < 0.9)
        #expect(abs(spot.width * 402 - place.width * 0.36) < 1e-9)
    }

    @Test func theHourGradesWhatHasNoNightOfItsOwn() {
        #expect(VoyageGrade.grade(light: "day") == .day)
        let night = VoyageGrade.grade(light: "night")
        #expect(night.blue > night.red && night.brightness < 0 && night.saturation < 1)
        #expect(VoyageGrade.grade(light: "golden").red > VoyageGrade.grade(light: "golden").blue)
    }
}
