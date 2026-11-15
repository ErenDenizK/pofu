import Foundation
import Testing
@testable import PofuWorld

@Suite("Composition rules")
struct CompositionRulesTests {
    let map: WorldMap
    let plate: PlateIsland

    init() throws {
        map = try #require(WorldMap.shipped)
        plate = try #require(PlateIsland.load("home"))
    }

    private func expectAllPass(_ frame: CompositionFrame) {
        for r in CompositionRules.check(frame) {
            #expect(r.passed, "\(frame.name) \(r.rule): \(r.detail)")
        }
    }

    // MARK: Frames that must pass

    @Test(arguments: [1, 2, 3])
    func theTierOneFramePasses(stage: Int) {
        expectAllPass(.map(stage: stage, tier: 1, map: map))
    }

    /// C1 to C6 on the Map the player meets: the real stop (`HomePlate.mapStop`), the painted islands'
    /// boxes, the towers and the far isles and the whale where Home's sky set of each light puts them.
    @Test(arguments: [1, 2, 3])
    func theRealMapStopPasses(stage: Int) throws {
        let home = try #require(HomePlate.shipped)
        for light in ["day", "golden", "night"] {
            let frame = try #require(MapSlots.frame(stage: stage, plate: home, light: light))
            #expect(frame.features.count == 6, "the five far features and the lip in \(light)")
            expectAllPass(frame)
        }
    }

    @Test(arguments: [1, 4, 10])
    func midPasses(level: Int) {
        expectAllPass(.mid(level: level, map: map, plate: plate))
    }

    @Test func nearRestPasses() {
        expectAllPass(.near(scale: map.nearRestScale, map: map, plate: plate))
    }

    @Test func nearAtTheLimitKeepsPofuWhole() {
        let frame = CompositionFrame.near(scale: map.nearLimitScale, map: map, plate: plate)
        #expect(CompositionRules.result("C1", in: frame).passed)
        #expect(CompositionRules.result("C4", in: frame).passed)
        // Pofu is 201 pt wide at the limit (v2 section 1.5).
        #expect(abs(frame.hero.width - 201) <= 2)
    }

    @Test func pofuIs122PtWideAtNearRest() {
        let frame = CompositionFrame.near(scale: map.nearRestScale, map: map, plate: plate)
        #expect(abs(frame.hero.width - 122) <= 1)
    }

    // MARK: One failing case per rule

    @Test func c1FailsWhenHomeSitsHigh() {
        var frame = CompositionFrame.map(stage: 3, tier: 1, map: map)
        shift(&frame, id: "home", dy: -60)
        #expect(!CompositionRules.result("C1", in: frame).passed)
        var mid = CompositionFrame.mid(level: 10, map: map, plate: plate)
        mid.hero = ScreenBox(minX: 0, minY: 100, maxX: 402, maxY: 300)
        #expect(!CompositionRules.result("C1", in: mid).passed)
        var near = CompositionFrame.near(scale: 4.5, map: map, plate: plate)
        near.feet = (201, 400)
        #expect(!CompositionRules.result("C1", in: near).passed)
    }

    @Test func c2FailsWhenARunIsTooTall() {
        var frame = CompositionFrame.map(stage: 3, tier: 1, map: map)
        frame.features.removeAll { $0.id == "isle-top" }
        let r = CompositionRules.result("C2", in: frame)
        #expect(!r.passed, "without the far isle the sky above Çağlayan is 0.207 of the height: \(r.detail)")
    }

    @Test func c2LetsTheHorizonRunReachPoint21() {
        // One empty run of 0.20 that holds the horizon passes; the same run elsewhere does not.
        let h = 874.0
        let boxes = [ScreenBox(minX: 0, minY: 0, maxX: 402, maxY: 463 - 0.10 * h), ScreenBox(minX: 0, minY: 463 + 0.10 * h, maxX: 402, maxY: h)]
        #expect(CompositionRules.tallestRun(boxes, height: h, horizon: 463, allow: 0.03) <= 0.18 + 0.002)
        #expect(CompositionRules.tallestRun(boxes, height: h) > 0.19)
    }

    @Test func c3FailsWhenAThirdIsEmpty() {
        var frame = CompositionFrame.map(stage: 3, tier: 1, map: map)
        frame.subjects.removeAll { $0.id == "koke" || $0.id == "caglayan" }
        frame.features.removeAll()
        let r = CompositionRules.result("C3", in: frame)
        #expect(!r.passed)
        #expect(r.detail.contains("top"))
    }

    @Test func c4FailsOnACutIslandAndOnATappableInTheCorner() {
        var frame = CompositionFrame.map(stage: 3, tier: 1, map: map)
        shift(&frame, id: "caglayan", dx: 60)
        #expect(!CompositionRules.result("C4", in: frame).passed, "Çağlayan cut by the right edge")
        var corner = CompositionFrame.map(stage: 3, tier: 1, map: map)
        shift(&corner, id: "home", dx: 150, dy: 60)
        let r = CompositionRules.result("C4", in: corner)
        #expect(!r.passed)
        #expect(r.detail.contains("corner keep-out") || r.detail.contains("safe band"))
    }

    @Test func c5FailsOnATinyIsland() {
        var frame = CompositionFrame.map(stage: 3, tier: 1, map: map)
        if let i = frame.subjects.firstIndex(where: { $0.id == "koke" }) {
            frame.subjects[i].island = ScreenBox(minX: 20, minY: 224, maxX: 100, maxY: 300)
        }
        #expect(!CompositionRules.result("C5", in: frame).passed)
    }

    @Test func c6FailsWhenAFeatureTouchesASlot() {
        var frame = CompositionFrame.map(stage: 3, tier: 1, map: map)
        frame.features.append(WorldMap.Piece(id: "whale", box: ScreenBox(minX: 300, minY: 300, maxX: 380, maxY: 340)))
        let r = CompositionRules.result("C6", in: frame)
        #expect(!r.passed)
        #expect(r.detail.contains("caglayan"))
    }

    // MARK: Helpers

    private func shift(_ frame: inout CompositionFrame, id: String, dx: Double = 0, dy: Double = 0) {
        guard let i = frame.subjects.firstIndex(where: { $0.id == id }) else { return }
        func moved(_ b: ScreenBox) -> ScreenBox { ScreenBox(minX: b.minX + dx, minY: b.minY + dy, maxX: b.maxX + dx, maxY: b.maxY + dy) }
        frame.subjects[i].box = moved(frame.subjects[i].box)
        frame.subjects[i].island = frame.subjects[i].island.map(moved)
        frame.subjects[i].art = frame.subjects[i].art.map(moved)
    }
}
