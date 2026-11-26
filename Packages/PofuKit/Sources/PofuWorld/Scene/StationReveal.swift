import Foundation
import PofuCore

/// The station level-up reveal (world presentation v2 §9.2) for a station that stands as a look over an erased base
/// (`PlateCompositor`), as a pure function of the build moment's time (`BuildMoment`, `reveal`):
///
/// - the sheet drops and the camera goes to the station's focus shot (0.5 s);
/// - the old look dips 4 % at its foot (0.25 s), with the build's dust;
/// - the new look opens through a ring growing from its foot (0.7 s, a soft 10 pt edge with a honey rim), `level-up`
///   at the ring's start;
/// - the new look settles from 1.06 to 1 (0.35 s); its contact shade, baked under it, cross-fades with it;
/// - the tag and the seeds; the resident hops 0.9 s after the ring starts; camera and focus return. At most 3.2 s.
///
/// Reduce Motion: a 0.4 s cross-fade, nothing moves.
public struct StationReveal: Hashable, Sendable {
    public static let focusLength = 0.5
    public static let dipLength = 0.25
    public static let dipDepth = 0.04
    public static let ringLength = 0.7
    /// The ring's soft edge, in points.
    public static let ringEdge = 10.0
    public static let settleFrom = 1.06
    public static let settleLength = 0.35
    public static let residentHopDelay = 0.9
    public static let reducedFade = 0.4

    public let moment: BuildMoment

    /// The reveal of `moment`, or `nil` when the moment is not a look's reveal.
    public init?(_ moment: BuildMoment) {
        guard moment.reveal else { return nil }
        self.moment = moment
    }

    /// When the ring starts: the moment's swap.
    public var ringStart: Double {
        moment.time(of: .swap) ?? 0
    }

    private var dipStart: Double {
        moment.time(of: .anticipation) ?? ringStart
    }

    /// When the new look has settled; after it the plain look draws.
    public var end: Double {
        moment.reduceMotion ? ringStart + Self.reducedFade : ringStart + Self.ringLength + Self.settleLength
    }

    /// The ring's ease: it opens quickly from the foot and slows as it reaches the roof.
    public static func ringCurve(_ p: Double) -> Double {
        MomentCurves.easeOut(MomentCurves.unit(p))
    }

    /// The old look's height about its foot, 1 to 0.96 through the dip, held while the ring opens.
    public func oldScaleY(at t: Double) -> Double {
        guard !moment.reduceMotion else { return 1 }
        let p = MomentCurves.smoothstep(MomentCurves.progress(t, from: dipStart, length: Self.dipLength))
        return 1 - Self.dipDepth * p
    }

    /// How far the ring has opened, 0 to 1 (`nil` before it starts, or with Reduce Motion).
    public func ring(at t: Double) -> Double? {
        guard !moment.reduceMotion, t >= ringStart else { return nil }
        return Self.ringCurve(MomentCurves.progress(t, from: ringStart, length: Self.ringLength))
    }

    /// The new look's scale about its foot: 1.06 while the ring opens, then settling to 1.
    public func newScale(at t: Double) -> Double {
        guard !moment.reduceMotion else { return 1 }
        let settle = MomentCurves.easeOut(MomentCurves.progress(t, from: ringStart + Self.ringLength, length: Self.settleLength))
        return Self.settleFrom + (1 - Self.settleFrom) * settle
    }

    /// The new look's opacity: whole under the ring's mask, or the Reduce Motion cross-fade.
    public func newOpacity(at t: Double) -> Double {
        if moment.reduceMotion { return MomentCurves.progress(t, from: ringStart, length: Self.reducedFade) }
        return t >= ringStart ? 1 : 0
    }

    /// The old look's opacity: whole until the ring has covered it, or the Reduce Motion cross-fade.
    public func oldOpacity(at t: Double) -> Double {
        if moment.reduceMotion { return 1 - newOpacity(at: t) }
        return (ring(at: t) ?? 0) < 1 ? 1 : 0
    }

    /// The honey rim's strength on the ring's edge, 0 to 1: full while it opens, gone as it reaches the roof.
    public func rim(at t: Double) -> Double {
        guard let p = ring(at: t), p > 0 else { return 0 }
        let u = MomentCurves.progress(t, from: ringStart, length: Self.ringLength)
        return u < 0.7 ? 1 : 1 - MomentCurves.smoothstep((u - 0.7) / 0.3)
    }

    /// Whether the reveal draws the station at `t` (from the tap through the settle).
    public func isActive(at t: Double) -> Bool {
        t >= 0 && t < end
    }
}

#if os(iOS)
import SwiftUI

