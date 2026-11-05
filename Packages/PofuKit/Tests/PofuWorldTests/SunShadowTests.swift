import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Sun shadow")
struct SunShadowTests {
    /// The light at an hour with the colour script's sun where the living
    /// sky puts it (the scene passes `palette.sun`).
    private func shadow(hour: Double, sun: (x: Double, y: Double)) -> SunShadow {
        SunShadow.make(light: WorldLight.at(hour: hour, wellbeing: 80, calm: 1).withSun(x: sun.x, y: sun.y))
    }

    private var noon: SunShadow { shadow(hour: 12.75, sun: (0.5, 0.11)) }
    private var morning: SunShadow { shadow(hour: 9, sun: (0.22, 0.2)) }
    private var evening: SunShadow { shadow(hour: 18.5, sun: (0.84, 0.3)) }
    private var dawn: SunShadow { shadow(hour: 6.25, sun: (0.16, 0.3)) }
    private var night: SunShadow { shadow(hour: 23, sun: (0.78, 0.14)) }

    @Test func shadowFallsAwayFromTheSun() {
        #expect(morning.direction.x > 0.3)
        #expect(evening.direction.x < -0.3)
        #expect(abs(noon.direction.x) < 0.01)
        // Always toward the viewer.
        for s in [noon, morning, evening, dawn, night] {
            #expect(s.direction.y > 0)
        }
    }

    @Test func groundIsForeshortened() {
        for s in [noon, morning, evening] {
            let norm = (s.azimuth.x * s.azimuth.x + s.azimuth.y * s.azimuth.y).squareRoot()
            #expect(abs(norm - 1) < 1e-9)
            #expect(abs(s.direction.x - s.azimuth.x) < 1e-12)
            #expect(abs(s.direction.y - s.azimuth.y * 0.5) < 1e-12)
        }
    }

    @Test func lengthFollowsTheSunsHeight() {
        #expect(abs(noon.length - 0.35) < 1e-9)
        #expect(abs(morning.length - 0.9) < 1e-9)
        #expect(evening.length > 1.4 && evening.length < 2.4)
        #expect(dawn.length > 1.4 && dawn.length < 2.4)
        #expect(noon.length < morning.length && morning.length < evening.length)
        // Clamped at both ends.
        #expect(SunShadow.length(forSunY: -1) == 0.35)
        #expect(SunShadow.length(forSunY: 2) == 2.4)
    }

    @Test func opacityBySpec() {
        // Dark enough to read over green grass, still soft.
        #expect(noon.opacity >= 0.45 && noon.opacity <= 0.55)
        #expect(evening.opacity >= 0.45 && evening.opacity <= 0.56)
        #expect(dawn.opacity >= 0.30 && dawn.opacity <= 0.38)
        #expect(noon.softness < evening.softness && evening.softness < dawn.softness)
    }

    @Test func nightIsAFaintBlueMoonShadow() {
        #expect(night.band == .night)
        #expect(night.opacity >= 0.06 && night.opacity <= 0.12)
        #expect(abs(night.length - 1.2) < 1e-9)
        #expect(night.tint.b > night.tint.r)
        #expect(night.opacity < noon.opacity / 2)
    }

    @Test func padIsDarkerAtNight() {
        #expect(abs(noon.padOpacity - 0.38) < 1e-9)
        #expect(abs(night.padOpacity - 0.42) < 1e-9)
    }

    private func luminance(_ c: GradeRGB) -> Double { 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }

    @Test func dayTintIsTheCellsShadowHueDarkened() {
        let cell = WorldLight.at(hour: 12.75, wellbeing: 80, calm: 1).cell
        #expect(noon.band == .day)
        #expect(evening.band == .golden)
        // Dark (a light colour at a quarter opacity was invisible on grass)...
        #expect(abs(luminance(noon.tint) - ShadowTuning.tintLuminance) < 1e-6)
        #expect(luminance(noon.tint) < luminance(cell.shadow))
        // ...with the cell's hue: the channel ratios survive.
        let k = noon.tint.r / max(cell.shadow.r, 1e-9)
        #expect(abs(noon.tint.g - cell.shadow.g * k) < 1e-6 && abs(noon.tint.b - cell.shadow.b * k) < 1e-6)
        #expect(luminance(evening.tint) < 0.2)
        #expect(luminance(dawn.tint) < 0.2)
    }

    @Test func darkeningKeepsTheHueAndHandlesBlack() {
        let violet = SunShadow.darkened(GradeRGB(0.7, 0.5, 0.8), to: 0.2)
        #expect(abs(luminance(violet) - 0.2) < 1e-6)
        #expect(violet.b > violet.r && violet.r > violet.g)
        let black = SunShadow.darkened(.zero, to: 0.2)
        #expect(abs(black.r - 0.2) < 1e-9)
    }

