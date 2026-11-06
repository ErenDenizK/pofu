import Foundation
import PofuCore

/// The build moment (interaction spec §2.4), as a pure function of the time
/// since the tap. The model has already committed (`WorldClock.build`:
/// seeds spent, level up); everything here is presentation and can be
/// interrupted.
///
/// | t (s) | Cue | What happens |
/// |---|---|---|
/// | 0 | `pushIn` | The sheet drops to compact; the camera pushes in to ×1.95 |
/// | 0.30 | `anticipation` | The station squashes to 1.06 × 0.88, ease-in, 120 ms |
/// | 0.42 | `swap` | The art swaps inside a 120 ms cross-fade at the deepest point; six dust puffs; `pop` back; medium impact |
/// | 0.45 | `sparkles` | Seven sparkles, 30 ms apart, 0.8 s each |
/// | 0.60 | `tag` | "Seviye n!" pops above the station and lives 2.6 s |
/// | 0.72 | `pofuHop` | Pofu hops |
/// | 0.84 | `residentHop` | The resident hops |
/// | 1.02 | `settle` | `.success` |
/// | 1.75 | `sheetBack` | The sheet returns to medium; the camera settles back |
/// | 3.20 | `end` | The tag is gone |
///
/// The level-up ceremony of light (light and shadow v2, section 5) rides on
/// the swap: the station's lit sources flare one after another, a warm burst
/// blooms and covers the shadow layer's rebuild, and the pad under the
/// station brightens (see the `Ceremony` extension).
///
/// With Reduce Motion there is no squash, no particle and no hop: the art
/// cross-fades in 200 ms and the tag fades in.
public struct BuildMoment: Hashable, Sendable {
    public enum Cue: Int, Hashable, Sendable, CaseIterable, Comparable {
        case pushIn
        case anticipation
        case swap
        case sparkles
        case tag
        case pofuHop
        case residentHop
        case settle
        case sheetBack
        case end

        public static func < (lhs: Cue, rhs: Cue) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public let station: StationID
    public let fromLevel: Int
    public let toLevel: Int
    public let maxLevel: Int
    public let reduceMotion: Bool
    /// Low Power Mode: a shorter ceremony of light and no particles.
    public let lowPower: Bool

    public init(station: StationID, fromLevel: Int, toLevel: Int, maxLevel: Int, reduceMotion: Bool, lowPower: Bool = false) {
        self.lowPower = lowPower
        self.station = station
        self.fromLevel = fromLevel
        self.toLevel = toLevel
        self.maxLevel = maxLevel
        self.reduceMotion = reduceMotion
    }

    /// The last level: the settle plays the celebration pattern.
    public var isFinalLevel: Bool {
        toLevel >= maxLevel
    }

    // MARK: - Timeline

    public static let squashDepth = (x: 1.06, y: 0.88)
    public static let crossFade = 0.12
    public static let reducedCrossFade = 0.2
    public static let tagLife = 2.6
    public static let sparkleCount = 7
    public static let sparkleLife = 0.8
    public static let sparkleStagger = 0.03
    public static let puffCount = 6
    public static let puffLife = 0.6
    /// A resident's hop: height in world units and length in seconds.
    public static let residentHopHeight = 10.0
    public static let residentHopLength = 0.42

    /// When `cue` plays, or `nil` when it does not (Reduce Motion drops the
    /// squash, the particles and the hops).
    public func time(of cue: Cue) -> Double? {
        if reduceMotion {
            switch cue {
            case .pushIn: return 0
            case .swap: return 0.10
            case .tag: return 0.10
            case .settle: return 0.30
            case .sheetBack: return 1.2
            case .end: return 0.10 + Self.tagLife
            case .anticipation, .sparkles, .pofuHop, .residentHop: return nil
            }
        }
        switch cue {
        case .pushIn: return 0
        case .anticipation: return 0.30
        case .swap: return 0.42
        case .sparkles: return 0.45
        case .tag: return 0.60
        case .pofuHop: return 0.72
        case .residentHop: return 0.84
        case .settle: return 1.02
        case .sheetBack: return 1.75
        case .end: return 0.60 + Self.tagLife
        }
    }

    public var duration: Double {
        time(of: .end) ?? 0
    }

    /// The cues in `(after, through]`, in time order.
    public func cues(after start: Double, through end: Double) -> [Cue] {
        Cue.allCases.filter { cue in
            guard let t = time(of: cue) else { return false }
            return (t > start || (t == 0 && start < 0)) && t <= end
        }
        .sorted { (time(of: $0) ?? 0, $0) < (time(of: $1) ?? 0, $1) }
    }

    // MARK: - The station

