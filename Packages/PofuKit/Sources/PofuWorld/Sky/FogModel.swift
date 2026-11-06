import Foundation
import PofuDesignSystem

/// How deep a layer sits in the air (sky and weather v1 §2.3).
public enum FogTier: Int, CaseIterable, Hashable, Sendable {
    /// The island in front: always clear.
    case front
    case mid
    case far
    case farthest
}

/// Real fog, part one: depth fog. Every layer is mixed toward the current
/// horizon colour (never grey) by its tier's amount, and shadows mix more
/// than lights, so contrast collapses with distance the way air does. The
/// numbers live in `LookTuning`. Pure, so it is tested on any platform.
public enum FogModel {
    /// A tier's fog, 0…1. `mist` (0…1) adds `LookTuning.fogMistExtra` to
    /// every tier behind the front one; the island in front stays clear, so
    /// its top is always readable.
    public static func amount(tier: FogTier, mist: Double = 0) -> Double {
        let base = LookTuning.fogTiers[tier.rawValue]
        guard tier != .front else { return base }
        return min(base + LookTuning.fogMistExtra * unit(mist), LookTuning.fogMaximum)
    }

    /// The fog at a continuous distance (0 front, 1 farthest), interpolated
    /// between the tiers' distances.
    public static func amount(distance: Double, mist: Double = 0) -> Double {
        let stops = LookTuning.fogTierDistances
        let d = min(max(distance.isFinite ? distance : 1, 0), 1)
        var upper = stops.count - 1
        for (index, stop) in stops.enumerated() where d <= stop {
            upper = index
            break
        }
        let lower = max(upper - 1, 0)
        let span = stops[upper] - stops[lower]
        let t = span > 0 ? (d - stops[lower]) / span : 1
        let a = amount(tier: FogTier(rawValue: lower) ?? .front, mist: mist)
        let b = amount(tier: FogTier(rawValue: upper) ?? .farthest, mist: mist)
        return a + (b - a) * t
    }

    /// What a shadow takes: 1.25x a light's amount.
    public static func shadowAmount(_ lightAmount: Double) -> Double {
        min(lightAmount * LookTuning.fogShadowFactor, LookTuning.fogMaximum)
    }

    /// The fog's colour: the sky's current horizon, never a grey. A horizon
    /// that has lost its hue (a washed-out overcast one) is pulled toward a
    /// soft blue instead of going neutral.
    public static func colour(horizon: PofuRGB) -> PofuRGB {
        let top = max(horizon.red, horizon.green, horizon.blue)
        let bottom = min(horizon.red, horizon.green, horizon.blue)
        guard top - bottom < minimumChroma else { return horizon }
        return horizon.mixed(with: PofuRGB(hex: 0xB8C8E8), amount: 0.35)
    }

    /// The least spread between a fog colour's channels.
    public static let minimumChroma = 0.02

    /// `colour` mixed toward the horizon's fog by `amount`.
    public static func fogged(_ colour: PofuRGB, horizon: PofuRGB, amount: Double) -> PofuRGB {
        colour.mixed(with: Self.colour(horizon: horizon), amount: amount)
    }

    /// A light (a lit colour) and a shadow through the same tier: the
    /// shadow takes 1.25x the fog.
    public static func fogged(light: PofuRGB, shadow: PofuRGB, horizon: PofuRGB, amount: Double) -> (light: PofuRGB, shadow: PofuRGB) {
        (
            fogged(light, horizon: horizon, amount: amount),
            fogged(shadow, horizon: horizon, amount: shadowAmount(amount))
        )
    }

    /// The peak opacity of the height fog cards: low in clear weather,
    /// higher in mist (`mist` 0…1 is SW-2's to set).
    public static func cardOpacity(mist: Double) -> Double {
        let t = unit(mist)
        return LookTuning.fogCardClearOpacity + (LookTuning.fogCardMistOpacity - LookTuning.fogCardClearOpacity) * t
    }

    private static func unit(_ x: Double) -> Double {
        min(max(x.isFinite ? x : 0, 0), 1)
    }
}

/// Real fog, part two: the height fog cards (§2.3), where they sit and how
/// they drift. Two to four soft shapes, densest at the cloud-sea line; some
/// behind the island, one in front of its base, so the foot dissolves and
/// the top stays clear.
public enum FogCardLayout {
    public enum Layer: Hashable, Sendable {
        case behind
        case front
    }

    public struct Card: Hashable, Sendable, Identifiable {
        public var id: Int
        public var layer: Layer
        /// The art index: `world-fog-card-<art>` replaces the code card.
        public var art: Int
        /// Drift as a multiple of `LookTuning.fogCardDrift`.
        public var speed: Double
        /// Width in screens, and where its centre sits against the cloud-sea
        /// line (points, up negative).
        public var width: Double
        public var yOffset: Double
        /// Its share of the peak opacity, and where it starts (0…1).
        public var strength: Double
        public var phase: Double
        /// How much the camera's peek moves it.
        public var parallax: Double
    }

    public static let cards: [Card] = [
        Card(id: 0, layer: .behind, art: 1, speed: 1, width: 1.3, yOffset: -58, strength: 0.7, phase: 0.15, parallax: 0.5),
        Card(id: 1, layer: .behind, art: 2, speed: 2, width: 1.1, yOffset: -14, strength: 0.9, phase: 0.62, parallax: 0.8),
        Card(id: 2, layer: .behind, art: 3, speed: 2, width: 0.9, yOffset: -92, strength: 0.45, phase: 0.95, parallax: 0.6),
        Card(id: 3, layer: .front, art: 1, speed: 3.5, width: 1.2, yOffset: 70, strength: 1, phase: 0.4, parallax: 1.2),
    ]

    /// The name the painted card art takes when it lands (batch 44).
    public static func artName(_ art: Int) -> String {
        "world-fog-card-\(art)"
    }

    /// The card's left edge at `time`, in points: it wraps across a strip
    /// one screen wide plus its own width.
    public static func x(of card: Card, time: Double, screenWidth: Double) -> Double {
        let width = card.width * screenWidth
        return SkyModel.cloudX(
            time: time, speed: LookTuning.fogCardDrift * card.speed,
            phase: card.phase * (screenWidth + width), width: width, span: screenWidth
        )
    }
}
