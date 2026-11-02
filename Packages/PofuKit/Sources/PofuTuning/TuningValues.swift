import Foundation

/// Every number that decides how Pofu *feels*, in one data-driven value
/// (pro game craft §3.3, upgrade 3). The defaults are the bundled
/// `tuning.json`, the single source of truth; the Ayar panel in Rehearsal
/// mode changes them live on the phone and exports the changes as JSON,
/// which the agent commits back into `tuning.json`.
///
/// Every leaf is a `Double`, so the value flattens to dotted keys
/// (`camera.travel.duration`) that the panel, the export and old saved
/// overrides all share. `TuningSpec` gives each key its range and step.
public struct TuningValues: Codable, Hashable, Sendable {
    public var camera: Camera
    public var depth: Depth
    public var grade: Grade
    public var companion: Companion
    public var haptics: Haptics
    public var garden: Garden

    public init(camera: Camera, depth: Depth, grade: Grade, companion: Companion, haptics: Haptics, garden: Garden) {
        self.camera = camera
        self.depth = depth
        self.grade = grade
        self.companion = companion
        self.haptics = haptics
        self.garden = garden
    }

    /// A spring as SwiftUI and `WorldSpring` describe one: how long it
    /// takes to settle, and how much it overshoots (0 none, 1 endless).
    public struct Spring: Codable, Hashable, Sendable {
        public var duration: Double
        public var bounce: Double

        public init(duration: Double, bounce: Double) {
            self.duration = duration
            self.bounce = bounce
        }
    }

    /// The world camera's springs (`WorldSprings`).
    public struct Camera: Codable, Hashable, Sendable {
        /// Between neighbouring framings (Home ↔ Island).
        public var travel: Spring
        /// Across two framings (Home ↔ Map).
        public var far: Spring
        /// After a drag lets go.
        public var release: Spring
        /// Into a station or a resident.
        public var focus: Spring
        /// The push-in of a build moment.
        public var buildPush: Spring
    }

    /// Depth in motion and the HD-2D tilt-shift (`DepthMotion`, `LookTuning`).
    public struct Depth: Codable, Hashable, Sendable {
        /// Parallax while the camera moves, as a multiple of today's.
        public var parallax: Double
        /// Depth-of-field strength at the Island framing (1 is the rail's lens).
        public var tiltShiftIsland: Double
        /// Depth-of-field strength at the Home framing.
        public var tiltShiftHome: Double
    }

    /// Trims over the colour grade, one per time of day; the identity
    /// (exposure, saturation and contrast 1, warmth and vignette 0)
    /// leaves the hour's grade as `WorldLight` makes it.
    public struct Grade: Codable, Hashable, Sendable {
        public var day: GradeTrim
        public var golden: GradeTrim
        public var night: GradeTrim
    }

    public struct GradeTrim: Codable, Hashable, Sendable {
        /// Multiplies the grade's gain.
        public var exposure: Double
        public var saturation: Double
        public var contrast: Double
        /// Leans the gain warm (positive) or cool (negative).
        public var warmth: Double
        /// Added to the grade's vignette.
        public var vignette: Double

        public init(exposure: Double = 1, saturation: Double = 1, contrast: Double = 1, warmth: Double = 0, vignette: Double = 0) {
            self.exposure = exposure
            self.saturation = saturation
            self.contrast = contrast
            self.warmth = warmth
            self.vignette = vignette
        }

        /// No change to the hour's grade.
        public static let identity = GradeTrim()

        /// The trims of `trims` blended by `weights` (time-of-day weights
        /// that sum to 1).
        public static func blend(_ trims: [(GradeTrim, Double)]) -> GradeTrim {
            let total = max(trims.reduce(0) { $0 + $1.1 }, 1e-9)
            func mix(_ value: (GradeTrim) -> Double) -> Double {
                trims.reduce(0) { $0 + value($1.0) * $1.1 } / total
            }
            return GradeTrim(
                exposure: mix(\.exposure),
                saturation: mix(\.saturation),
                contrast: mix(\.contrast),
                warmth: mix(\.warmth),
                vignette: mix(\.vignette)
            )
        }
    }

    /// Pofu's idle life (`BreathingCurve`, `CompanionMotion`).
    public struct Companion: Codable, Hashable, Sendable {
        /// Seconds per breath when Pofu is low, and when thriving.
        public var breathPeriodLow: Double
        public var breathPeriodHigh: Double
        /// Peak vertical scale change of a breath, low and thriving.
        public var breathAmplitudeLow: Double
        public var breathAmplitudeHigh: Double
        /// Seconds between idle blinks.
        public var blinkIntervalMin: Double
        public var blinkIntervalMax: Double
    }