/// One station's look on the plate: the look for its level, or, during its build, the v2 §9.2 reveal from the old
/// look to the new one (`StationReveal`). The one path a look is drawn by: in the composite, over a character behind
/// it, and in the far picture (without a build). A level change outside a build cross-fades in 0.4 s.
struct PlateLookPiece: View {
    let compositor: PlateCompositor
    let station: String
    let build: BuildFrame?
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    var body: some View {
        let id = StationID(rawValue: station)
        let level = compositor.levels[id] ?? 0
        if let build, build.moment.station == id, let reveal = StationReveal(build.moment), reveal.isActive(at: build.time) {
            RevealedLook(
                old: compositor.look(station, level: build.moment.fromLevel),
                new: compositor.look(station, level: build.moment.toLevel),
                reveal: reveal, t: build.time, pose: pose, size: size, offset: offset
            )
        } else {
            SettledLook(look: compositor.look(station, level: level), pose: pose, size: size, offset: offset)
        }
    }
}

/// A look at rest; a new asset cross-fades in 0.4 s (also the Reduce Motion form of a reveal).
private struct SettledLook: View {
    let look: PlateCompositor.Look?
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let look {
                PlateImage(name: look.art, box: look.box, pose: pose, size: size, offset: offset, grade: look.grade)
                    .id(look.art)
                    .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(.easeInOut(duration: StationReveal.reducedFade), value: look?.art)
    }
}

/// The reveal at one instant: the old look dipping at its foot, the new one opening through a ring from the foot
/// with a honey rim, then settling from 1.06.
private struct RevealedLook: View {
    let old: PlateCompositor.Look?
    let new: PlateCompositor.Look?
    let reveal: StationReveal
    let t: Double
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    /// The ring's rim: the plate's warm honey.
    static let honey = Color(red: 1.0, green: 0.80, blue: 0.42)

    var body: some View {
        let w = Double(size.width)
        ZStack(alignment: .topLeading) {
            if let old {
                let foot = anchor(old.foot, w: w)
                PlateImage(name: old.art, box: old.box, pose: pose, size: size, offset: offset, grade: old.grade)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .scaleEffect(x: 1, y: reveal.oldScaleY(at: t), anchor: foot)
                    .opacity(reveal.oldOpacity(at: t))
            }
            if let new {
                let foot = anchor(new.foot, w: w)
                let image = PlateImage(name: new.art, box: new.box, pose: pose, size: size, offset: offset, grade: new.grade)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                if let p = reveal.ring(at: t) {
                    let r = radius(new, progress: p, w: w)
                    ZStack(alignment: .topLeading) {
                        image.mask { ring(foot: foot, radius: r, band: false) }
                        // The honey rim: the new look's own silhouette in honey, only on the ring's edge.
                        PlateImage(name: new.art, box: new.box, pose: pose, size: size, offset: offset, template: Self.honey)
                            .frame(width: size.width, height: size.height, alignment: .topLeading)
                            .mask { ring(foot: foot, radius: r, band: true) }
                            .opacity(0.85 * reveal.rim(at: t))
                            .blendMode(.screen)
                    }
                    .scaleEffect(reveal.newScale(at: t), anchor: foot)
                } else {
                    image.opacity(reveal.newOpacity(at: t))
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func anchor(_ p: WorldPoint, w: Double) -> UnitPoint {
        let a = pose.project(p, width: w)
        return UnitPoint(x: (a.x + offset.width) / max(size.width, 1), y: (a.y + offset.height) / max(size.height, 1))
    }

    /// The ring's radius in points: from nothing to past the farthest corner of the look's canvas (and its edge).
    private func radius(_ look: PlateCompositor.Look, progress p: Double, w: Double) -> Double {
        let f = pose.project(look.foot, width: w)
        let a = pose.project(WorldPoint(x: look.box.minX, y: look.box.minY), width: w)
        let b = pose.project(WorldPoint(x: look.box.maxX, y: look.box.maxY), width: w)
        let corners = [(a.x, a.y), (b.x, b.y), (a.x, b.y), (b.x, a.y)]
        let far = corners.map { hypot($0.0 - f.x, $0.1 - f.y) }.max() ?? 0
        return p * (far * StationReveal.settleFrom + 2 * StationReveal.ringEdge)
    }

    /// The ring's mask: solid inside, a soft 10 pt edge (or, for the rim, only that edge).
    private func ring(foot: UnitPoint, radius r: Double, band: Bool) -> some View {
        let edge = StationReveal.ringEdge
        let r = max(r, 0.5)
        let inner = max(r - edge, 0) / r
        let stops: [Gradient.Stop] = band
            ? [.init(color: .clear, location: max(r - 2.2 * edge, 0) / r), .init(color: .black, location: inner + 0.5 * (1 - inner)), .init(color: .clear, location: 1)]
            : [.init(color: .black, location: inner), .init(color: .clear, location: 1)]
        return RadialGradient(stops: stops, center: foot, startRadius: 0, endRadius: CGFloat(r))
            .frame(width: size.width, height: size.height)
    }
}
#endif
