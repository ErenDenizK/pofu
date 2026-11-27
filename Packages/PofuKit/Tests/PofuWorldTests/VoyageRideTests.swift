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

    @Test func theRowGlidesBackToTheIslandSheLeavesBeforeTheyHop() {
        // The player chose Köke (stop 1); she waits at Home (stop 0): the row comes back to Home in the first
        // part of the board beat, and nobody hops until it has.
        #expect(ride.rowPosition(at: 0, selected: 1, origin: 0) == 1)
        #expect(ride.rowPosition(at: ride.board * VoyageRide.glideShare, selected: 1, origin: 0) == 0)
        #expect(ride.rowPosition(at: ride.board, selected: 1, origin: 0) == 0)
        #expect(ride.rowPosition(at: ride.board + 1, selected: 1, origin: 0) == 0)
        #expect(VoyageRide.boardProgress(VoyageRide.glideShare) == 0)
        #expect(VoyageRide.boardProgress(1) == 1)
        #expect(ride.board * VoyageRide.glideShare >= 0.3)
    }

    @Test func sheAndTheIslandsShareOneWorldScale() {
        // Moored, her body is the share of the island's width; in the air she is the same share of the
        // camera's island, whatever the camera's scale: her width follows the camera.
        let row = 80.0
        #expect(ride.whaleWidth(at: 0, row: row, world: 30) == row)
        let flight = ride.board
        #expect(ride.whaleWidth(at: flight + ride.fly, row: row, world: 30) == 30)
        #expect(ride.whaleWidth(at: ride.board + ride.fly + 0.2, row: row, world: 55) == 55)
        // Over the whole flight she never changes faster than the world does: at a fixed world width the
        // only change is the hand-over from the row's scale, in the first fifth.
        var last = ride.whaleWidth(at: flight + ride.fly * 0.2, row: row, world: 30)
        var t = flight + ride.fly * 0.2
        while t < flight + ride.fly {
            t += 0.05
            let now = ride.whaleWidth(at: t, row: row, world: 30)
            #expect(now == last)
            last = now
        }
        #expect(abs(VoyageRide.islandShare - 1.0 / 3.0) < 0.05)
    }

    @Test func everyTripIsOneRide() {
        // From the row: she waits moored and they hop aboard.
        let row = VoyageRide.trip(from: .home, to: .koke, atMap: true, focusOpen: false, reduceMotion: false)
        #expect(row?.fromRow == true && (row?.board ?? 0) > 0)
        // A tap on a far island or the place control from anywhere else: the same ride, with no boarding.
        let near = VoyageRide.trip(from: .home, to: .koke, atMap: false, focusOpen: false, reduceMotion: false)
        #expect(near?.fromRow == false && near?.board == 0)
        #expect(near?.fly == row?.fly && near?.moor == row?.moor)
        let back = VoyageRide.trip(from: .koke, to: .home, atMap: false, focusOpen: false, reduceMotion: false)
        #expect(back != nil && back?.toTheRight == false)
        // Focus open, or no motion: no boarding either; no trip to where the camera already is.
        #expect(VoyageRide.trip(from: .home, to: .koke, atMap: true, focusOpen: true, reduceMotion: false)?.fromRow == false)
        #expect(VoyageRide.trip(from: .home, to: .koke, atMap: true, focusOpen: false, reduceMotion: true)?.reduced == true)
        #expect(VoyageRide.trip(from: .koke, to: .koke, atMap: false, focusOpen: false, reduceMotion: false) == nil)
        // She fades in when she did not lift off a mooring.
        #expect((near?.whaleOpacity(at: (near?.duration ?? 0) * 0 + 0.001) ?? 1) < 1)
    }

    @Test func theFocusUIStaysHiddenForTheWholeRide() {
        #expect(!VoyageRide.hidesFocusUI(nil))
        for t in stride(from: 0.0, through: ride.duration, by: 0.25) {
            #expect(VoyageRide.hidesFocusUI(ride), "the plaque stays away at \(t) s")
        }
        // The ride is over once the passengers are off: their last hop ends with the moor beat.
        let end = ride.beat(at: ride.duration - 0.001)
        #expect(end.beat == .moor && end.progress > 0.99)
        #expect(VoyageRide.hopProgress(index: 1, count: 2, beatProgress: 1) == 1)
    }

    @Test func theRidesAreStillThreeToFiveSecondsWithTheLongerBoarding() {
        #expect(ride.board >= 1.2)
        #expect((3.0 ... 5.0).contains(ride.duration))
    }

    @Test func theMooringPostStandsOnTheRimAndTheLineIsTiedToIt() {
        let rope = GezginData.Rope.standard
        #expect(rope.tieY < rope.postY && rope.tieY > rope.postY - rope.postHeight)
        #expect(rope.thickness >= 0.015)
        // The line is tied above her bow, to the post's neck, never to a point in the air.
        #expect(rope.tieY < rope.bowY)
    }

    // MARK: - Row 2e: her place at every island

    @Test func everyMainIslandHasAMooringWithItsPostOnTheRim() throws {
        let data = try #require(GezginData.shipped)
        for island in [IslandID.koke, .caglayan] {
            let berth = try #require(Gezgin.berth(at: island, data: data, home: nil), "\(island) has a berth")
            // The post stands on the island's side of her, level with or above her feet, and the line slopes down to her bow.
            #expect(berth.post.x < berth.feet.x)
            #expect(berth.tie.y <= berth.bow.y + 1e-9)
            #expect(berth.slope < 50, "\(island): the line is a slack rope, not a strap down a cliff (\(berth.slope) degrees)")
            #expect(!berth.landing.isEmpty, "\(island): the passengers land on the island")
            for spot in berth.landing { #expect(spot.x < berth.post.x + berth.width) }
        }
        #expect(Gezgin.berth(at: .home, data: data, home: HomePlate.shipped) != nil)
    }

    @Test func anIslandWithoutAMooringHasHerHoverBeside() throws {
        let data = try #require(GezginData.shipped)
        #expect(Gezgin.berth(at: IslandID("revontuli"), data: data, home: nil) == nil)
        let end = ride.whale(at: ride.duration - 0.001, start: start, berth: nil)
        let hover = VoyageRide.hover(toTheRight: true)
        #expect(abs(end.x - hover.x) < 0.01 && abs(end.y - hover.y) < 0.01)
        // With a berth she glides to it, stays whole and has turned to face the island.
        let berth = VoyageRide.Spot(x: 0.6, y: 0.5, width: 0.3)
        let at = ride.whale(at: ride.duration - 0.001, start: start, berth: berth)
        #expect(abs(at.x - 0.6) < 0.01 && abs(at.y - 0.5) < 0.01)
        #expect(ride.whaleOpacity(at: ride.duration - 0.01, berthed: true) == 1)
        #expect(ride.whaleOpacity(at: ride.duration - 0.01, berthed: false) < 1)
        #expect(ride.facing(at: ride.duration - 0.001, berthed: true) == 1)
        #expect(ride.facing(at: ride.board + 1, berthed: true) == -1)
    }

    @Test func theSlackLineHangsBelowTheChordAndNeverRunsPlumb() {
        let tie = WorldPoint(x: 0, y: 0), bow = WorldPoint(x: 40, y: 10)
        let control = GezginData.Rope.control(tie: tie, bow: bow, sag: 0.15)
        #expect(control.y > 5)
        #expect(GezginData.Rope.slope(tie: tie, bow: bow) < 20)
        #expect(GezginData.Rope.slope(tie: tie, bow: WorldPoint(x: 0, y: 40)) > 89)
    }

    @Test func theRowAndTheSceneNeverShowTheSameIslandTogether() {
        let row = VoyageRide(from: .home, to: .koke, data: .fallback)
        for t in stride(from: 0.0, through: row.duration, by: 0.05) {
            let shown = row.rowOpacity(at: t) * row.sceneIslandOpacity(at: t)
            #expect(shown == 0, "no ghost at \(t) s")
        }
        #expect(row.sceneIslandOpacity(at: row.duration) == 1)
        let near = VoyageRide(from: .home, to: .koke, data: .fallback, fromRow: false)
        #expect(near.sceneIslandOpacity(at: 0.5) == 1)
    }

    @Test func theFocusUIStaysHiddenOnTheWayBackToo() {
        let back = VoyageRide(from: .koke, to: .home, data: .fallback)
        for t in stride(from: 0.0, through: back.duration + 0.5, by: 0.25) {
            #expect(VoyageRide.hidesFocusUI(back), "hidden at \(t) s")
        }
        #expect(!VoyageRide.hidesFocusUI(nil), "it returns when the ride is over and the passengers are off")
    }

    @Test func theRopeIsVisiblySlackAndNoTwoHomesShowAtOnce() {
        // The midpoint of the quadratic line drops 0.5 * sag of the chord below it: at least a tenth, obvious at device size.
        let rope = GezginData.Rope.standard
        #expect(0.5 * rope.sag >= 0.12)
        let tie = WorldPoint(x: 0, y: 0), bow = WorldPoint(x: 40, y: 10)
        let c = GezginData.Rope.control(tie: tie, bow: bow, sag: rope.sag)
        let midY = 0.25 * tie.y + 0.5 * c.y + 0.25 * bow.y
        let chord = (40.0 * 40 + 10 * 10).squareRoot()
        #expect(midY - 5 >= 0.10 * chord)
        // The row and the scene's Home are never both visible: the row is gone before the scene's islands start.
        let row = VoyageRide(from: .home, to: .koke, data: .fallback)
        for t in stride(from: 0.0, through: row.duration, by: 1.0 / 30) {
            let both = row.rowOpacity(at: t) > 0.05 && row.sceneIslandOpacity(at: t) > 0.05
            #expect(!both, "Home shows once at \(t) s")
            #expect(row.rowOpacity(at: t) + row.sceneIslandOpacity(at: t) <= 1.0 + 1e-9)
        }
    }

    @Test func sheAndTheBarNeverJumpAcrossTheHandovers() {
        // Her spot moves by little per 1/30 s through the whole ride, the board-to-fly and fly-to-moor handovers included.
        let berth = VoyageRide.Spot(x: 0.62, y: 0.55, width: 0.3)
        var last = ride.whale(at: 0, start: start, berth: berth)
        for t in stride(from: 1.0 / 30, through: ride.duration, by: 1.0 / 30) {
            let now = ride.whale(at: t, start: start, berth: berth)
            #expect(abs(now.x - last.x) < 0.04 && abs(now.y - last.y) < 0.04 && abs(now.width - last.width) < 0.04, "no jump at \(t) s")
            last = now
        }
        // The row's bar goes with the tap.
        #expect(ride.barOpacity(at: 0) == 1)
        #expect(ride.barOpacity(at: VoyageRide.barSeconds) == 0)
        #expect(ride.barOpacity(at: 1.0) == 0)
    }
}
