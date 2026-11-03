import Foundation
import Testing
@testable import PofuWorld

@Suite("Home objects")
struct HomeObjectsTests {
    @Test func cheekStepsFollowScaleA() {
        let expected: [(Int, CheekStep)] = [
            (-3, .empty), (0, .empty), (1, .round), (7, .round), (8, .full), (19, .full), (20, .huge), (500, .huge),
        ]
        for (seeds, step) in expected {
            #expect(CheekStep(uncollected: seeds) == step, "\(seeds) seeds")
        }
    }

    @Test func cheekEnergyRisesWithTheStep() {
        let energies = CheekStep.allCases.map(\.companionEnergy)
        #expect(energies == energies.sorted())
        #expect(energies.first == 0)
        #expect(energies.last == 1)
        #expect(CheekStep.huge.lowered == .full)
        #expect(CheekStep.empty.lowered == .empty)
    }

    @Test func theHugeLineIsSaidOnceADay() {
        let calendar = Calendar(identifier: .gregorian)
        let morning = Date(timeIntervalSince1970: 1_793_000_000)
        var gate = CheekLineGate()
        #expect(gate.allows(step: .huge, now: morning, calendar: calendar))
        #expect(!gate.allows(step: .full, now: morning, calendar: calendar))
        gate.markSpoken(at: morning)
        #expect(!gate.allows(step: .huge, now: morning.addingTimeInterval(60), calendar: calendar))
        #expect(gate.allows(step: .huge, now: morning.addingTimeInterval(86_400 * 2), calendar: calendar))
    }

    @Test func theJarFillIsMonotonicAndBounded() {
        #expect(SeedJarFill.fraction(seeds: 0) == 0)
        #expect(SeedJarFill.fraction(seeds: 1) == SeedJarFill.minimumVisible)
        #expect(SeedJarFill.fraction(seeds: 60, capacity: 120) == 0.5)
        #expect(SeedJarFill.fraction(seeds: 9_999) == 1)
        #expect(SeedJarFill.fraction(seeds: 10, capacity: 0) == 0)
        let fills = stride(from: 0, through: 200, by: 5).map { SeedJarFill.fraction(seeds: $0) }
        #expect(fills == fills.sorted())
    }

    @Test func theLanternGlowsFromFifteenToAHundredPercent() {
        #expect(CalmLantern.glow(calm: 1.0) == 0.15)
        #expect(CalmLantern.glow(calm: 2.0) == 1)
        #expect(abs(CalmLantern.glow(calm: 1.5) - 0.575) < 1e-9)
        #expect(CalmLantern.glow(calm: 0.4) == 0.15)
        #expect(CalmLantern.glow(calm: 3) == 1)
        #expect(CalmLantern.glow(calm: .nan) == 0.15)
    }

    @Test func potsHaveOneBloomPerSkipAndOneBudPerOpen() {
        let pots = SkipPots(beads: [true, true, false, true])
        #expect(pots.pots.count == 4)
        #expect(pots.pots.map(\.blooms) == [1, 1, 0, 1])
        #expect(pots.pots.map(\.buds) == [0, 0, 1, 0])
        #expect(pots.skips == 3)
        #expect(pots.reaches == 4)
        #expect(!pots.isClustered)
        #expect(SkipPots(beads: []).pots.isEmpty)
    }

    @Test func manyReachesClusterIntoEightPots() {
        let beads = (0..<19).map { $0 % 3 != 0 }
        let pots = SkipPots(beads: beads)
        #expect(pots.pots.count <= SkipPots.maxVisible)
        #expect(pots.isClustered)
        #expect(pots.pots.map(\.reaches).reduce(0, +) == 19)
        #expect(pots.pots.map(\.blooms).reduce(0, +) == beads.filter { $0 }.count)
        let eight = SkipPots(beads: Array(repeating: true, count: 8))
        #expect(eight.pots.count == 8)
        #expect(!eight.isClustered)
    }

    @Test func theCollectBeatPressesThenReleasesTheCheeks() {
        let beat = CheekCollectBeat(from: .huge, timing: HomeTiming())
        #expect(beat.energy(at: 0) == 1)
        #expect(beat.pawsPressed(at: 0.1))
        let mid = beat.energy(at: beat.timing.pawsPress + beat.timing.cheekRelease / 2)
        #expect(abs(mid - 0.5) < 1e-9)
        #expect(beat.energy(at: 5) == 0)
        #expect(!beat.pawsPressed(at: 5))
        #expect(!CheekCollectBeat(from: .empty, timing: HomeTiming()).pawsPressed(at: 0.1))
    }
}

@Suite("Home layout")
struct HomeObjectsLayoutTests {
    @Test func theJarStandsLeftAndTheLanternRightOfPofu() {
        let feet = MomentPoint(x: 200, y: 590)
        let jar = HomeObjectsLayout.jarCenter(feet: feet, screenWidth: 393)
        let lantern = HomeObjectsLayout.lanternCenter(feet: feet, screenWidth: 393)
        #expect(jar.x < feet.x)
        #expect(lantern.x > feet.x)
        #expect(jar.y > 0 && lantern.y > 0)
    }

    @Test func objectsStayOnAScreenEdge() {
        let near = MomentPoint(x: 20, y: 500)
        #expect(HomeObjectsLayout.jarCenter(feet: near, screenWidth: 393).x >= 28)
        let far = MomentPoint(x: 380, y: 500)
        #expect(HomeObjectsLayout.lanternCenter(feet: far, screenWidth: 393).x <= 393 - 30)
    }
}
