import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Home props on the plate (WP5)")
struct HomePropsTests {
    private func plate() throws -> PlateIsland {
        try #require(HomePlate.shipped, "the package ships Plates/plate-home.json").plate
    }

    private func home(stage: Int) throws -> HomePlate {
        HomePlate(plate: try plate(), light: "day", stage: stage)
    }

    /// The painted feet that stand on the front lip, plate pts (`tools/proof/round3.py` `FEET`): the water wheel's
    /// legs at every level, the mailbox at level 10 (stage 0).
    private func feet(stage: Int) -> [ClosedRange<Double>] {
        stage == 0 ? [466...597, 268...335] : [466...597]
    }

    @Test func everyStageHasThreePropSlots() throws {
        let island = try plate()
        #expect(Set(island.props.map(\.id)) == ["jar", "pots", "lantern"])
        for prop in island.props {
            #expect(prop.slots.count == island.stages, "\(prop.id) has a slot at every stage")
            for stage in 0..<island.stages {
                let slot = try #require(prop.slot(stage: stage))
                #expect(slot.x > 0 && slot.x < island.plateSize.width && slot.y > 0 && slot.y < island.plateSize.height)
            }
        }
    }

    @Test func propSlotsKeep12PtFromPaintedFeetAtEveryLevel() throws {
        let island = try plate()
        for stage in 0..<island.stages {
            for prop in island.props {
                let slot = try #require(prop.slot(stage: stage))
                let half = prop.span(stage: stage) / 2
                // Only a prop that stands on the lip, level with the painted feet, can stand on one.
                guard slot.y > 940 else { continue }
                for foot in feet(stage: stage) {
                    let clear = slot.x + half <= foot.lowerBound - 12 + 0.5 || slot.x - half >= foot.upperBound + 12 - 0.5
                    #expect(clear, "\(prop.id) at stage \(stage) stands on a painted foot")
                }
            }
        }
    }

    @Test func propsDoNotOverlapEachOther() throws {
        let island = try plate()
        for stage in 0..<island.stages {
            let spans = try island.props.map { prop -> (x: ClosedRange<Double>, y: Double) in
                let slot = try #require(prop.slot(stage: stage))
                let half = prop.span(stage: stage) / 2
                return ((slot.x - half)...(slot.x + half), slot.y)
            }
            for i in spans.indices {
                for j in spans.indices where j > i {
                    // Two props overlap when they share their width and stand at the same depth.
                    let level = abs(spans[i].y - spans[j].y) < 20
                    #expect(!(level && spans[i].x.overlaps(spans[j].x)), "stage \(stage): props \(i) and \(j) overlap")
                }
            }
        }
    }

    @Test func plateHomeHasTappableJarPotsAndLantern() throws {
        let h = try home(stage: 4)
        let world = IslandSamples.world(
            clock: nil, tendedDays: 60, levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5],
            jar: .zero, islands: [.home], islandLevel: 6
        )
        let targets = WorldHitTest.plateTargets(h, stations: world.stations, z: 2)
        for prop in HomeSlots.Prop.allCases {
            let target = try #require(targets.first { $0.kind == .prop(prop) }, "\(prop) is a target")
            let foot = try #require(h.propSlot(prop))
            #expect(target.worldBox.minX < foot.x && foot.x < target.worldBox.maxX)
            #expect(target.worldBox.maxY == foot.y)
            // Tapping the middle of its art answers with it.
            let pose = CameraRail(stops: h.stops).pose(of: .mid)
            let p = pose.project(WorldPoint(x: target.worldBox.midX, y: target.worldBox.midY), width: CameraRail.referenceWidth)
            let hit = try #require(WorldHitTest.resolve(x: p.x, y: p.y, targets: targets, pose: pose, width: CameraRail.referenceWidth))
            #expect(hit.kind == .prop(prop))
        }
        // Far from the Home framing the Archipelago answers only with islands.
        #expect(!WorldHitTest.plateTargets(h, stations: world.stations, z: 0).contains { if case .prop = $0.kind { true } else { false } })
    }

    @Test func propTargetsAreAtLeast44PtAtMid() throws {
        let h = try home(stage: 0)
        let pose = CameraRail(stops: h.stops).pose(of: .mid)
        for prop in HomeSlots.Prop.allCases {
            let box = try #require(h.propBox(prop))
            let target = HitTarget(kind: .prop(prop), worldBox: box, depth: 0)
            let r = WorldHitTest.screenRect(of: target, pose: pose, width: CameraRail.referenceWidth)
            #expect(r.maxX - r.minX >= 44 - 1e-9 && r.maxY - r.minY >= 44 - 1e-9)
        }
    }

    @Test func noPropStandsBehindAPaintedObject() throws {
        // A bush or a wheel in front of a prop would hide it: at every stage nothing is drawn over a prop.
        for stage in 0..<10 {
            let h = try home(stage: stage)
            for prop in HomeSlots.Prop.allCases {
                let foot = try #require(h.propSlot(prop)), box = try #require(h.propBox(prop))
                let covering = h.occluders(over: foot, box: box).map(\.id)
                #expect(covering.isEmpty, "stage \(stage): \(covering) cover \(prop)")
            }
        }
    }

    @Test func thePropsFitTheTextureBudgetBesideThePlate() throws {
        let island = try plate()
        // Every state of every prop, whether shown or not, ships in the budget too.
        let all = island.props.reduce(0) { $0 + $1.bytes }
        #expect(all > 0)
        // The worst frame holds the jar, the pots' four states and the lantern's two.
        let worst = island.props.reduce(0) { sum, prop in
            let states = max(prop.states.count, 1)
            let shown = prop.id == "jar" ? 1 : states
            return sum + prop.bytes / states * shown
        }
        #expect(worst > 0)
        #expect(PlateMath.budgetOK(island))
    }
}