    /// The Ayçiçeği garden minigame's feel (`PofuGames.GardenFeel`):
    /// durations in seconds, lengths in cells unless named, haptics 0…1.
    public struct Garden: Codable, Hashable, Sendable {
        /// Plots in the tray, as a share of a bed cell (each also fits its slot).
        public var trayScale: Double
        /// How far above the thumb a lifted plot floats, in cells (plus half its height).
        public var liftCells: Double
        /// How quickly the dragged plot catches the finger, per second.
        public var followStiffness: Double
        /// How far, in cells, a blocked drop looks for the nearest fit.
        public var snapTolerance: Double
        /// Seconds for a plot to grow from the tray to full size.
        public var pickUp: Double
        /// Seconds for planted tiles to glide into their cells.
        public var snapToCell: Double
        /// Seconds of the planting squash.
        public var squash: Double
        /// How wide the planting squash goes (0.14 is 1.14 x 0.86).
        public var squashAmount: Double
        /// Seconds for a missed drop to spring back to the tray.
        public var trayReturn: Double
        /// Seconds for a new plot to pop into the tray.
        public var deal: Double
        /// Seconds between the three new plots.
        public var dealStagger: Double
        /// Seconds between bloom steps sweeping out from the drop.
        public var bloomStagger: Double
        /// Seconds of a sunflower's pop.
        public var bloomPop: Double
        /// Seconds a sunflower stays before its seed flies.
        public var bloomHold: Double
        /// The pop's overshoot at combo 1; it grows with the combo.
        public var bloomOvershoot: Double
        /// Seconds of a seed's arc into Pofu's cheeks.
        public var seedFlight: Double
        /// A flying seed's height in points.
        public var seedSize: Double
        /// Seeds that fly per bloomed line.
        public var seedsPerLine: Double
        /// How bright lines about to bloom glow (added light).
        public var glowStrength: Double
        /// The screen shake's ceiling in points (double blooms and combos of 3 only).
        public var shakeMaximum: Double
        /// Lifting a plot.
        public var hapticLift: Double
        /// Planting.
        public var hapticPlant: Double
        /// A one-line bloom; more lines and combos add to it.
        public var hapticBloom: Double
        /// A seed landing in Pofu's cheeks.
        public var hapticCheek: Double
    }

    /// Haptic intensities, 0…1.
    public struct Haptics: Codable, Hashable, Sendable {
        public var pofuTap: Double
        public var collectTap: Double
        public var buildSwap: Double
        public var hopAppearDay: Double
        public var hopAppearNight: Double
        public var breathStart: Double
    }
}

// MARK: - Defaults

extension TuningValues {
    /// The bundled defaults (`Resources/tuning.json`). A test proves the
    /// file decodes, so a failure here is a broken build, not user data.
    public static let defaults: TuningValues = {
        do {
            return try bundled()
        } catch {
            preconditionFailure("tuning.json does not decode: \(error)")
        }
    }()

    /// Decodes the bundled `tuning.json`.
    public static func bundled() throws -> TuningValues {
        guard let url = Bundle.module.url(forResource: "tuning", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(TuningValues.self, from: Data(contentsOf: url))
    }
}

// MARK: - Flat keys

extension TuningValues {
    /// Every leaf as `dotted.key: value`.
    public func flattened() -> [String: Double] {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
            let object = try? JSONSerialization.jsonObject(with: data)
        else { return [:] }
        var flat: [String: Double] = [:]
        Self.flatten(object, prefix: "", into: &flat)
        return flat
    }

    /// `base` with `overrides` laid over it. Keys `base` does not have
    /// (a renamed or removed value in an old saved file) are ignored, and
    /// non-finite values are dropped.
    public init(base: TuningValues, overrides: [String: Double]) {
        var flat = base.flattened()
        for (key, value) in overrides where flat[key] != nil && value.isFinite {
            flat[key] = value
        }
        self = (try? Self(flat: flat)) ?? base
    }

    /// Rebuilds a value from a complete set of flat keys.
    public init(flat: [String: Double]) throws {
        var root: [String: Any] = [:]
        for (key, value) in flat {
            Self.insert(value, at: key.split(separator: ".").map(String.init), into: &root)
        }
        let data = try JSONSerialization.data(withJSONObject: root)
        self = try JSONDecoder().decode(TuningValues.self, from: data)
    }

    /// The keys whose values differ from `base`, sorted.
    public func changes(from base: TuningValues) -> [TuningChange] {
        let mine = flattened()
        let theirs = base.flattened()
        return mine.keys.sorted().compactMap { key in
            guard let value = mine[key], let original = theirs[key], abs(value - original) > 1e-9 else { return nil }
            return TuningChange(key: key, defaultValue: original, value: value)
        }
    }

    private static func flatten(_ object: Any, prefix: String, into flat: inout [String: Double]) {
        if let dictionary = object as? [String: Any] {
            for (key, value) in dictionary {
                flatten(value, prefix: prefix.isEmpty ? key : "\(prefix).\(key)", into: &flat)
            }
        } else if let number = object as? NSNumber {
            flat[prefix] = number.doubleValue
        }
    }

    private static func insert(_ value: Double, at path: [String], into node: inout [String: Any]) {
        guard let head = path.first else { return }
        if path.count == 1 {
            node[head] = value
            return
        }
        var child = node[head] as? [String: Any] ?? [:]
        insert(value, at: Array(path.dropFirst()), into: &child)
        node[head] = child
    }
}

/// One value the founder changed.
public struct TuningChange: Codable, Hashable, Sendable, Identifiable {
    public var key: String
    public var defaultValue: Double
    public var value: Double

    public var id: String { key }

    public init(key: String, defaultValue: Double, value: Double) {
        self.key = key
        self.defaultValue = defaultValue
        self.value = value
    }

    enum CodingKeys: String, CodingKey {
        case key
        case defaultValue = "default"
        case value
    }
}
