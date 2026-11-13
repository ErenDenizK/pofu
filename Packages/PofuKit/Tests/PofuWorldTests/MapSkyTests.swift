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
    /// island and the cloud sea's horizon lies behind it. No code sky shows at a seam.
    @Test func theMapSkyCoversTheScreenAtEveryCamera() throws {
        let home = try #require(HomePlate.shipped)
        for light in ["day", "golden", "night"] {
            let hour = ["day": 12.0, "golden": 18.0, "night": 23.0][light]!
            let plate = try #require(PaintedSky.mapSky(world: Self.world, look: Self.look(hour)))
            let set = PaintedSky.mapSet(try #require(plate.skySet))
            let sky = try #require(set.layers.first { $0.role == .sky })
            let near = try #require(set.layers.first { $0.asset.contains("-sea-") && !$0.id.contains("-map") })
            let horizon = try #require(set.layers.first { $0.asset.contains("-sea-") })
            for screen in Self.screens {
                for camera in try Self.cameras(width: screen.width, height: screen.height) {
                    let pose = PaintedSky.mapPose(camera.pose, sky: plate, width: screen.width, height: screen.height)
                    func rect(_ layer: SkySet.Layer) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
                        let box = plate.worldBox(
                            master: PlateRect(minX: layer.pos.x, minY: layer.pos.y, maxX: layer.pos.x + layer.size.x, maxY: layer.pos.y + layer.size.y),
                            of: set
                        )
                        let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: screen.width)
                        return (a.x, a.y, a.x + box.width * pose.scale, a.y + box.height * pose.scale)
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
                    #expect(r.maxY >= screen.height, "\(light) sea bottom \(screen) \(camera.name)")
                    guard camera.name == "map" else { continue }
                    let box = home.islandBox
                    let top = camera.pose.project(WorldPoint(x: box.minX, y: box.minY), width: screen.width).y
                    let foot = camera.pose.project(WorldPoint(x: box.minX, y: box.maxY), width: screen.width).y
                    for layer in set.layers where layer.role == .whale || layer.asset.contains("-isle-") {
                        #expect(rect(layer).maxY <= top + 0.02 * screen.height, "\(light) \(layer.asset) above Home \(screen)")
                    }
                    let h = rect(horizon)
                    let window = try #require(horizon.window)
                    let line = h.minY + window.top * (h.maxY - h.minY)
                    #expect(line > top && line < foot + 0.08 * screen.height, "\(light) horizon \(line) behind Home \(top)...\(foot) \(screen)")
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
            #expect(sea.count == PaintedSky.mapSeaStack.count + 1)
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

    /// The painted Map frames what it draws: the painted Home, Koke and Çağlayan fill the band between the
    /// chrome (the harbor isle, which the painted Map does not draw, is not framed), each island whole on
    /// screen and drawn larger than the sprite world's Map draws them.
    @Test func thePaintedMapFramesItsThreeIslands() throws {
        let home = try #require(HomePlate.shipped)
        let stop = home.mapStop
        #expect(stop.scale > CameraRail.referenceStops[0].scale * 1.4)
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        let w = CameraRail.referenceWidth, h = CameraRail.referenceHeight
        var lowest = 0.0, highest = h
        for box in [home.islandBox, KokeLayout.islandBox, CaglayanLayout.islandBox] {
            let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: w)
            let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: w)
            #expect(a.x >= 0 && b.x <= w, "\(box) across")
            #expect(a.y >= IslandFraming.topBand && b.y <= h - IslandFraming.bottomBand, "\(box) between the bands")
            lowest = max(lowest, b.y)
            highest = min(highest, a.y)
        }
        // The islands use the band's height, not its top half.
        #expect(lowest - highest > 0.8 * IslandFraming.bandHeight(height: h))
        #expect(home.stops.first == stop)
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
            #expect(sea == map.layers.filter { $0.asset.contains("-sea-") }, "\(light)")
            #expect(sea.count == PaintedSky.mapSeaStack.count + 1)
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

    /// The Map's sky never zooms: its scale is the same at every camera on a screen, and a flight slides
    /// it a sixteenth as far as the world.
    @Test func theMapSkySlidesAndNeverZooms() throws {
        let plate = try #require(PaintedSky.mapSky(world: Self.world, look: Self.look(12)))
        let cameras = try Self.cameras(width: 402, height: 874)
        let poses = cameras.map { PaintedSky.mapPose($0.pose, sky: plate, width: 402, height: 874) }
        let scale = poses[0].scale
        #expect(poses.allSatisfy { abs($0.scale - scale) < 1e-9 })
        let (a, b) = (cameras[0].pose, cameras[3].pose)
        let (pa, pb) = (poses[0], poses[3])
        #expect(abs((pb.lookY - pa.lookY) - (b.lookY - a.lookY) * PaintedSky.mapParallax) < 1e-9)
        #expect(abs((pb.lookX - pa.lookX) - (b.lookX - a.lookX) * PaintedSky.mapParallax) < 1e-9)
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
