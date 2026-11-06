import Foundation
import PofuCore

/// A character's shadow at night, cast away from the strongest light source
/// in reach (light and shadow v2, §4). Quantised the way the bake's key is
/// (3° steps, 0.1 length, 0.02 opacity), so a flickering strength never
/// rebuilds the shadow layer. Pure and tested; `ShadowBake` draws it.
public struct SourceShadow: Hashable, Sendable {
    /// The direction away from the source, in `ShadowTuning.angleStep` degrees.
    public var angle: Int
    /// The length (× the object's height) in `ShadowTuning.lengthStep`.
    public var length: Int
    /// The opacity in `ShadowTuning.opacityStep`.
    public var opacity: Int

    /// The shadow a character receives from `sample`, or nil when no source
    /// reaches it (the faint moon shadow stays).
    public static func make(sample: LightSample) -> SourceShadow? {
        guard sample.sourceID != nil, sample.strength >= ShadowTuning.sourceMinimumStrength else { return nil }
        let k = min(sample.strength, 1)
        // Away from the source, on the ground.
        let degrees = atan2(-sample.directionY, -sample.directionX) * 180 / .pi
        let length = ShadowTuning.sourceLengthWeak + (ShadowTuning.sourceLengthStrong - ShadowTuning.sourceLengthWeak) * k
        return SourceShadow(
            angle: Int((degrees / ShadowTuning.angleStep).rounded()),
            length: Int((length / ShadowTuning.lengthStep).rounded()),
            opacity: Int((ShadowTuning.sourceOpacity * k / ShadowTuning.opacityStep).rounded())
        )
    }

    /// Pofu's and the residents' shadows from `field`, by caster id
    /// (`ShadowCasters`: `pofu`, `resident-<id>`).
    public static func characters(field: LightField, world: WorldSnapshot) -> [String: SourceShadow] {
        var result: [String: SourceShadow] = [:]
        if let shadow = make(sample: field.sample(IslandLayout.pofu)) {
            result["pofu"] = shadow
        }
        let built = Set(world.stations.filter { $0.island == .home && $0.isOpen && $0.level > 0 }.map(\.id))
        for resident in IslandLayout.residents where built.contains(resident.station) {
            let feet = IslandFootprint.clamped(resident.feet, footprint: IslandFootprint.footprint(of: resident.art))
            if let shadow = make(sample: field.sample(feet)) {
                result["resident-\(resident.id.rawValue)"] = shadow
            }
        }
        return result
    }
}
