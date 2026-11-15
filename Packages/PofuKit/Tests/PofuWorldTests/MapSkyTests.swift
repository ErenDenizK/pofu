import Foundation
import PofuCore
import PofuDesignSystem
@testable import PofuWorld
import Testing

/// The Map and the flights in the painted world (R4 of docs/research/route-2026-11-12-codex-pause.md):
/// Home's painted sky behind them at every distance, Home's clean Map cut, no sprite isle.
@Suite("The painted Map")
struct MapSkyTests {
    static let world = IslandSamples.world(
        clock: nil, tendedDays: 12, levels: [:], jar: .zero, islands: [.home, .harbor], islandLevel: 5
    )

    static func look(_ hour: Double) -> WorldLook {
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = .clear
        return look
    }

    /// The phones the sky must cover: the reference one, a wide one, a narrow one and the shortest.
    static let screens: [(width: Double, height: Double)] = [(402, 874), (440, 956), (393, 852), (375, 667)]

    @Test func theMapTakesHomesSkyAtTheHoursLight() throws {
        for (hour, light) in [(12.0, "day"), (18.0, "golden"), (23.0, "night"), (6.0, "day")] {
            let sky = try #require(PaintedSky.mapSky(world: Self.world, look: Self.look(hour)), "hour \(hour)")
            #expect(sky.light == light, "hour \(hour)")
            #expect(sky.stage == 0)
            #expect(sky.plate.island == "home")
            #expect(sky.skySet != nil)
            // The same sky as the stops': a flight lands under the painting it flew through.
            #expect(PaintedSky.sky(for: .koke, world: Self.world, look: Self.look(hour))?.light == light)
        }
        var bed = Self.world
        bed.isBedtime = true
        #expect(PaintedSky.mapSky(world: bed, look: Self.look(12))?.light == "night")
        var sprites = Self.look(12)
        sprites.homePlates = false
        #expect(PaintedSky.mapSky(world: Self.world, look: sprites) == nil)
    }

    /// Every camera the player meets between stops: the Map, the flight's apex, the three stops of each
    /// island, and every instant of the flights from Home's Island and Home stops to Koke, Çağlayan and
    /// the harbor and back.
    static func cameras(width: Double, height: Double) throws -> [(name: String, pose: CameraPose)] {
        let home = try #require(HomePlate.shipped)
        let rail = CameraRail(width: width, height: height, stops: home.stops, whole: home.wholeStop)
        var poses: [(String, CameraPose)] = [
            ("map", rail.pose(of: .map)), ("apex", rail.pose(z: CameraFlight.apexZ)), ("past the map", rail.pose(z: -0.3)),
            ("island", rail.pose(of: .island)), ("home", rail.pose(of: .home)),
        ]
        for island in [IslandID.koke, .caglayan, .harbor] {
            let stop = try #require(IslandFraming.isleStop(island, width: width, height: height))
            let at = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
            poses.append(("\(island) stop", at))
            for from in [rail.pose(of: .island), rail.pose(of: .home)] {
                for (a, b) in [(from, at), (at, from)] {
                    let flight = CameraFlight(from: a, to: b, apexLogScale: rail.pose(z: CameraFlight.apexZ).logScale)
                    for step in 0...20 {
                        poses.append(("flight \(island) \(step)", flight.pose(at: flight.duration * Double(step) / 20)))
                    }
                }
            }
        }
        return poses
    }

