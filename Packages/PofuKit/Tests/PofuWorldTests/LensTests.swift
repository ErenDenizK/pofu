import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Depth lens")
struct LensTests {
    @Test func insideTheSlabEverythingIsSharp() {
        let lens = Lens(focus: 10, slab: 8, range: 50)
        #expect(lens.blurLevel(depth: 10) == 0)
        #expect(lens.blurLevel(depth: 18) == 0)
        #expect(lens.blurLevel(depth: 2) == 0)
    }

    @Test func blurGrowsLinearlyWithDistanceFromThePlane() {
        let lens = Lens(focus: 0, slab: 10, range: 50)
        #expect(abs(lens.blurLevel(depth: 35) - 0.5) < 1e-12)
        #expect(abs(lens.blurLevel(depth: 60) - 1.0) < 1e-12)
    }

    @Test func inFrontAndBehindBlurAlike() {
        let lens = Lens(focus: 20, slab: 6, range: 40)
        for distance in stride(from: 0.0, through: 120, by: 7.5) {
            #expect(lens.blurLevel(depth: 20 + distance) == lens.blurLevel(depth: 20 - distance))
        }
    }

    @Test func blurIsCappedAtDeep() {
        let lens = Lens(focus: 0, slab: 0, range: 10)
        #expect(lens.blurLevel(depth: 1000) == 2)
        #expect(lens.blurLevel(depth: -1000) == 2)
    }

    @Test func theMapKeepsEverythingSharp() {
        for depth in stride(from: -300.0, through: 300, by: 50) {
            #expect(Lens.map.blurLevel(depth: depth) == 0)
            #expect(Lens.rail(z: 0).blurLevel(depth: depth) == 0)
        }
    }

    @Test func homeFocusesOnPofuAndSoftensTheBackOfTheLawn() {
        let pofu = IslandLayout.depth(ofY: IslandLayout.pofu.y)
        #expect(Lens.home.blurLevel(depth: pofu) == 0)
        let bands = IslandLayout.plateBands.map { Lens.home.blurLevel(depth: $0.depth) }
        // Back lawn deeper than the middle lawn, which is softer than the
        // front lawn Pofu sits on.
        #expect(bands[0] > bands[1])
        #expect(bands[1] > bands[2])
        #expect(bands[0] > 1)
    }

    @Test func theIslandLensIsSubtle() {
        for band in IslandLayout.plateBands {
            #expect(Lens.island.blurLevel(depth: band.depth) <= 0.35)
        }
    }

    @Test func aStationFocusKeepsItsRowSharpAndSoftensPofu() {
        guard let teaStall = IslandLayout.stationAnchors[.teaStall] else {
            Issue.record("no çay ocağı slot")
            return
        }
        let lens = Lens.station(depth: IslandLayout.depth(ofY: teaStall.y))
        #expect(lens.blurLevel(depth: IslandLayout.depth(ofY: teaStall.y)) == 0)
        let pofu = lens.blurLevel(depth: IslandLayout.depth(ofY: IslandLayout.pofu.y))
        #expect(pofu > 0.1 && pofu < 0.6)
    }

    @Test func theRailLensInterpolatesBetweenFramings() {
        #expect(Lens.rail(z: 1) == Lens.island)
        #expect(Lens.rail(z: 2) == Lens.home)
        let mid = Lens.rail(z: 1.5)
        #expect(abs(mid.focus - (Lens.island.focus + Lens.home.focus) / 2) < 1e-12)
        // Past the ends it holds.
        #expect(Lens.rail(z: 2.3) == Lens.home)
        #expect(Lens.rail(z: -0.3) == Lens.map)
    }
}

@Suite("Depth weights")
struct DepthWeightsTests {
    @Test func sharpSoftAndDeepAtTheBakedLevels() {
        #expect(DepthWeights(level: 0) == DepthWeights.exact(sharp: 1, soft: 0, deep: 0))
        #expect(DepthWeights(level: 1) == DepthWeights.exact(sharp: 0, soft: 1, deep: 0))
        #expect(DepthWeights(level: 2) == DepthWeights.exact(sharp: 0, soft: 0, deep: 1))
    }

