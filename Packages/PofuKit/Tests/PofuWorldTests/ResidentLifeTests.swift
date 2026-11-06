import Foundation
import Testing
import PofuCompanion
import PofuCore
@testable import PofuWorld

@Suite("Residents' life")
struct ResidentLifeTests {
    static let specs = [
        ResidentLife.Spec(id: "mochi", home: WorldPoint(x: 108, y: 29)),
        ResidentLife.Spec(id: "findik", home: WorldPoint(x: 76, y: 20)),
        ResidentLife.Spec(id: "a", home: WorldPoint(x: 0, y: 20)),
        ResidentLife.Spec(id: "b", home: WorldPoint(x: -40, y: 20)),
        ResidentLife.Spec(id: "c", home: WorldPoint(x: 150, y: 10)),
    ]
    static let avoid = [IslandLayout.pofu]

    @Test("the schedule is deterministic for a seed and differs between days")
    func deterministic() throws {
        let walkable = try #require(IslandFootprint.walkable)
        let a = ResidentLife.plans(for: Self.specs, day: 9_000, cycle: 2, walkable: walkable, avoid: Self.avoid)
        let b = ResidentLife.plans(for: Self.specs, day: 9_000, cycle: 2, walkable: walkable, avoid: Self.avoid)
        #expect(a == b)
        let others = (1...6).map { ResidentLife.plans(for: Self.specs, day: 9_000 + $0, cycle: 2, walkable: walkable, avoid: Self.avoid) }
        #expect(others.contains { $0 != a })
    }

    @Test("walk targets lie inside the walkable area, along the whole path")
    func targetsAreWalkable() throws {
        let walkable = try #require(IslandFootprint.walkable)
        var walks = 0
        for day in 0..<40 {
            for cycle in 0..<4 {
                for plan in ResidentLife.plans(for: Self.specs, day: day, cycle: cycle, walkable: walkable, avoid: Self.avoid) {
                    guard case .walk(let target, _, let seconds, _) = plan.activity else { continue }
                    walks += 1
                    #expect(seconds <= 3)
                    #expect(walkable.contains(target))
                    for i in 0...8 {
                        let u = Double(i) / 8
                        let p = WorldPoint(x: plan.spec.home.x + (target.x - plan.spec.home.x) * u, y: plan.spec.home.y + (target.y - plan.spec.home.y) * u)
                        #expect(walkable.contains(p))
                    }
                    #expect(ResidentLife.distance(target, IslandLayout.pofu) >= 20)
                }
            }
        }
        #expect(walks > 20, "residents do walk")
    }

    @Test("never more than two movers at once")
    func moverCap() throws {
        let walkable = try #require(IslandFootprint.walkable)
        for day in 0..<60 {
            let plans = ResidentLife.plans(for: Self.specs, day: day, cycle: day % 5, walkable: walkable, avoid: Self.avoid)
            var t = 0.0
            while t <= ResidentLife.cycleSeconds {
                #expect(ResidentLife.movers(of: plans, at: t) <= ResidentLife.maxMovers)
                t += 0.05
            }
        }
    }

    @Test("every loop starts and ends at rest, and a settled island holds still")
    func restAtTheEnds() throws {
        let walkable = try #require(IslandFootprint.walkable)
        for day in 0..<30 {
            for plan in ResidentLife.plans(for: Self.specs, day: day, cycle: 0, walkable: walkable, avoid: Self.avoid) {
                let start = ResidentLife.step(of: plan, at: 0)
                let end = ResidentLife.step(of: plan, at: ResidentLife.cycleSeconds)
                for s in [start, end] {
                    #expect(s.dx == 0 && s.dy == 0 && s.hop == 0 && s.lean == 0 && s.pose == .rest, "\(plan.spec.id) day \(day)")
                }
                #expect(ResidentLife.step(of: plan, at: 3, isAmbient: false).isRest)
            }
        }
    }

    @Test("a walk eases: slow at the ends, fastest in the middle")
    func easing() {
        let plan = ResidentLife.Plan(
            spec: ResidentLife.Spec(id: "x", home: WorldPoint(x: 0, y: 0)),
            activity: .walk(target: WorldPoint(x: 40, y: 0), start: 1, seconds: 2.6, linger: 0.5),
            glanceAt: 7,
            greetsPofu: false
        )
        let early = ResidentLife.step(of: plan, at: 1.26).dx - ResidentLife.step(of: plan, at: 1).dx
        let middle = ResidentLife.step(of: plan, at: 2.56).dx - ResidentLife.step(of: plan, at: 2.3).dx
        #expect(middle > early * 3)
        #expect(abs(ResidentLife.step(of: plan, at: 3.6).dx - 40) < 0.001)
    }