    /// At every one of those cameras, on every phone and in every light, the Map's sky set covers the
    /// whole screen: its gradient sky everywhere, its tiles across the width at any drift, and its painted
    /// cloud sea down to the bottom edge. On the Map the distant isles and the whale stand above Home's
    /// island, in the lane between the wonder islands and Home on the reference phone (the crystal isle up
    /// in the empty sky), and the cloud sea's horizon lies on the Map's horizon row, under the lane and
    /// above Home's foot. No code sky shows at a seam.
    @Test func theMapSkyCoversTheScreenAtEveryCamera() throws {
        let home = try #require(HomePlate.shipped)
        let map = try #require(WorldMap.shipped)
        for light in ["day", "golden", "night"] {
            let hour = ["day": 12.0, "golden": 18.0, "night": 23.0][light]!
            let plate = try #require(PaintedSky.mapSky(world: Self.world, look: Self.look(hour)))
            let set = MapSlots.sky(try #require(plate.skySet), plate: plate)
            let sky = try #require(set.layers.first { $0.role == .sky })
            let near = try #require(set.layers.last { $0.asset.contains("-sea-") })
            let horizon = try #require(set.layers.first { $0.asset.contains("-sea-") })
            for screen in Self.screens {
                for camera in try Self.cameras(width: screen.width, height: screen.height) {
                    let reference = plate.skyReference(width: screen.width, height: screen.height)
                    func rect(_ layer: SkySet.Layer) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
                        let pose = DepthLayer.pose(camera.pose, reference: reference, k: layer.k)
                        let box = plate.worldBox(
                            master: PlateRect(minX: layer.pos.x, minY: layer.pos.y, maxX: layer.pos.x + layer.size.x, maxY: layer.pos.y + layer.size.y),
                            of: set
                        )
                        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: screen.width)
                        var (y, h) = (a.y, box.height * pose.scale)
                        if layer.role == .sky {
                            let rows = DepthLayer.coveringSky(minY: y, maxY: y + h, screenHeight: screen.height)
                            (y, h) = (rows.minY, rows.maxY - rows.minY)
                        }
                        return (a.x, y, a.x + box.width * pose.scale, y + h)
                    }
                    let s = rect(sky)
                    #expect(s.minX <= 0 && s.minY <= 0 && s.maxX >= screen.width && s.maxY >= screen.height, "\(light) sky \(screen) \(camera.name)")
                    for layer in set.layers where layer.role == .tile {
                        let r = rect(layer)
                        let w = r.maxX - r.minX
                        let n = SkyMotion.copies(left: r.minX, width: w, screen: screen.width)
                        #expect(r.minX + Double(n.lowerBound) * w <= 0 && r.minX + Double(n.upperBound + 1) * w >= screen.width, "\(light) \(layer.id) width \(screen) \(camera.name)")
                    }
                    let r = rect(near)
                    let seaFoot = r.minY + (try #require(near.window).bottom - (try #require(near.window)).bottomFade) * (r.maxY - r.minY)
                    #expect(seaFoot >= screen.height, "\(light) sea bottom \(screen) \(camera.name)")
                    guard camera.name == "map" else { continue }
                    let box = home.islandBox
                    let top = camera.pose.project(WorldPoint(x: box.minX, y: box.minY), width: screen.width).y
                    let foot = camera.pose.project(WorldPoint(x: box.minX, y: box.maxY), width: screen.width).y
                    let isReference = screen.width == 402 && screen.height == 874
                    for layer in set.layers where layer.role == .whale || layer.asset.contains("-isle-") {
                        let r = rect(layer)
                        #expect(r.maxY <= top, "\(light) \(layer.asset) above Home \(screen)")
                        guard isReference else { continue }
                        if layer.id == MapSlots.featureLayers["isle-top"] {
                            #expect(r.maxY < 150, "\(light) \(layer.id) up in the empty sky")
                        } else {
                            #expect(r.minY >= map.backdropLane.lowerBound - 0.5 && r.maxY <= map.backdropLane.upperBound + 0.5, "\(light) \(layer.id) in the lane: \(r.minY)...\(r.maxY)")
                        }
                    }
                    let h = rect(horizon)
                    let window = try #require(horizon.window)
                    let line = h.minY + window.top * (h.maxY - h.minY)
                    #expect(line > map.backdropLane.upperBound / 874 * screen.height - 0.03 * screen.height && line < foot, "\(light) horizon \(line) under the lane, above Home's foot \(foot) \(screen)")
                    if isReference { #expect(abs(line - map.horizon * screen.height) < 0.5, "\(light) horizon on the Map's row") }
                }
            }
        }
    }

    /// The Map's sky set is the sky set's own layers: the island left out, the isles and the whale smaller
    /// about their middles, the mid clouds above their residue, and the cloud sea a stack of its clean band
    /// with no gap from the horizon down to its painted rows.
    @Test func theMapSetIsTheSkySetRearranged() throws {
        for (hour, light) in [(12.0, "day"), (18.0, "golden"), (23.0, "night")] {
            let source = try #require(PaintedSky.mapSky(world: Self.world, look: Self.look(hour))?.skySet)
            let set = PaintedSky.mapSet(source)
            #expect(!set.layers.contains { $0.role == .island }, "\(light)")
            for layer in set.layers where layer.role == .whale || layer.asset.contains("-isle-") {
                let painted = try #require(source.layers.first { $0.id == layer.id })
                #expect(abs(layer.size.x - painted.size.x * PaintedSky.mapIsleScale) < 1e-9)
                #expect(abs((layer.pos.x + layer.size.x / 2) - (painted.pos.x + painted.size.x / 2)) < 1e-9)
            }
            let mid = try #require(set.layers.first(where: SkySet.isMidClouds))
            #expect(mid.window != nil)
            let sea = set.layers.filter { $0.asset.contains("-sea-") }
            #expect(sea.count == PaintedSky.mapSeaStack.count + 1 + PaintedSky.mapSeaBelow.count)
            // Farthest first; under each band's fading top the band behind it is still whole.
            func band(_ l: SkySet.Layer) throws -> (top: Double, opaqueTop: Double, opaqueBottom: Double) {
                let w = try #require(l.window)
                return (l.pos.y + w.top * l.size.y, l.pos.y + (w.top + w.topFade) * l.size.y, l.pos.y + (w.bottom - w.bottomFade) * l.size.y)
            }
            for (far, nearer) in zip(sea, sea.dropFirst()) {
                let a = try band(far), b = try band(nearer)
                #expect(b.top >= a.top, "\(light) \(nearer.id) lies under \(far.id)")
                #expect(a.opaqueBottom >= b.opaqueTop - 1e-6, "\(light) no gap above \(nearer.id)")
            }
        }
    }

    /// The painted Map is the tier-1 frame in journey order (Map order A): Home low and in front, its
    /// foot at 0.80 of the height and 230 pt wide; Koke and Çağlayan rising behind it, whole on screen,
    /// below the status bar's band and above Home. Tier 2 takes over once Çağlayan blooms.
    @Test func thePaintedMapIsTheTierOneFrameInJourneyOrder() throws {
        let home = try #require(HomePlate.shipped)
        let stop = home.mapStop
        #expect(home.stops.first == stop)
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let w = CameraRail.referenceWidth, h = CameraRail.referenceHeight
        func screen(_ box: WorldBox) -> ScreenBox {
            let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: w)
            let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: w)
            return ScreenBox(minX: a.x, minY: a.y, maxX: b.x, maxY: b.y)
        }
        let homeBox = screen(home.islandBox)
        #expect(abs(homeBox.maxY / h - 0.80) < 0.002)
        #expect(abs(homeBox.width - 230) < 2)
        for box in [KokeLayout.islandBox, CaglayanLayout.islandBox].map(screen) {
            #expect(box.minX >= 0 && box.maxX <= w, "\(box) across")
            #expect(box.minY >= 84 - 0.5, "\(box) below the status bar's band")
            #expect(box.maxY < homeBox.minY - 100, "\(box) behind and above Home")
        }
        var bloomed = home
        bloomed.mapTier = 2
        #expect(bloomed.mapStop.scale < stop.scale)
        var world = Self.world
        world.caglayan = WonderStatus(phase: .arrived, stage: 4)
        #expect(HomePlate.resolve(world: world, look: Self.look(12))?.mapTier == 2)
        #expect(HomePlate.resolve(world: Self.world, look: Self.look(12))?.mapTier == 1)
    }

    /// What each slot holds follows the player: day 1 Koke's slot is veiled and Çağlayan's a cloud tower;
    /// once Koke can be visited it is the island and Çağlayan's is veiled; then both are islands.
    @Test func theSlotsFollowTheJourney() {
        let hidden = WonderStatus(), rumoured = WonderStatus(phase: .rumoured), arrived = WonderStatus(phase: .arrived, stage: 1)
        #expect(MapSlots.stage(koke: hidden, caglayan: hidden) == 1)
        #expect(MapSlots.stage(koke: rumoured, caglayan: hidden) == 1)
        #expect(MapSlots.stage(koke: arrived, caglayan: hidden) == 2)
        #expect(MapSlots.stage(koke: arrived, caglayan: rumoured) == 2)
        #expect(MapSlots.stage(koke: arrived, caglayan: arrived) == 3)
        #expect(MapSlots.tier(caglayan: arrived) == 1)
        #expect(MapSlots.tier(caglayan: WonderStatus(phase: .arrived, stage: WonderIslands.healedStage)) == 2)
        let states = { (stage: Int) in Dictionary(uniqueKeysWithValues: MapSlots.slots(stage: stage, tier: 1).map { ($0.id, $0.state) }) }
        #expect(states(1) == ["koke": .veiled, "caglayan": .cloud])
        #expect(states(2) == ["koke": .island, "caglayan": .veiled])
        #expect(states(3) == ["koke": .island, "caglayan": .island])
        #expect(MapSlots.slots(stage: 3, tier: 2).count == 5)
        for slot in MapSlots.slots(stage: 1, tier: 1) {
            // The tower stands on the slot's foot, centred on it; a veiled slot's island shows inside.
            #expect(abs(slot.tower.maxY - slot.box.maxY) < 1e-9 && abs(slot.tower.midX - slot.box.midX) < 1e-9)
            if slot.state == .veiled {
                let veil = MapSlots.veilBox(of: slot)
                #expect(veil.map { $0.minX >= slot.tower.minX && $0.maxX <= slot.tower.maxX && $0.minY >= slot.tower.minY && $0.maxY <= slot.tower.maxY } == true)
                #expect(MapSlots.veilArt(slot.id) == "world-koke-island-0__deep")
            }
        }
        let assets = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        for name in [MapSlots.towerArt, "world-koke-island-0__deep", "world-caglayan-island-0__deep"] {
            #expect(FileManager.default.fileExists(atPath: assets.appendingPathComponent("\(name).imageset/Contents.json").path), "\(name)")
        }
    }

    /// The islands bob 2 pt top to bottom, each over its own 6 to 9 s, at the Map only: none at rest and
    /// none from a quarter of the way to the Island stop in.
    @Test func theIslandsBobAtTheMapOnly() {
        for id in ["home", "koke", "caglayan", "tier2-a"] {
            #expect((6.0 ... 9.0).contains(MapSlots.bobPeriod(id)), "\(id)")
            let samples = stride(from: 0.0, to: 20, by: 0.05).map { MapSlots.bob(id, time: $0, z: 0) }
            #expect(abs(samples.max()! - samples.min()! - MapSlots.bobTravel) < 0.01, "\(id) travels 2 pt")
            #expect(MapSlots.bob(id, time: nil, z: 0) == 0)
            for z in [0.25, 0.5, 1, 2] {
                #expect(stride(from: 0.0, to: 20, by: 0.5).allSatisfy { MapSlots.bob(id, time: $0, z: z) == 0 }, "\(id) still at z \(z)")
            }
            #expect(abs(MapSlots.bob(id, time: 3, z: 0.1)) <= abs(MapSlots.bob(id, time: 3, z: 0)) + 1e-12)
        }
        #expect(Set(["home", "koke", "caglayan"].map(MapSlots.bobPeriod)).count == 3, "they never move together")
    }

    /// Koke's and Çağlayan's soft shadow on the Map's cloud sea: under the island's middle, a little above
    /// its foot (half behind the belly), not wider than the island, faint.
    @Test func theWonderIslesCastASoftShadowOnTheSea() {
        for box in [KokeLayout.islandBox, CaglayanLayout.islandBox] {
            let s = PaintedSky.isleShadow(under: box)
            #expect(abs(s.centre.x - box.midX) < 1e-9)
            #expect(s.centre.y > box.midY && s.centre.y < box.maxY)
            #expect(s.centre.y + s.height / 2 > box.maxY)
            #expect(s.width <= box.width && s.height < s.width / 2)
            #expect(s.opacity > 0 && s.opacity < 0.5)
        }
    }

    /// Koke's stop draws Home's sky set without what Home's island hid there, as the Map does (the mid
    /// clouds above their residue, the cloud sea as its clean band under its receding stack); its distant
    /// isles and whale stay as painted.
    @Test func aWonderStopsSkyIsTheSetWithoutHomesHiddenFill() throws {
        for (hour, light) in [(12.0, "day"), (18.0, "golden"), (23.0, "night")] {
            let source = try #require(PaintedSky.sky(for: .koke, world: Self.world, look: Self.look(hour))?.skySet)
            let set = PaintedSky.stopSet(source)
            let map = PaintedSky.mapSet(source)
            #expect(!set.layers.contains { $0.role == .island }, "\(light)")
            for layer in set.layers where layer.role == .whale || layer.asset.contains("-isle-") {
                #expect(source.layers.contains(layer), "\(light) \(layer.id) as painted")
            }
            #expect(set.layers.first(where: SkySet.isMidClouds)?.window != nil, "\(light)")
            let sea = set.layers.filter { $0.asset.contains("-sea-") }
            // The Map's sea is the stop's, its near band cropped above the hazy foot, and the rows below it.
            let mapSea = map.layers.filter { $0.asset.contains("-sea-") }
            #expect(sea.dropLast() == Array(mapSea.prefix(PaintedSky.mapSeaStack.count)), "\(light)")
            #expect(sea.count == PaintedSky.mapSeaStack.count + 1)
            #expect(mapSea.count == PaintedSky.mapSeaStack.count + 1 + PaintedSky.mapSeaBelow.count)
        }
    }

    @Test func aWindowFadesInAndOut() {
        let w = SkySet.Window(top: 0.2, bottom: 0.8, topFade: 0.1, bottomFade: 0.2)
        #expect(w.opacity(at: 0.1) == 0)
        #expect(abs(w.opacity(at: 0.25) - 0.5) < 1e-9)
        #expect(w.opacity(at: 0.5) == 1)
        #expect(abs(w.opacity(at: 0.7) - 0.5) < 1e-9)
        #expect(w.opacity(at: 0.9) == 0)
    }

    @Test func tileCopiesCoverTheScreen() {
        for (left, width) in [(-300.0, 2000.0), (-50.0, 120.0), (380.0, 90.0), (-1000.0, 333.0)] {
            let n = SkyMotion.copies(left: left, width: width, screen: 402)
            #expect(left + Double(n.lowerBound) * width <= 0)
            #expect(left + Double(n.upperBound + 1) * width >= 402)
        }
    }

    /// The Map draws Home's sky set through the same depth function as Home does, from Home's stop: at the
    /// reference every layer is the camera's own, and between there and the Map the layers move by their
    /// depth, the island layer with the camera and the sky not at all.
    @Test func mapSkyIsTheSameSetThroughTheDepthFunction() throws {
        let plate = try #require(PaintedSky.mapSky(world: Self.world, look: Self.look(12)))
        let set = try #require(plate.skySet)
        let cameras = try Self.cameras(width: 402, height: 874)
        let reference = plate.skyReference(width: 402, height: 874)
        let home = try #require(cameras.first { $0.name == "home" }?.pose)
        let map = try #require(cameras.first { $0.name == "map" }?.pose)
        #expect(abs(home.scale - reference.scale) < 1e-9 && abs(home.lookX - reference.lookX) < 1e-9)
        for layer in set.layers {
            let atHome = DepthLayer.pose(home, reference: reference, k: layer.k)
            #expect(atHome == home || (abs(atHome.logScale - home.logScale) < 1e-9 && abs(atHome.lookX - home.lookX) < 1e-9), "\(layer.id) at Home")
            let atMap = DepthLayer.pose(map, reference: reference, k: layer.k)
            switch layer.k {
            case 0: #expect(abs(atMap.scale - reference.scale) < 1e-9 && abs(atMap.lookX - reference.lookX) < 1e-9, "\(layer.id) never moves")
            case 1: #expect(abs(atMap.scale - map.scale) < 1e-9 && abs(atMap.lookX - map.lookX) < 1e-9, "\(layer.id) is the camera")
            default: #expect(atMap.scale < reference.scale && atMap.scale > map.scale, "\(layer.id) between the two")
            }
        }
    }

    /// Home's island on the Map is cut from each level's own painting (`tools/plate/map_cut.py`): every
    /// painted state has its Map cut in the catalog, at the island cut's own size.
    @Test func everyHomeStateHasItsMapCut() throws {
        let home = try #require(HomePlate.shipped?.plate)
        let assets = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PofuWorld/Resources/World.xcassets")
        var count = 0
        for light in ["day", "golden", "night"] {
            for stage in 0..<10 where home.paints(light: light, stage: stage) {
                let name = home.mapIslandArt(light: light, stage: stage)
                #expect(name == "world-home-mapisle-\(light)-\(stage)")
                let file = assets.appendingPathComponent("\(name).imageset/\(name).heic")
                #expect(FileManager.default.fileExists(atPath: file.path), "\(name)")
                count += 1
            }
        }
        #expect(count >= 20)
    }

    @Test func theMidCloudsAreOneTileOfEachLight() throws {
        for (hour, light) in [(12.0, "day"), (18.0, "golden"), (23.0, "night")] {
            let set = try #require(PaintedSky.mapSky(world: Self.world, look: Self.look(hour))?.skySet)
            #expect(set.layers.filter(SkySet.isMidClouds).map(\.asset) == ["world-home-sky-mid-\(light)-0"])
        }
    }

    @Test func anotherIslandKeepsItsIslandCut() throws {
        let caglayan = try #require(HomePlate.caglayanIsland)
        #expect(caglayan.mapIslandArt(light: "day", stage: 2) == caglayan.islandArt(light: "day", stage: 2))
    }

    /// On the painted Map Home answers over its painted island, and the harbor's sprite isle is not a
    /// target (it is not drawn there); Koke and Çağlayan answer once they can be visited.
    @Test func thePaintedMapHasNoHarborTarget() throws {
        let plate = try #require(HomePlate.resolve(world: Self.world, look: Self.look(12)))
        let targets = WorldHitTest.plateTargets(plate, stations: Self.world.stations, z: 0, koke: .arrived, caglayan: .arrived)
        let islands = targets.compactMap { target -> IslandID? in
            if case .island(let id) = target.kind { return id }
            return nil
        }
        #expect(Set(islands) == [.home, .koke, .caglayan])
        let home = try #require(targets.first { $0.kind == .island(.home) })
        #expect(home.worldBox == plate.islandBox)
        // The sprite world's Map is unchanged.
        #expect(WorldHitTest.islandTargets().contains { $0.kind == .island(.harbor) })
    }

    /// A flight held for a screenshot sits where the flight would be at that instant.
    @Test func aHeldFlightIsTheFlightsPose() throws {
        var rig = CameraRig()
        let stop = try #require(IslandFraming.isleStop(.koke, width: rig.rail.width, height: rig.rail.height))
        let to = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        rig.startFlight(to: to, landing: .pose(to))
        let flight = try #require(rig.flight)
        rig.holdFlight(at: 0.5)
        #expect(rig.pose == flight.pose(at: flight.duration / 2))
        #expect(abs(rig.railPosition - CameraFlight.apexZ) < 0.05)
    }
}
