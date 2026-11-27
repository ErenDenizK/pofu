import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The cloud wake behind her on the ride (plan row 2d art list): drift only, born at take-off, dead before she
/// is moored, never under Reduce Motion.
struct VoyageWakeTests {
    private let rides = [
        VoyageRide(from: .home, to: .koke, data: .fallback),
        VoyageRide(from: .koke, to: .home, data: .fallback),
        VoyageRide(from: .home, to: .caglayan, data: .fallback, fromRow: false),
    ]

    private func total(_ ride: VoyageRide, at t: Double) -> Double {
        VoyageWake.Piece.allCases.map { VoyageWake.opacity($0, ride: ride, at: t) }.max() ?? 0
    }

    @Test func thereIsNoWakeAtTheRidesEndsOrWhileSheIsMoored() {
        for ride in rides {
            #expect(total(ride, at: 0) == 0)
            #expect(total(ride, at: ride.duration) == 0)
            #expect(total(ride, at: ride.duration + 5) == 0)
            #expect(total(ride, at: ride.board - 0.001) == 0)
            #expect(total(ride, at: ride.board + ride.fly + ride.moor * 0.4) == 0)
            #expect(total(ride, at: ride.duration - 0.01) == 0)
            #expect(!VoyageWake.isVisible(ride: ride, at: 0))
        }
    }

    @Test func itIsBornSoftlyAtTakeOffAndDiesSoftlyBeforeTheMooring() {
        for ride in rides {
            var last = 0.0
            var peak = 0.0
            var t = 0.0
            while t <= ride.duration {
                let now = total(ride, at: t)
                #expect(abs(now - last) < 0.12, "the wake steps from \(last) to \(now) at \(t)")
                last = now; peak = max(peak, now)
                t += 1.0 / 60
            }
            #expect(peak > 0.9)
            // It has started within a hair of lift-off, and it is there at the half way.
            #expect(total(ride, at: ride.board + ride.fly * 0.05) < 0.3)
            #expect(total(ride, at: ride.board + ride.fly * 0.5) > 0.9)
        }
    }

    @Test func theShortClusterMarksTheEndsAndTheLongChainTheCruise() {
        let ride = rides[0]
        let early = ride.board + ride.fly * 0.1
        let mid = ride.board + ride.fly * 0.5
        let late = ride.board + ride.fly * 0.95
        #expect(VoyageWake.opacity(.short, ride: ride, at: early) > VoyageWake.opacity(.long, ride: ride, at: early))
        #expect(VoyageWake.opacity(.long, ride: ride, at: mid) > 0.99)
        #expect(VoyageWake.opacity(.short, ride: ride, at: mid) == 0)
        #expect(VoyageWake.opacity(.short, ride: ride, at: late) > VoyageWake.opacity(.long, ride: ride, at: late))
    }

    @Test func thereIsNoWakeUnderReduceMotion() {
        let ride = VoyageRide(from: .home, to: .koke, data: .fallback, reduceMotion: true)
        var t = 0.0
        while t <= ride.duration + 1 {
            #expect(total(ride, at: t) == 0)
            t += 0.05
        }
    }

    @Test func itStreamsOppositeToHerHeading() {
        let right = VoyageRide(from: .home, to: .koke, data: .fallback)
        let left = VoyageRide(from: .koke, to: .home, data: .fallback)
        let t = right.board + right.fly * 0.5
        #expect(right.toTheRight && !left.toTheRight)
        #expect(VoyageWake.offset(.long, ride: right, at: t).dx < 0)
        #expect(VoyageWake.offset(.long, ride: left, at: left.board + left.fly * 0.5).dx > 0)
    }

    @Test func theCutOutsAreShipped() {
        for piece in VoyageWake.Piece.allCases {
            #expect(piece.share > 0 && piece.aspect > 0.2 && piece.aspect < 0.5)
        }
    }
}
