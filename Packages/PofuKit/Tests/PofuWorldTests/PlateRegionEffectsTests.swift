import Foundation
import Testing
import PofuCore
@testable import PofuWorld

@Suite("Plate region effects (WP13)")
struct PlateRegionEffectsTests {
    private var plate: PlateIsland {
        get throws { try #require(HomePlate.shipped?.plate, "the package ships Plates/plate-home.json") }
    }

    /// Every painted state of Home: each light, each stage it paints.
    private func states() throws -> [HomePlate] {
        let island = try plate
        var out: [HomePlate] = []
        for (light, count) in island.lightStages.sorted(by: { $0.key < $1.key }) {
            for stage in 0..<count where island.plateCrop(light: light, stage: stage) != nil {
                out.append(HomePlate(plate: island, light: light, stage: stage))
            }
        }
        return out
    }

    @Test func homeCarriesItsWater() throws {
        let island = try plate
        #expect(island.water.map(\.id) == ["pond", "pond-small", "pond-look-1", "pond-look-2", "pond-look-3", "pond-look-4", "pond-look-5", "pond-look-5-2"])
        // The pond is painted at stages 0 to 5 and the small one at 6; none past 6 has any. Where the pond's look
        // stands over an erased base (stages 0 to 3 by day) the plate's own pond is not drawn: with the pond unbuilt
        // there is no water, and a built one has its look's outline (`theWaterFollowsThePondsLevel`).
        for state in try states() {
            let count = PlateRegionEffects.water(of: state).count
            let onBase = island.stationLooks(light: state.key, stage: state.stage)["pond"] != nil
            #expect(count == (state.stage <= 6 && !onBase ? 1 : 0), "\(state.light) stage \(state.stage)")
        }
        for body in island.water {
            #expect(body.polygon.count >= 3)
            let box = try #require(body.box)
            #expect(box.minX > 0 && box.maxX < island.plateSize.width && box.minY > 0 && box.maxY < island.plateSize.height)
            let pond = try #require(island.objects.first { $0.id == "pond" })
            // The pond's tap polygon holds the water's centre (they describe the same pond; the small one
            // sits on the lawn where the tap polygon is the big pond's).
            if body.id == "pond" {
                let cx = (box.minX + box.maxX) / 2, cy = (box.minY + box.maxY) / 2
                #expect(pond.polygon.contains { $0.x < cx } && pond.polygon.contains { $0.x > cx })
                #expect(pond.polygon.contains { $0.y < cy } && pond.polygon.contains { $0.y > cy })
            }
            #expect(body.period > 0 && PlateRegionEffects.loop.truncatingRemainder(dividingBy: body.period) == 0)
            #expect(body.reach < body.feather + 5, "the shader's gate stays a few pixels wide")
        }
    }

    @Test func regionsCoverUnder5PercentOfThePixels() throws {
        // At every pond level (0 to 5, past the last look too), the worst of them reported by the test log.
        var worst = 0.0
        for state in try states() {
            for level in 0...6 {
                let share = PlateRegionEffects.coverage(of: state, levels: ["pond": level])
                worst = max(worst, share)
                #expect(share < 0.05, "\(state.light) stage \(state.stage) pond level \(level): \(share)")
            }
        }
        print("worst water coverage at any pond level: \(worst)")
        // On the screen at Home's mid framing (the island 1.15 screens wide on a 402 x 874 pt phone).
        let island = try plate
        let ppp = island.framing.homeWidths * 402 / island.islandBox.width
        for state in try states() {
            for level in 0...6 {
                let area = PlateRegionEffects.water(of: state, levels: ["pond": level]).reduce(0) { $0 + $1.area }
                #expect(area * ppp * ppp / (402 * 874) < 0.05, "\(state.light) stage \(state.stage) pond level \(level)")
            }
        }
    }

    @Test func aPatchStaysInsideTheScreen() throws {
        let body = try #require(try plate.water.first)
        // At mid: the island's top left at a screen point, 0.45 pt per plate pixel.
        let patch = try #require(PlateRegionEffects.patch(of: body, origin: (x: -10, y: 80), pointsPerPixel: 0.45, screen: (402, 874)))
        #expect(patch.minX >= 0 && patch.minY >= 0 && patch.maxX <= 402 && patch.maxY <= 874)
        #expect(patch.minX == patch.minX.rounded() && patch.maxY == patch.maxY.rounded())
        // Closer in, the pond is cut to the screen and the patch is still a part of it.
        let near = try #require(PlateRegionEffects.patch(of: body, origin: (x: -300, y: -1400), pointsPerPixel: 1.8, screen: (402, 874)))
        #expect(near.maxX <= 402 && near.maxY <= 874 && near.width > 0)
        // Off the screen: nothing.
        #expect(PlateRegionEffects.patch(of: body, origin: (x: -3000, y: 0), pointsPerPixel: 1.8, screen: (402, 874)) == nil)
    }

    @Test func pausedOutsideAmbient() {
        let policy = FramePolicy()
        for state in FrameState.allCases {
            let directive = policy.directive(for: state)
            #expect(PlateRegionEffects.runs(under: directive, reduceMotion: false, isStill: false) == (state == .ambient), "\(state)")
        }
        let ambient = policy.directive(for: .ambient)
        #expect(!PlateRegionEffects.runs(under: ambient, reduceMotion: true, isStill: false))
        #expect(!PlateRegionEffects.runs(under: ambient, reduceMotion: false, isStill: true))
        // Low Power Mode and a serious thermal state turn Ambient into Settled.
        let lowPower = policy.directive(for: .ambient, conditions: FrameConditions(lowPower: true))
        #expect(!PlateRegionEffects.runs(under: lowPower, reduceMotion: false, isStill: false))
        let hot = policy.directive(for: .ambient, conditions: FrameConditions(thermal: .serious))
        #expect(!PlateRegionEffects.runs(under: hot, reduceMotion: false, isStill: false))
    }

    @Test func theLoopLeadsIntoItself() {
        #expect(PlateRegionEffects.time(0) == 0)
        #expect(abs(PlateRegionEffects.time(6.0 / 30) - 6.0 / 30) < 1e-9)
        #expect(abs(PlateRegionEffects.time(6.0 + 1.0) - 1.0) < 1e-9)
        // Quantised to the rate: two instants in one frame give one time.
        #expect(PlateRegionEffects.time(2.001) == PlateRegionEffects.time(2.02))
        #expect(PlateRegionEffects.time(2.0) != PlateRegionEffects.time(2.04))
        #expect(PlateRegionEffects.time(.infinity) == 0)
        #expect(PlateRegionEffects.time(-1.0) >= 0)
        #expect(PlateRegionEffects.fallbackHz == 20)
    }

    @Test func theDriftIsAUnitDirection() throws {
        let body = try #require(try plate.water.first)
        let d = body.direction
        #expect(abs(d.x * d.x + d.y * d.y - 1) < 1e-9)
    }

    @Test func theWaterFollowsThePondsLevel() throws {
        let island = try plate
        let looks = try #require(island.stations["pond"])
        let frame = try #require(looks.box)
        for state in try states() where island.stationLooks(light: state.key, stage: state.stage)["pond"] != nil {
            // Unbuilt: the base is grass, so no water.
            #expect(PlateRegionEffects.water(of: state, levels: ["pond": 0]).isEmpty, "\(state.light) \(state.stage) level 0")
            for level in 1...looks.levels {
                let n = try #require(looks.lookLevel(stationLevel: level, light: state.key))
                let bodies = PlateRegionEffects.water(of: state, levels: ["pond": level])
                #expect(!bodies.isEmpty, "\(state.light) \(state.stage) level \(level) has water")
                for body in bodies {
                    #expect(body.look == n && body.station == "pond")
                    // Inside the look's canvas: the outline is fitted to the look's water, not the old pond's.
                    let box = try #require(body.box)
                    #expect(box.minX >= frame.minX && box.maxX <= frame.maxX && box.minY >= frame.minY && box.maxY <= frame.maxY)
                }
            }
        }
        // The levels differ: a bigger pond has a bigger outline.
        let day = try #require(try states().first { $0.key == "day" && island.stationLooks(light: "day", stage: $0.stage)["pond"] != nil })
        let small = PlateRegionEffects.water(of: day, levels: ["pond": 1]).reduce(0) { $0 + $1.area }
        let big = PlateRegionEffects.water(of: day, levels: ["pond": 3]).reduce(0) { $0 + $1.area }
        #expect(small > 0 && big > small)
        // Where the state keeps the painted pond, its own outline stays at every level.
        for state in try states() where island.stationLooks(light: state.key, stage: state.stage)["pond"] == nil && state.stage <= 5 {
            #expect(PlateRegionEffects.water(of: state, levels: ["pond": 3]).map(\.id) == ["pond"])
        }
    }

    @Test func thePatchSamplesTheDrawnLook() throws {
        let island = try plate
        for state in try states() where island.stationLooks(light: state.key, stage: state.stage)["pond"] != nil {
            for level in 1...5 {
                let levels: [StationID: Int] = ["pond": level]
                let compositor = PlateCompositor(plate: state, levels: levels)
                let drawn = compositor.stationsBackToFront.compactMap { compositor.look($0, level: levels[StationID(rawValue: $0)] ?? 0) }
                // The patch draws the base and these looks (`PlateWaterPatch`): the pond's look of the level is one.
                for body in PlateRegionEffects.water(of: state, levels: levels) {
                    #expect(drawn.contains { $0.station == "pond" && $0.look == body.look }, "\(state.key) \(state.stage) level \(level)")
                }
            }
        }
    }
}