    @Test func castLandsAlongTheDirection() {
        let s = morning
        let p = s.cast(from: WorldPoint(x: 10, y: 20), height: 40)
        #expect(abs(p.x - (10 + s.direction.x * s.length * 40)) < 1e-9)
        #expect(p.y > 20)
    }

    @Test func keyBucketsDirectionAndLength() {
        let base = shadow(hour: 9, sun: (0.30, 0.20))
        // A hair of sun movement is the same bucket; a real step is not.
        let nudged = shadow(hour: 9, sun: (0.3005, 0.2002))
        #expect(base.key == nudged.key)
        #expect(base.key != shadow(hour: 9, sun: (0.40, 0.20)).key)
        #expect(base.key != shadow(hour: 9, sun: (0.30, 0.26)).key)
        // 3° buckets: nothing under 1.5° changes the key.
        let angle = atan2(base.azimuth.y, base.azimuth.x)
        #expect(abs(Double(base.key.angle) * 3 - angle * 180 / .pi) <= 1.5 + 1e-9)
        #expect(abs(Double(base.key.length) * 0.1 - base.length) <= 0.05 + 1e-9)
    }

    @Test func keyChangesWithTheBand() {
        #expect(noon.key.band == .day)
        #expect(noon.key != night.key)
        #expect(Set([noon.key, noon.key, night.key]).count == 2)
    }

    @Test func aWholeDayRebuildsOnlyAFewTimes() {
        // Scrub the day in one-minute steps along the colour script's
        // sun path; the bake key must change far less than once a minute.
        var keys: [SunShadow.Key] = []
        for minute in stride(from: 6 * 60, through: 22 * 60, by: 1) {
            let hour = Double(minute) / 60
            let sky = ColourScript.cell(minuteOfDay: Double(minute)).sun
            let light = WorldLight.at(hour: hour, wellbeing: 80, calm: 1).withSun(x: sky.x, y: sky.y)
            let key = SunShadow.make(light: light).key
            if keys.last != key { keys.append(key) }
        }
        #expect(keys.count < 160)
    }

    @Test func extremeInputsStayFinite() {
        let light = WorldLight.at(hour: .nan, wellbeing: 80, calm: 1).withSun(x: .nan, y: .infinity)
        let s = SunShadow.make(light: light)
        #expect(s.length.isFinite && s.opacity.isFinite)
    }
}

@Suite("Shadow casters")
struct ShadowCastersTests {
    private func status(_ id: StationID, level: Int, island: IslandID = .home, open: Bool = true) -> StationStatus {
        StationStatus(id: id, island: island, level: level, maxLevel: 5, levelCap: 5, isOpen: open, nextCost: nil, canAfford: false, seedsPerHour: 0, capLiftsAtIslandLevel: nil)
    }

    @Test func signatureTracksBuiltHomeStationsOnly() {
        let a = ShadowCasters.Signature(stations: [status(.teaStall, level: 1), status(.garden, level: 0), status(.pier, level: 1, island: .harbor)], islandLevel: 1)
        #expect(a.levels.map(\.station) == [.teaStall])
        let b = ShadowCasters.Signature(stations: [status(.teaStall, level: 2)], islandLevel: 1)
        #expect(a != b)
        #expect(ShadowCasters.Signature(stations: [status(.teaStall, level: 1)], islandLevel: 1) != ShadowCasters.Signature(stations: [status(.teaStall, level: 1)], islandLevel: 2))
    }

    @Test func aBuiltStationBringsItsResidentAndPofuAlwaysStands() {
        let bare = ShadowCasters.casters(for: .init(stations: [], islandLevel: 1))
        #expect(bare.contains { $0.id == "pofu" })
        #expect(!bare.contains { $0.id.hasPrefix("station-") || $0.id.hasPrefix("resident-") })
        let built = ShadowCasters.casters(for: .init(stations: [status(.teaStall, level: 1)], islandLevel: 1))
        #expect(built.contains { $0.id == "station-\(StationID.teaStall.rawValue)" })
        #expect(built.contains { $0.id == "resident-\(ResidentID.mochi.rawValue)" })
    }

    @Test func waterAndOtherIslandsCastNothing() {
        let casters = ShadowCasters.casters(for: .init(stations: [status(.pond, level: 1)], islandLevel: 4))
        let pond = casters.first { $0.id == "station-\(StationID.pond.rawValue)" }
        #expect(pond?.cast == ShadowCaster.Cast.none)
        #expect(pond?.pad.isEmpty == true)
    }

    @Test func everyCasterHasAPadOrACast() {
        for level in [1, 5, 10] {
            for caster in ShadowCasters.casters(for: .init(stations: [status(.teaStall, level: min(level, 5)), status(.workshop, level: 1)], islandLevel: level)) {
                #expect(!caster.pad.isEmpty || caster.cast != .none, "\(caster.id)")
            }
        }
    }
}

@Suite("Night shadows from sources")
struct SourceShadowTests {
    private func sample(strength: Double, dx: Double, dy: Double, id: String? = "lamp") -> LightSample {
        LightSample(sourceID: id, colour: GradeRGB(1, 0.8, 0.5), directionX: dx, directionY: dy, strength: strength,
                    ambient: 0.1, moonRim: 0.5)
    }

