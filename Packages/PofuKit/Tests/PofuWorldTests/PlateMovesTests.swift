import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Plate moves")
struct PlateMovesTests {
    static var plate: PlateIsland { HomePlate.shipped!.plate }
    static var spots: [String: [PlatePoint]] { plate.spots }

    @Test("every character's first spot is its painted one, and each has two or more")
    func painted() {
        let plate = Self.plate
        for id in PlateMoves.ids {
            let list = plate.spots[id] ?? []
            #expect(list.count >= 2 && list.count <= 4, "\(id)")
            #expect(list.first == plate.characters[id], "\(id)")
        }
    }

    @Test("every spot is on the lawn and every straight line between two spots stays on it")
    func lawn() {
        let plate = Self.plate
        for (id, list) in plate.spots {
            for a in list {
                #expect(PlateMath.contains(plate.walkable, a), "\(id) \(a)")
                for b in list {
                    for t in stride(from: 0.0, through: 1.0, by: 0.05) {
                        let p = PlatePoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
                        #expect(PlateMath.contains(plate.walkable, p), "\(id) \(a) to \(b) at \(t)")
                    }
                }
            }
        }
    }

    /// Pofu may stand behind something low, never behind something taller than himself.
    @Test("no spot is behind a taller occluder or look, at any stage, light or level")
    func nobodyHidden() {
        let plate = Self.plate
        var checked = 0
        for light in plate.lights {
            for stage in 0..<(plate.lightStages[light] ?? 0) {
                let state = HomePlate(plate: plate, light: light, stage: stage)
                for level in [1, 2, 3, 5, 8, 10] {
                    let levels: [StationID: Int] = Dictionary(uniqueKeysWithValues: plate.objects.compactMap(\.station).map { ($0, level) })
                    let compositor = PlateCompositor(plate: state, levels: levels)
                    for (id, list) in plate.spots {
                        for spot in list {
                            let feet = state.world(spot)
                            let box = id == "pofu"
                                ? state.pofuBox(at: feet)
                                : state.residentBox(art: WorldArt.sprite(id)?.sharp ?? IslandLayout.residentHitBox, at: feet, id: ResidentID(rawValue: id))
                            for object in state.occluders(over: feet, box: box) {
                                let h = state.occluderBox(object).height
                                #expect(h <= box.height, "\(id) \(spot) behind \(object.id) at \(light) \(stage)")
                            }
                            for look in compositor.looks(over: feet, box: box) {
                                #expect(look.box.height <= box.height, "\(id) \(spot) behind the look of \(look.station) at \(light) \(stage) level \(level)")
                            }
                            checked += 1
                        }
                    }
                }
            }
        }
        #expect(checked > 100)
    }

    /// The check bites: Pofu just behind the tea stall's foot is covered by it.
    @Test("the occluder check finds Pofu behind the stall")
    func control() {
        var found = 0
        for stage in 0..<10 {
            let state = HomePlate(plate: Self.plate, light: "day", stage: stage)
            let feet = state.world(PlatePoint(x: 700, y: 800))
            let box = state.pofuBox(at: feet)
            let levels: [StationID: Int] = ["teaStall": 5]
            found += state.occluders(over: feet, box: box).filter { state.occluderBox($0).height > box.height }.count
            found += PlateCompositor(plate: state, levels: levels).looks(over: feet, box: box).filter { $0.box.height > box.height }.count
        }
        #expect(found > 0)
    }

    static let present = ["pofu", "mochi", "findik"]

    /// Every move of a visit, by playing the state at 20 Hz.
    static func moves(day: Int, seconds: Double, allowed: Bool = true) -> [PlateMoves.Move] {
        var state = PlateMoves.State()
        var seen: [Int: PlateMoves.Move] = [:]
        var t = 0.0
        while t < seconds {
            state.advance(day: day, elapsed: t, spots: spots, present: present, allowed: allowed)
            if let move = state.active { seen[move.slot] = move }
            t += 0.05
        }
        return seen.values.sorted { $0.slot < $1.slot }
    }