    @Test func theLowerLayerIsFullyInEarlySoEdgesNeverThin() {
        let quarter = DepthWeights(level: 0.25)
        #expect(quarter.soft == 1)
        #expect(abs(quarter.sharp - 0.75) < 1e-12)
        let past = DepthWeights(level: 1.25)
        #expect(past.deep == 1)
        #expect(abs(past.soft - 0.75) < 1e-12)
    }

    @Test func weightsAreContinuous() {
        var previous = DepthWeights(level: 0)
        for step in 1...400 {
            let weights = DepthWeights(level: Double(step) / 200)
            #expect(abs(weights.sharp - previous.sharp) < 0.03)
            #expect(abs(weights.soft - previous.soft) < 0.03)
            #expect(abs(weights.deep - previous.deep) < 0.03)
            previous = weights
        }
    }

    @Test func outOfRangeLevelsClamp() {
        #expect(DepthWeights(level: -1) == DepthWeights(level: 0))
        #expect(DepthWeights(level: 9) == DepthWeights(level: 2))
        #expect(DepthWeights(level: .nan) == DepthWeights(level: 0))
    }
}

@Suite("World art and layout")
struct WorldArtTests {
    @Test func everyPlacedSpriteWasBaked() {
        var names = IslandLayout.plateBands.map(\.art)
        names += IslandLayout.residents.map(\.art)
        names += IslandLayout.isles.map(\.art)
        names += IslandLayout.islandCast.map(\.art)
        names += SimitPose.allCases.map(\.art)
        names += GoatPose.allCases.map(\.art)
        names += IslandDressing.pieces.filter { $0.kind.family == .meadow }.map(\.art)
        names += HomeFixtures.doors.map(\.art)
        names += (1...HomeFixtures.hiveLevels).compactMap { HomeFixtures.hiveArt(level: $0) }
        names += IslandLayout.harborProps.map { $0.piece.art }
        names += IslandLayout.generatedLevels.flatMap { station, levels in
            (1...levels).compactMap { IslandLayout.stationArt(station, level: $0)?.name }
        }
        names.append("pofu")
        for station in IslandLayout.stationAnchors.keys {
            if let art = IslandLayout.stationArt(station, level: 1) {
                names.append(art.name)
            }
        }
        for name in names {
            #expect(WorldArt.sprite(name) != nil, "missing \(name)")
        }
    }

    @Test func blurredVariantsCoverTheSharpImage() {
        for name in WorldArt.names {
            guard let sprite = WorldArt.sprite(name), let sharp = sprite.sharp else { continue }
            // Plate bands are cut per variant; whole sprites pad outward.
            if name.contains("-band") { continue }
            #expect(sprite.soft.minX <= sharp.minX && sprite.soft.maxX >= sharp.maxX, "\(name)")
            #expect(sprite.deep.minX <= sprite.soft.minX && sprite.deep.maxY >= sprite.soft.maxY, "\(name)")
        }
    }

    @Test func homeSlotsSitOnTheLawn() {
        for (station, anchor) in IslandLayout.stationAnchors {
            let x = anchor.x / IslandLayout.lawnRadiusX
            let y = anchor.y / IslandLayout.lawnRadiusY
            #expect(x * x + y * y < 1, "\(station) is off the lawn")
        }
    }

    @Test func aStationFocusCentresTheStationAboveTheSheet() {
        guard let pose = IslandLayout.stationFocusPose(.teaStall, width: 402, height: 874, safeTop: 62) else {
            Issue.record("no pose")
            return
        }
        #expect(pose.scale <= 1.7 + 1e-9)
        let top = 62.0 + 100
        let bottom = 874.0 * 0.58
        #expect(abs(pose.anchorY - ((top + bottom) / 2 + 8)) < 1e-9)
    }

    @Test func samplesReadTheStandardCatalog() {
        let world = IslandSamples.dayThree()
        #expect(world.homeStage == 3)
        let open = world.stations.filter { $0.island == .home && $0.isOpen }.map(\.id)
        #expect(Set(open) == [.garden, .teaStall, .pond])
    }
}

extension DepthWeights {
    static func exact(sharp: Double, soft: Double, deep: Double) -> DepthWeights {
        var weights = DepthWeights(level: 0)
        weights.sharp = sharp
        weights.soft = soft
        weights.deep = deep
        return weights
    }
}