    @Test("a walk plays step-a, base, step-b, base at 6 fps, and a still island plays none")
    func walkFrames() {
        let plan = ResidentLife.Plan(
            spec: ResidentLife.Spec(id: "x", home: WorldPoint(x: 0, y: 0)),
            activity: .walk(target: WorldPoint(x: 40, y: 0), start: 1, seconds: 2.6, linger: 0.5),
            glanceAt: 7,
            greetsPofu: false
        )
        let frames = (0..<8).map { ResidentLife.step(of: plan, at: 1 + (Double($0) + 0.5) / ResidentLife.walkFPS).pose }
        #expect(frames == [.stepA, .rest, .stepB, .rest, .stepA, .rest, .stepB, .rest])
        // At the far end and at rest, no walk frame.
        #expect(ResidentLife.step(of: plan, at: 4.0).pose == .rest)
        #expect(ResidentLife.step(of: plan, at: 2, isAmbient: false).pose == .rest)
    }

    @Test("the work beat alternates the work-beat frame with the base")
    func workBeatFrames() {
        let plan = ResidentLife.Plan(
            spec: ResidentLife.Spec(id: "x", home: WorldPoint(x: 0, y: 0)),
            activity: .work(start: 1, seconds: 3),
            glanceAt: 7,
            greetsPofu: false
        )
        #expect(ResidentLife.step(of: plan, at: 1.25).pose == .workBeat)
        #expect(ResidentLife.step(of: plan, at: 1.75).pose == .rest)
    }

    @Test("a frame the resident has no art for falls back: work-beat to work, walk to the base")
    func frameFallbacks() throws {
        #expect(ResidentPose.workBeat.fallbacks == [.workBeat, .work])
        let findik = try #require(IslandLayout.resident(.findik))
        if WorldArt.sprite("findik-step-a") == nil { #expect(findik.art(for: .stepA) == findik.art) }
        #expect(ResidentPose.rest.lifePose(.stepA) == .stepA)
        #expect(ResidentPose.sleepy.lifePose(.stepA) == .sleepy)
        #expect(ResidentPose.work.lifePose(.workBeat) == .workBeat)
    }

    @Test("a reaction lasts 1.2 s with a tiny hop")
    func reaction() {
        #expect(ResidentLife.reaction(age: 0.15)?.hop ?? 0 > 0)
        #expect(ResidentLife.reaction(age: 1.19) != nil)
        #expect(ResidentLife.reaction(age: 1.2) == nil)
    }
}

@Suite("Pofu's mood in the world")
struct PofuMoodSourceTests {
    @Test("what just happened wins, then night, visitor, band")
    func order() {
        func mood(_ band: WellbeingBand = .content, night: Bool = false, calm: Bool = false, visitor: Bool = false, _ event: ResidentEvent? = nil) -> PofuMood {
            PofuMoodSource.mood(band: band, isBedtime: night, calmIsFull: calm, visitorPresent: visitor, event: event)
        }
        #expect(mood(night: true, .ceremonyDone) == .proud)
        #expect(mood(.cozy, .visitorArrived) == .happy)
        #expect(mood(night: true, visitor: true) == .sleepy)
        #expect(mood(calm: true) == .relieved)
        #expect(mood(visitor: true) == .curious)
        #expect(mood(.cozy) == .happy)
        #expect(mood(.content) == .calm)
    }

    @Test("a low band is drowsy or a little worried, never a drooping face")
    func lowBand() {
        #expect(PofuMoodSource.mood(band: .curledUp, isBedtime: false, calmIsFull: false, visitorPresent: false) == .sleepy)
        #expect(PofuMoodSource.mood(band: .unwell, isBedtime: false, calmIsFull: false, visitorPresent: false) == .worried)
        for band in WellbeingBand.allCases {
            let mood = PofuMoodSource.mood(band: band, isBedtime: false, calmIsFull: false, visitorPresent: false)
            #expect(mood != .relieved)
        }
    }
}