    /// The station's scale around its footprint at `t`: the anticipation
    /// squash, then a `pop` spring back through a small stretch.
    public func stationScale(at t: Double) -> (x: Double, y: Double) {
        guard !reduceMotion, let squash = time(of: .anticipation), let swap = time(of: .swap) else { return (1, 1) }
        let depth = Self.squashDepth
        if t < squash {
            return (1, 1)
        }
        if t < swap {
            let p = MomentCurves.easeIn(MomentCurves.progress(t, from: squash, length: swap - squash))
            return (1 + (depth.x - 1) * p, 1 + (depth.y - 1) * p)
        }
        let r = MomentCurves.springRemaining(t - swap, duration: 0.55, bounce: 0.5)
        return (1 + (depth.x - 1) * r, 1 + (depth.y - 1) * r)
    }

    /// How far the new level's art has faded in, 0…1.
    public func newArt(at t: Double) -> Double {
        guard let swap = time(of: .swap) else { return 1 }
        let length = reduceMotion ? Self.reducedCrossFade : Self.crossFade
        return MomentCurves.progress(t, from: swap, length: length)
    }

    /// The level the station shows at `t`: the old one until the swap's
    /// midpoint.
    public func shownLevel(at t: Double) -> Int {
        newArt(at: t) >= 0.5 ? toLevel : fromLevel
    }

    // MARK: - Particles (world units around the station's footprint)

    /// Six dust puffs out of the footprint at the swap.
    public func puffs(at t: Double) -> [MomentParticle] {
        guard !reduceMotion, !lowPower, let swap = time(of: .swap) else { return [] }
        let p = (t - swap) / Self.puffLife
        guard p >= 0, p < 1 else { return [] }
        let out = MomentCurves.easeOut(p)
        return (0..<Self.puffCount).map { i in
            let angle = (Double(i) * 60 + 30) * Double.pi / 180
            let radius = 1 + 0.7 * out
            return MomentParticle(
                x: cos(angle) * 34 * radius,
                y: sin(angle) * 9 * radius - 6 * out,
                scale: 0.6 + 0.7 * out,
                opacity: 0.85 * (p < 0.35 ? 1 : 1 - (p - 0.35) / 0.65)
            )
        }
    }

    /// Where the sparkles start, relative to the footprint: around the top
    /// of the vignette. Fixed, so every build looks the same (A17).
    static let sparkleSpots: [(x: Double, y: Double)] = [
        (-34, -38), (-18, -62), (-4, -48), (12, -70), (26, -44), (38, -60), (-28, -74),
    ]

    /// Seven sparkles, staggered 30 ms, rising and twinkling for 0.8 s.
    public func sparkles(at t: Double) -> [MomentParticle] {
        guard !reduceMotion, !lowPower, let start = time(of: .sparkles) else { return [] }
        var result: [MomentParticle] = []
        for (i, spot) in Self.sparkleSpots.prefix(Self.sparkleCount).enumerated() {
            let p = (t - start - Double(i) * Self.sparkleStagger) / Self.sparkleLife
            guard p >= 0, p < 1 else { continue }
            let grow = MomentCurves.easeOut(min(p / 0.2, 1))
            let fade = p < 0.6 ? 1 : 1 - (p - 0.6) / 0.4
            result.append(MomentParticle(
                x: spot.x,
                y: spot.y - 18 * MomentCurves.easeOut(p),
                scale: grow * (1 - 0.4 * p),
                opacity: fade,
                rotation: 45 * p
            ))
        }
        return result
    }

    // MARK: - The tag and the hops

    /// The "Seviye n!" tag: its scale and opacity, or `nil` when hidden.
    public func tag(at t: Double) -> (scale: Double, opacity: Double)? {
        guard let start = time(of: .tag) else { return nil }
        let age = t - start
        guard age >= 0, age < Self.tagLife else { return nil }
        let fadeIn = reduceMotion ? MomentCurves.progress(age, from: 0, length: 0.2) : MomentCurves.progress(age, from: 0, length: 0.12)
        let fadeOut = MomentCurves.progress(age, from: Self.tagLife - 0.3, length: 0.3)
        let scale = reduceMotion ? 1 : 1 - 0.4 * MomentCurves.springRemaining(age, duration: 0.55, bounce: 0.5)
        return (scale, fadeIn * (1 - fadeOut))
    }

