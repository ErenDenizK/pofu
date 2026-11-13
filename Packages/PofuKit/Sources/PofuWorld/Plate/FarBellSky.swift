import Foundation
import PofuCore

/// The far bell's notes in the sky (docs/design/days-17-21-v1.md, PR 2):
/// one warm light among the painted stars on the nights of the road, a
/// little stronger each night, and a soft ring of light for each note that
/// answers. Pure numbers here; the drawing is `FarBellSkyLayer`.
public enum FarBellSky {
    /// The far light, in plate pixels (1024 x 1536): clear sky right of the
    /// dome isle and over the whale's lane on every night plate.
    public static let light = PlatePoint(x: 718, y: 208)
    /// Plate pixels over Pofu's feet where his hummed notes ring.
    public static let humLift = 96.0
    /// How long a note's ring lives, in seconds.
    public static let ringLife = 1.1

    /// The light's strength: 0.35, 0.5, 0.65, 0.8 for steps 1 to 4, 1.0 on
    /// the bell's day, else `nil` (no light).
    public static func glow(step: Int?, bellDay: Bool) -> Double? {
        if bellDay { return 1.0 }
        guard let step, (1...FarBellPrelude.steps).contains(step) else { return nil }
        return 0.35 + 0.15 * Double(step - 1)
    }

    /// The glow the world's snapshot holds.
    public static func glow(in world: WorldSnapshot) -> Double? {
        glow(step: FarBellPrelude.step(in: world), bellDay: FarBellPrelude.isBellDay(in: world))
    }

    /// A note's ring `age` seconds into the tune, in points at the reference
    /// width, or `nil` before the note, after its life, or under Reduce Motion.
    public static func ring(note: FarBellTune.Note, age: Double, reduceMotion: Bool) -> (radius: Double, opacity: Double)? {
        guard !reduceMotion, age >= note.at, age <= note.at + ringLife else { return nil }
        let p = (age - note.at) / ringLife
        let (from, to) = note.isFar ? (5.0, 34.0) : (4.0, 16.0)
        return (from + (to - from) * MomentCurves.easeOut(p), 0.6 * (1 - MomentCurves.smoothstep(p)))
    }
}

#if os(iOS)
import SwiftUI

/// The light and the rings over the painted plate. Drops out cleanly: with no
/// step, no bell day and no tune it draws nothing.
struct FarBellSkyLayer: View {
    let plate: HomePlate
    let world: WorldSnapshot
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.worldStillFrame) private var still

    private static let halo = Color(red: 1, green: 0.82, blue: 0.5)
    private static let core = Color(red: 1, green: 0.84, blue: 0.59)

    private func point(_ p: PlatePoint) -> CGPoint {
        let a = pose.project(plate.world(p), width: Double(size.width))
        return CGPoint(x: a.x + Double(offset.width), y: a.y + Double(offset.height))
    }

    var body: some View {
        let k = Double(size.width) / CameraRail.referenceWidth
        let stage = FarBellStage.shared
        ZStack(alignment: .topLeading) {
            if plate.light == "night", let glow = FarBellSky.glow(in: world) {
                let c = point(FarBellSky.light)
                let r = 8 * k
                // Source-over, not additive: added to the blue sky amber turns white.
                Canvas { context, _ in
                    context.fill(
                        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: Self.halo.opacity(0.30 * glow), location: 0),
                                .init(color: Self.halo.opacity(0.14 * glow), location: 0.25),
                                .init(color: Self.halo.opacity(0.065 * glow), location: 0.5),
                                .init(color: Self.halo.opacity(0.017 * glow), location: 0.75),
                                .init(color: Self.halo.opacity(0), location: 1),
                            ]),
                            center: c, startRadius: 0, endRadius: r
                        )
                    )
                    let cr = 1.6 * k
                    context.fill(
                        Path(ellipseIn: CGRect(x: c.x - cr, y: c.y - cr, width: cr * 2, height: cr * 2)),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: Self.core.opacity(glow), location: 0),
                                .init(color: Self.core.opacity(0.71 * glow), location: 0.25),
                                .init(color: Self.core.opacity(0.43 * glow), location: 0.5),
                                .init(color: Self.core.opacity(0.19 * glow), location: 0.75),
                                .init(color: Self.core.opacity(0), location: 1),
                            ]),
                            center: c, startRadius: 0, endRadius: cr
                        )
                    )
                }
                .allowsHitTesting(false)
            }
            if stage.age(at: Date()) != nil {
                TimelineView(.animation(paused: stage.frozenAge != nil || still)) { timeline in
                    rings(age: stage.age(at: timeline.date), k: k, stage: stage)
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func rings(age: Double?, k: Double, stage: FarBellStage) -> some View {
        let colour = Self.halo
        let hum = PlatePoint(
            x: (plate.plate.characters["pofu"]?.x ?? FarBellSky.light.x),
            y: (plate.plate.characters["pofu"]?.y ?? FarBellSky.light.y) - FarBellSky.humLift
        )
        return Canvas { context, _ in
            guard let age else { return }
            for note in stage.notes {
                guard let ring = FarBellSky.ring(note: note, age: age, reduceMotion: reduceMotion) else { continue }
                let c = point(note.isFar ? FarBellSky.light : hum)
                let r = ring.radius * k
                // A warm breath of light, never a drawn line: no inner edge
                // (it rises from the centre on a smooth curve), a wide peak
                // toward the rim, then gone.
                let peak = ring.opacity * 0.30
                let stops: [Gradient.Stop] = [0.0, 0.2, 0.4, 0.55, 0.7, 0.82, 0.92, 1.0].map { t in
                    let up = t < 0.75 ? MomentCurves.smoothstep(t / 0.75) : 1 - MomentCurves.smoothstep((t - 0.75) / 0.25)
                    return .init(color: colour.opacity(peak * up), location: t)
                }
                context.fill(
                    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                    with: .radialGradient(Gradient(stops: stops), center: c, startRadius: 0, endRadius: r)
                )
            }
        }
        .allowsHitTesting(false)
    }
}
#endif