    @Test func fallsAwayFromTheSourceAtMostThirtyPercentTimesStrength() throws {
        let s = try #require(SourceShadow.make(sample: sample(strength: 0.5, dx: 1, dy: 0)))
        // The source is to the right: the shadow points left (180°).
        #expect(abs(abs(Double(s.angle) * ShadowTuning.angleStep) - 180) <= 1.5 + 1e-9)
        #expect(Double(s.opacity) * ShadowTuning.opacityStep <= 0.30 * 0.5 + 0.011)
        let strong = try #require(SourceShadow.make(sample: sample(strength: 1.4, dx: 1, dy: 0)))
        #expect(Double(strong.opacity) * ShadowTuning.opacityStep <= 0.30 + 1e-9)
    }

    @Test func aStrongerSourceThrowsAShorterDarkerShadow() throws {
        let weak = try #require(SourceShadow.make(sample: sample(strength: 0.2, dx: 0, dy: -1)))
        let strong = try #require(SourceShadow.make(sample: sample(strength: 1, dx: 0, dy: -1)))
        #expect(strong.length < weak.length)
        #expect(strong.opacity > weak.opacity)
        let length = Double(strong.length) * ShadowTuning.lengthStep
        #expect(length >= 0.6 - 0.05 && Double(weak.length) * ShadowTuning.lengthStep <= 1.4 + 0.05)
    }

    @Test func noSourceInReachKeepsTheMoonShadow() {
        #expect(SourceShadow.make(sample: sample(strength: 0, dx: 0, dy: 0, id: nil)) == nil)
        #expect(SourceShadow.make(sample: sample(strength: 0.01, dx: 1, dy: 0)) == nil)
    }

    private func night(_ hour: Double) -> (WorldSnapshot, WorldLight) {
        var w = IslandSamples.grownIsland()
        w.islandLevel = 8
        w.calm = 1.5
        return (w, WorldLight.at(hour: hour, wellbeing: 78, calm: 1.5).withSun(x: 0.78, y: 0.14))
    }

    /// A lamp a few units from Pofu's feet.
    private func lamp(nearPofu: Bool) -> LightField {
        let feet = IslandLayout.pofu
        let point = nearPofu ? WorldPoint(x: feet.x + 20, y: feet.y) : WorldPoint(x: feet.x + 900, y: feet.y)
        let source = LightSource(id: "lamp", kind: .lamp, point: point, height: 0, colour: GradeRGB(1, 0.8, 0.5),
                                 reach: 60, shape: .round, strength: 1)
        return LightField(sources: [source], ambientFloor: 0.14, moonRim: 0.5, moonColour: GradeRGB(0.7, 0.7, 0.8))
    }

    @Test func charactersCastAwayFromTheSourceInReachOnly() throws {
        let (w, _) = night(22.5)
        let near = SourceShadow.characters(field: lamp(nearPofu: true), world: w)
        let pofu = try #require(near["pofu"])
        // The lamp is to Pofu's right: his shadow points left.
        #expect(abs(abs(Double(pofu.angle) * ShadowTuning.angleStep) - 180) <= 1.5 + 1e-9)
        #expect(SourceShadow.characters(field: lamp(nearPofu: false), world: w).isEmpty)
    }

    @Test func byDayNobodyGetsASourceShadow() {
        let (w, _) = night(12.75)
        let noonLight = WorldLight.at(hour: 12.75, wellbeing: 78, calm: 1.5).withSun(x: 0.5, y: 0.11)
        #expect(SunShadow.make(light: noonLight, world: w).characters.isEmpty)
        let (_, nightLight) = night(22.5)
        #expect(SunShadow.make(light: nightLight).characters.isEmpty)
        #expect(SunShadow.make(light: nightLight, world: w).band == .night)
    }

    @Test func theKeyFollowsTheCharactersShadows() throws {
        let (w, _) = night(22.5)
        var sun = SunShadow.make(light: night(22.5).1)
        let base = sun.key
        sun.characters = SourceShadow.characters(field: lamp(nearPofu: true), world: w)
        #expect(!sun.characters.isEmpty)
        #expect(sun.key != base)
    }

    @Test func appliedShadowTakesTheSourcesDirectionAndKeepsTheHue() throws {
        let (w, light) = night(22.5)
        var sun = SunShadow.make(light: light)
        sun.characters = SourceShadow.characters(field: lamp(nearPofu: true), world: w)
        let source = try #require(sun.characters["pofu"])
        let own = sun.applying(source)
        #expect(own.tint == sun.tint)
        #expect(own.opacity <= 0.30 + 1e-9 && own.opacity > 0.1)
        #expect(own.direction.x < 0)
        #expect(own.characters.isEmpty)
        #expect(own.softness == ShadowTuning.sourceSoftness)
    }
}