    /// How high the station's resident is off the ground, in world units.
    public func residentLift(at t: Double) -> Double {
        guard let start = time(of: .residentHop) else { return 0 }
        let u = (t - start) / Self.residentHopLength
        guard u > 0, u < 1 else { return 0 }
        return 4 * Self.residentHopHeight * u * (1 - u)
    }
}

// MARK: - The ceremony of light

extension BuildMoment {
    /// The ceremony's numbers, in seconds and world units.
    public enum Ceremony {
        /// Between one lit source and the next.
        public static let lampStagger = 0.04
        public static let lampRise = 0.10
        public static let lampHold = 0.14
        public static let lampFall = 0.50
        public static let burstLength = 0.90
        public static let burstPeak = 0.18
        public static let burstRadius = (from: 26.0, to: 120.0)
        public static let burstOpacity = 0.55
        /// How long the pad under the station stays brighter.
        public static let padLength = 1.2
        public static let padRise = 0.12
        /// Low Power Mode shortens every length by this factor.
        public static let lowPowerFactor = 0.6
        /// Reduce Motion fades the lamps in together and out over this long.
        public static let reducedLamp = (rise: 0.2, fall: 0.4)
    }

    /// Where the lit sources of `station` at `level` are, in world units:
    /// the `LitSources` rows live at that level, else the station's
    /// emitters (its window and door points), else its anchor.
    public static func litPoints(station: StationID, level: Int) -> [WorldPoint] {
        var points: [WorldPoint] = []
        for row in LitSources.rows {
            if case .station(let id, let from, let through) = row.requirement, id == station, (from...through).contains(level) {
                points.append(row.point)
            }
        }
        if points.isEmpty {
            points = IslandLayout.emitters.filter { $0.station == station }.map(\.point)
        }
        if points.isEmpty, let anchor = IslandLayout.stationAnchors[station] {
            points = [anchor]
        }
        return points
    }

    private var ceremonyScale: Double {
        lowPower ? Ceremony.lowPowerFactor : 1
    }

    /// When the ceremony starts: at the art swap.
    public var ceremonyStart: Double? {
        time(of: .swap)
    }

    /// The ceremony's last instant (the pad's fade).
    public var ceremonyEnd: Double? {
        ceremonyStart.map { $0 + Ceremony.padLength * ceremonyScale }
    }

    /// How much the `index`th lit source flares at `t`, 0...1: a quick rise,
    /// a short hold, then back to the time-of-day state. Sources start 40 ms
    /// apart; under Reduce Motion they all fade in and out together.
    public func lampFlare(index: Int, at t: Double) -> Double {
        guard let start = ceremonyStart else { return 0 }
        let k = ceremonyScale
        if reduceMotion {
            let age = t - start
            let rise = MomentCurves.progress(age, from: 0, length: Ceremony.reducedLamp.rise * k)
            let fall = MomentCurves.progress(age, from: Ceremony.reducedLamp.rise * k, length: Ceremony.reducedLamp.fall * k)
            return rise * (1 - fall)
        }
        let age = t - start - Double(index) * Ceremony.lampStagger
        guard age >= 0 else { return 0 }
        let rise = MomentCurves.easeOut(MomentCurves.progress(age, from: 0, length: Ceremony.lampRise * k))
        let fall = MomentCurves.smoothstep(MomentCurves.progress(age, from: (Ceremony.lampRise + Ceremony.lampHold) * k, length: Ceremony.lampFall * k))
        return rise * (1 - fall)
    }

    /// The warm burst blooming from the building: its radius in world units
    /// and its opacity, or `nil` when there is none (outside its window, or
    /// Reduce Motion, which only cross-fades).
    public func burst(at t: Double) -> (radius: Double, opacity: Double)? {
        guard !reduceMotion, let start = ceremonyStart else { return nil }
        let length = Ceremony.burstLength * ceremonyScale
        let age = t - start
        guard age >= 0, age < length else { return nil }
        let p = age / length
        let radius = Ceremony.burstRadius.from + (Ceremony.burstRadius.to - Ceremony.burstRadius.from) * MomentCurves.easeOut(p)
        let rise = MomentCurves.easeOut(MomentCurves.progress(p, from: 0, length: Ceremony.burstPeak))
        let fall = MomentCurves.smoothstep(MomentCurves.progress(p, from: Ceremony.burstPeak, length: 1 - Ceremony.burstPeak))
        return (radius, Ceremony.burstOpacity * rise * (1 - fall))
    }

    /// How much brighter the ground pad under the station is at `t`, 0...1,
    /// for 1.2 s from the swap (it is a brightness, so Reduce Motion keeps it).
    public func padGlow(at t: Double) -> Double {
        guard let start = ceremonyStart else { return 0 }
        let length = Ceremony.padLength * ceremonyScale
        let age = t - start
        guard age >= 0, age < length else { return 0 }
        let rise = MomentCurves.easeOut(MomentCurves.progress(age, from: 0, length: Ceremony.padRise * ceremonyScale))
        let fall = MomentCurves.smoothstep(MomentCurves.progress(age, from: Ceremony.padRise * ceremonyScale, length: length - Ceremony.padRise * ceremonyScale))
        return rise * (1 - fall)
    }
}
