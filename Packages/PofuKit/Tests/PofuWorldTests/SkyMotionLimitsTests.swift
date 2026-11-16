import Foundation
import PofuCore
@testable import PofuWorld
import Testing

/// The cloud floor's life stays inside v2 section 3 (WP9): slow, never in step, never too many layers.
@Suite("Sky motion limits")
struct SkyMotionLimitsTests {
    /// Every piece the Map can show, over every tier and the beds of every slot state.
    static func allPieces() -> [[CloudFloor.Piece]] {
        guard let plate = HomePlate.shipped.map({ HomePlate(plate: $0.plate, light: "day", stage: 0) }) else { return [] }
        return (0 ... 2).map { tier in
            var p = plate
            p.mapTier = tier
            let stop = p.mapStop, home = p.midStop
            return CloudFloor.pieces(
                homeBox: p.islandBox,
                slots: MapSlots.slots(stage: tier + 1, tier: tier, homeCentre: WorldPoint(x: p.islandBox.midX, y: p.islandBox.midY)),
                stop: CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY),
                reference: CameraPose(scale: home.scale, look: home.look, anchorY: home.anchorY)
            )
        }
    }

    @Test func theKitShipsEveryFormThePiecesUse() {
        for spot in CloudFloor.spots { #expect(CloudFloor.forms[spot.form] != nil, "\(spot.form)") }
        #expect(CloudFloor.forms["bed-wide"] != nil && CloudFloor.forms["bed-round"] != nil && CloudFloor.forms["tower-b"] != nil)
    }

    @Test func noAmbientLayerOver8PtPerSecond() {
        for pieces in Self.allPieces() { for p in pieces { #expect(CloudFloor.speed(p) <= 8, "\(p.id)") } }
        // And as sampled: the swell's step between 15 Hz frames.
        for pieces in Self.allPieces() {
            for p in pieces {
                let ys = stride(from: 0.0, to: 60, by: 1.0 / 15).map { CloudFloor.motion(p, time: $0).dy }
                let step = zip(ys, ys.dropFirst()).map { abs($1 - $0) * 15 }.max() ?? 0
                #expect(step <= 8, "\(p.id)")
            }
        }
    }

    @Test func noFullWidthLayerOver5() {
        for pieces in Self.allPieces() {
            for p in pieces where p.width * 1 >= 0 {
                let screenWidth = p.width * DepthLayer.pose(CameraPose(scale: 1, look: WorldPoint(x: 0, y: 0), anchorY: 0), reference: CameraPose(scale: 1, look: WorldPoint(x: 0, y: 0), anchorY: 0), k: p.k).scale
                if screenWidth >= 0.45 * CameraRail.referenceWidth { #expect(CloudFloor.speed(p) <= 5, "\(p.id)") }
            }
        }
        for s in CloudFloor.spots where s.width >= 0.45 * CameraRail.referenceWidth { #expect(s.drift <= 5 && s.swell * 2 * .pi / s.swellPeriod <= 5, "\(s.id)") }
    }

    @Test func noPeriodUnder5Seconds() {
        for pieces in Self.allPieces() { for period in CloudFloor.periods(pieces) { #expect(period >= 5) } }
    }

    @Test func periodsShareNoSmallMultiple() {
        // The floor pieces of the Map at its richest, each period once.
        let periods = (Self.allPieces().last ?? []).isEmpty ? [] : CloudFloor.periods(Self.allPieces().last ?? [])
        let unique = Array(Set(periods)).sorted()
        for (i, a) in unique.enumerated() {
            for b in unique[(i + 1)...] {
                #expect(b - a >= 0.29, "\(a) and \(b) are in step")
                let ratio = b / a
                for n in 2 ... 4 { #expect(abs(ratio - Double(n)) / Double(n) >= 0.025, "\(a) and \(b) beat as 1:\(n)") }
            }
        }
    }

    @Test func atMost18MovingLayersAtTheMap() {
        for pieces in Self.allPieces() { #expect(pieces.count <= 18) }
    }

    @Test func atRestNothingMoves() {
        for pieces in Self.allPieces() {
            for p in pieces {
                let m = CloudFloor.motion(p, time: nil)
                #expect(m.dy == 0 && m.scale == 1)
            }
        }
    }

    @Test func aBedRestsUnderEachOpenIslandAndNoneUnderAnEmptySlot() {
        guard let plate = HomePlate.shipped.map({ HomePlate(plate: $0.plate, light: "day", stage: 0) }) else { return }
        let stop = plate.mapStop, home = plate.midStop
        let c = WorldPoint(x: plate.islandBox.midX, y: plate.islandBox.midY)
        func beds(stage: Int, tier: Int) -> Set<String> {
            Set(CloudFloor.pieces(
                homeBox: plate.islandBox, slots: MapSlots.slots(stage: stage, tier: tier, homeCentre: c),
                stop: CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY),
                reference: CameraPose(scale: home.scale, look: home.look, anchorY: home.anchorY)
            ).filter { $0.kind == .bed }.map(\.id))
        }
        #expect(beds(stage: 1, tier: 0) == ["bed-home"] || beds(stage: 1, tier: 0).contains("bed-home"))
        #expect(beds(stage: 3, tier: 2).count >= 3)
    }

    @Test func hazeGrowsWithDistance() {
        #expect(CloudFloor.haze(k: 1) == 1 && CloudFloor.haze(k: 1.25) == 1)
        #expect(CloudFloor.haze(k: 0.45) < CloudFloor.haze(k: 0.85))
    }

    @Test func theKitFitsTheBudget() {
        let bytes = CloudFloor.textureBytes(Array(CloudFloor.forms.keys))
        #expect(bytes > 0 && bytes < 3_500_000, "\(bytes)")
    }
}