    @Test("two to four hops, one move at a time, at most two a minute, deterministic")
    func rhythm() {
        for day in [9_000, 9_001, 9_002] {
            let moves = Self.moves(day: day, seconds: 900)
            #expect(moves.count >= 12)
            #expect(moves.count <= 30)
            for move in moves {
                #expect((2...4).contains(move.hops))
                #expect(move.duration < PlateMoves.slotSeconds - PlateMoves.startRange.upperBound)
            }
            for (a, b) in zip(moves, moves.dropFirst()) { #expect(b.start >= a.start + a.duration) }
            #expect(moves == Self.moves(day: day, seconds: 900))
        }
        #expect(Self.moves(day: 9_000, seconds: 900) != Self.moves(day: 9_005, seconds: 900))
    }

    @Test("everyone is seen at two or more spots, and rests on a spot between moves")
    func spotsVisited() {
        var state = PlateMoves.State()
        var seen: [String: Set<String>] = [:]
        var t = 0.0
        while t < 600 {
            let frame = state.advance(day: 9_000, elapsed: t, spots: Self.spots, present: Self.present, allowed: true)
            for (id, p) in frame where !p.isMoving {
                #expect(Self.spots[id]!.contains(p.feet), "\(id) at \(p.feet)")
                seen[id, default: []].insert("\(p.feet)")
            }
            t += 0.1
        }
        for id in Self.present { #expect(seen[id, default: []].count >= 2, "\(id)") }
    }

    @Test("the arc leaves and lands on the ground, along a straight line")
    func arc() throws {
        let move = try #require(Self.moves(day: 9_000, seconds: 60).first)
        let a = move.from, b = move.to
        var t = move.start
        var peak = 0.0
        while t <= move.start + move.duration + 0.5 {
            let p = PlateMoves.placement(of: move, at: t)
            #expect(p.lift >= 0 && p.lift <= PlateMoves.height + 1e-9)
            peak = max(peak, p.lift)
            // On the line from a to b.
            let cross = (b.x - a.x) * (p.feet.y - a.y) - (b.y - a.y) * (p.feet.x - a.x)
            #expect(abs(cross) < 1e-6 * max(1, abs(b.x - a.x) + abs(b.y - a.y)) * 1000)
            t += 0.01
        }
        #expect(peak > PlateMoves.height * 0.95)
        #expect(PlateMoves.placement(of: move, at: move.start + move.duration + 1).feet == move.to)
        #expect(PlateMoves.placement(of: move, at: move.start + move.duration + 1).lift == 0)
    }

    @Test("a card, a build or Reduce Motion mean no move, and a move in the air ends on its spot")
    func gated() {
        #expect(Self.moves(day: 9_000, seconds: 300, allowed: false).isEmpty)
        var state = PlateMoves.State()
        var t = 0.0
        while state.active == nil, t < 120 {
            state.advance(day: 9_000, elapsed: t, spots: Self.spots, present: Self.present, allowed: true)
            t += 0.05
        }
        let move = state.active
        #expect(move != nil)
        let frame = state.advance(day: 9_000, elapsed: t + 0.1, spots: Self.spots, present: Self.present, allowed: false)
        #expect(state.active == nil)
        #expect(frame[move!.id]?.feet == move!.to)
    }

    @Test("a move never lands on, or crosses, another character")
    func clear() {
        for day in [9_000, 9_001, 9_002, 9_003] {
            for move in Self.moves(day: day, seconds: 900) {
                // The others rest where the state left them; replaying is enough: they never stand in the move's way.
                #expect(move.from != move.to)
            }
        }
        var state = PlateMoves.State()
        var t = 0.0
        while t < 900 {
            let frame = state.advance(day: 9_001, elapsed: t, spots: Self.spots, present: Self.present, allowed: true)
            let all = Array(frame.values)
            for i in all.indices { for j in all.indices where i < j {
                #expect(abs(all[i].feet.x - all[j].feet.x) > 40, "t \(t)")
            } }
            t += 0.1
        }
    }

    @Test("the body widths come from the sprites, in plate pixels")
    func bodies() {
        let plate = Self.plate
        let pofu = PlateMoves.bodyWidth(of: "pofu", plate: plate)
        let mochi = PlateMoves.bodyWidth(of: "mochi", plate: plate)
        let findik = PlateMoves.bodyWidth(of: "findik", plate: plate)
        #expect(abs(pofu - 83.4) < 0.1)
        #expect(mochi > 60 && mochi < 68, "mochi \(mochi)")
        #expect(findik > 48 && findik < 56, "findik \(findik)")
        #expect(PlateMoves.clearance("pofu", "mochi") >= (pofu + mochi) / 2 + 10)
    }

    /// Every way the mover can choose: any spot for each character at once, and each character in flight
    /// along any line between two of its spots (and at every point on it) against the others at any spot.
    @Test("no two bodies touch in any combination of spots or any flight between spots")
    func bodiesNeverTouch() {
        let spots = Self.spots
        let ids = PlateMoves.ids + [PlateMoves.visitorID]
        for a in ids { for b in ids where a < b {
            let need = PlateMoves.clearance(a, b)
            for pa in spots[a] ?? [] { for pb in spots[b] ?? [] {
                #expect(abs(pa.x - pb.x) >= need, "\(a) \(pa) and \(b) \(pb) at rest")
            } }
            // In flight: a mover on a line between two of its spots, the other at any of its spots.
            for (mover, other) in [(a, b), (b, a)] where PlateMoves.ids.contains(mover) {
                for from in spots[mover] ?? [] { for to in spots[mover] ?? [] { for rest in spots[other] ?? [] {
                    for t in stride(from: 0.0, through: 1.0, by: 0.02) {
                        let x = from.x + (to.x - from.x) * t
                        #expect(abs(x - rest.x) >= need, "\(mover) \(from) to \(to) at \(t) against \(other) \(rest)")
                    }
                } } }
            }
        } }
    }

    @Test("the visitor has a spot of its own, on the lawn, and it is where the plate says")
    func visitor() {
        let home = HomePlate.shipped!
        let spot = try! #require(Self.spots[PlateMoves.visitorID]?.first)
        #expect(Self.spots[PlateMoves.visitorID]?.count == 1)
        #expect(PlateMath.contains(home.plate.walkable, spot))
        let placed = home.plate(PlateLife.visitorSpot(home))
        #expect(abs(placed.x - spot.x) < 1e-6 && abs(placed.y - spot.y) < 1e-6)
        #expect(PlateMoves.visitorWidth(home.plate) > 50)
    }

    @Test("each character keeps its own side: Mochi left, Pofu in the middle, Fındık right")
    func sides() {
        let s = Self.spots
        let max = { (id: String) in s[id]!.map(\.x).max()! }
        let min = { (id: String) in s[id]!.map(\.x).min()! }
        #expect(max("mochi") < min("pofu") && max("pofu") < s["visitor"]![0].x && s["visitor"]![0].x < min("findik"))
    }
}
