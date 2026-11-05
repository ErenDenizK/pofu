#if canImport(SwiftUI)
import PofuDesignSystem
import SwiftUI

/// Pofu, alive: an illustrated companion animated procedurally.
///
/// One still image becomes a living character through layered motion:
/// ground-anchored breathing, idle sway, blinks and expressions revealed
/// from a lid plate, tap squish on springs, a celebratory double hop, and,
/// through a Metal distortion shader, cheek pouches that fill with energy,
/// tuft follow-through, and fur that ripples. Vitality drains color and
/// slumps the posture continuously; no extra frames are needed for it.
///
/// See `docs/design/companion-motion.md`.
public struct CompanionView: View {
    /// Wellbeing in `0...1` (PofuCore's `VitalityModel`).
    public var vitality: Double
    /// Stored energy in `0...1`, shown as cheek-pouch fill.
    public var energy: Double
    /// Increment to celebrate (hop) once.
    public var celebrations: Int
    public var art: CompanionArt?
    /// Called after Pofu's own squish when the user taps it (or activates
    /// it with an assistive technology), for screens where a tap means
    /// something, such as collecting seeds.
    public var onTap: (@MainActor () -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.companionBlinks) private var blinks
    @Environment(\.companionLife) private var life
    @State private var driver = CompanionDriver()
    @State private var taps = 0

    public init(
        vitality: Double,
        energy: Double = 0.25,
        celebrations: Int = 0,
        art: CompanionArt? = .placeholder,
        onTap: (@MainActor () -> Void)? = nil
    ) {
        self.vitality = vitality
        self.energy = energy
        self.celebrations = celebrations
        self.art = art
        self.onTap = onTap
    }

    /// The empty room above the art at rest, in points, for a companion
    /// laid out `width` wide. Hops use it; layouts can tuck a speech
    /// bubble's tail into it so the tail meets Pofu's head.
    public nonisolated static func restingHeadroom(forWidth width: CGFloat, art: CompanionArt? = .placeholder) -> CGFloat {
        guard let art else { return 0 }
        return CGFloat(CompanionStageLayout(width: Double(width), rig: art.rig).artOriginY)
    }

    public var body: some View {
        Group {
            if let art {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    CompanionStage(
                        art: art,
                        pose: driver.pose(
                            at: context.date,
                            vitality: vitality,
                            energy: energy,
                            reduceMotion: reduceMotion,
                            blinks: blinks,
                            life: life
                        )
                    )
                }
                .aspectRatio(CompanionStage.aspectRatio(for: art.rig), contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            driver.tap()
            taps += 1
            onTap?()
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: taps)
        .onChange(of: celebrations) {
            driver.celebrate()
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "Pofu"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            driver.tap()
            taps += 1
            onTap?()
        }
    }
}

extension EnvironmentValues {
    /// Whether Pofu blinks on his own. Screenshot rendering turns it off
    /// so a frame never catches him mid-blink.
    @Entry public var companionBlinks: Bool = true
    /// How Pofu breathes and blinks; the tuning lab panel sets it live.
    @Entry public var companionLife: CompanionLife = .standard
}

/// Owns the motion simulation across view updates and advances it with
/// the display clock. Deliberately not observable: the timeline redraws
/// every frame anyway, and mutating it while rendering must not schedule
/// extra view updates.
@MainActor
final class CompanionDriver {
    private var motion = CompanionMotion()
    private var lastDate: Date?

    func pose(at date: Date, vitality: Double, energy: Double, reduceMotion: Bool, blinks: Bool = true, life: CompanionLife = .standard) -> CompanionPose {
        if lastDate == nil {
            // Start settled at the given state, without a gulp or a slow
            // fade-in on first appearance.
            motion = CompanionMotion(vitality: vitality, energy: energy)
        }
        let elapsed = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        motion.reduceMotion = reduceMotion
        motion.blinks = blinks
        motion.life = life
        motion.vitality = vitality
        motion.energy = energy
        motion.step(elapsed)
        return motion.pose
    }

    func tap() {
        motion.tap()
    }

    func celebrate() {
        motion.celebrate()
    }
}

/// Lays out the figure on its stage: headroom for hops, a contact shadow,
/// and the transforms that keep the feet planted.
struct CompanionStage: View {
    let art: CompanionArt
    let pose: CompanionPose

    static func aspectRatio(for rig: CompanionRig) -> Double {
        CompanionStageLayout.aspectRatio(for: rig)
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = CompanionStageLayout(width: Double(proxy.size.width), rig: art.rig)
            let artSize = CGSize(width: layout.artWidth, height: layout.artHeight)

            ZStack(alignment: .topLeading) {
                ContactShadow(pose: pose, artWidth: layout.artWidth)
                    .position(x: layout.groundX, y: layout.groundY + layout.artHeight * 0.006)

                CompanionFigure(art: art, pose: pose, size: artSize)
                    .padding(layout.padding)
                    .distortionEffect(
                        CompanionShaders.deform(pose: pose, rig: art.rig, artRect: layout.artRectInPaddedFigure),
                        maxSampleOffset: CGSize(width: layout.padding, height: layout.padding),
                        isEnabled: CompanionShaders.isAvailable
                    )
                    .saturation(pose.saturation)
                    .brightness(pose.brightness)
                    .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: layout.groundAnchor)
                    .transformEffect(Self.lean(pose.lean, groundY: layout.groundYInPaddedFigure))
                    .offset(y: -pose.hop * layout.artHeight)
                    .position(layout.figureCenter)
            }
        }
    }

    /// A shear that keeps the ground line fixed and moves the top by
    /// `lean` times the height: a soft body bending, not a rigid tilt.
    static func lean(_ lean: Double, groundY: Double) -> CGAffineTransform {
        CGAffineTransform(a: 1, b: 0, c: -lean, d: 1, tx: lean * groundY, ty: 0)
    }
}

/// Stage geometry in points, all in `Double` so it is easy to test and
/// free of CGFloat conversions in view code.
struct CompanionStageLayout: Hashable, Sendable {
    /// Headroom above the art (for hops) and floor room below (for the
    /// shadow), as fractions of the art height; side margins as a fraction
    /// of its width.
    static let headroom = 0.24
    static let floorRoom = 0.06
    static let sideMargin = 0.1

    static func aspectRatio(for rig: CompanionRig) -> Double {
        rig.aspectRatio * (1 + 2 * sideMargin) / (1 + headroom + floorRoom)
    }

    let artWidth: Double
    let artHeight: Double
    let artOriginX: Double
    let artOriginY: Double
    let groundX: Double
    let groundY: Double
    /// Transparent margin around the figure, so the distortion shader can
    /// push the silhouette outward without clipping.
    let padding: Double
    let groundAnchorX: Double
    let groundAnchorY: Double

    init(width: Double, rig: CompanionRig) {
        let safeWidth = width.isFinite ? max(width, 0) : 0
        artWidth = safeWidth / (1 + 2 * Self.sideMargin)
        artHeight = artWidth / rig.aspectRatio
        artOriginX = artWidth * Self.sideMargin
        artOriginY = artHeight * Self.headroom
        groundX = artOriginX + rig.ground.x * artWidth
        groundY = artOriginY + rig.ground.y * artHeight
        padding = artWidth * 0.1
        let paddedWidth = artWidth + 2 * padding
        let paddedHeight = artHeight + 2 * padding
        groundAnchorX = paddedWidth > 0 ? (padding + rig.ground.x * artWidth) / paddedWidth : 0.5
        groundAnchorY = paddedHeight > 0 ? (padding + rig.ground.y * artHeight) / paddedHeight : 1
    }

    /// The scale anchor: the feet, in the padded figure's unit space.
    var groundAnchor: UnitPoint {
        UnitPoint(x: groundAnchorX, y: groundAnchorY)
    }

    var groundYInPaddedFigure: Double {
        padding + (groundY - artOriginY)
    }

    var artRectInPaddedFigure: CGRect {
        CGRect(x: padding, y: padding, width: artWidth, height: artHeight)
    }

    var figureCenter: CGPoint {
        CGPoint(x: artOriginX + artWidth / 2, y: artOriginY + artHeight / 2)
    }
}

/// The soft floor shadow; it shrinks and fades as Pofu leaves the ground.
private struct ContactShadow: View {
    let pose: CompanionPose
    let artWidth: Double

    var body: some View {
        let lift = pose.shadowScale
        let alpha = 0.2 * (0.35 + 0.65 * lift)
        let width = artWidth * 0.78 * pose.scaleX * (0.55 + 0.45 * lift) * 1.08
        let height = artWidth * 0.07 * (0.6 + 0.4 * lift) * 1.2
        let ink = Color(red: 0.55, green: 0.32, blue: 0.25)
        // A radial gradient squashed to an ellipse: the soft edge without
        // a blur pass every frame.
        Circle()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: ink.opacity(alpha), location: 0),
                        .init(color: ink.opacity(alpha * 0.8), location: 0.55),
                        .init(color: ink.opacity(0), location: 1),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: width / 2
                )
            )
            .frame(width: width, height: width)
            .scaleEffect(y: height / max(width, 1))
            .frame(width: width, height: height)
    }
}

/// The art at rest size with its in-place overlays: lids, blush, and
/// (without the shader) an approximate cheek bulge.
private struct CompanionFigure: View {
    let art: CompanionArt
    let pose: CompanionPose
    let size: CGSize

    var body: some View {
        let rig = art.rig
        ZStack(alignment: .topLeading) {
            Image(decorative: art.base, scale: 1)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)

            if !CompanionShaders.isAvailable {
                FallbackCheek(art: art, center: rig.leftCheek, pose: pose, size: size)
                FallbackCheek(art: art, center: rig.rightCheek, pose: pose, size: size)
            }

            BlushLayer(rig: rig, intensity: pose.blush, size: size)

            if let plate = art.lidPlate {
                Image(decorative: plate, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .frame(
                        width: rig.lidPlateSize.x * size.width,
                        height: rig.lidPlateSize.y * size.height
                    )
                    .offset(
                        x: rig.lidPlateOrigin.x * size.width,
                        y: rig.lidPlateOrigin.y * size.height
                    )
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .mask {
                        LidShape(rig: rig, pose: pose)
                    }
            }

            LashShape(rig: rig, pose: pose)
                .stroke(
                    Color(red: 0.24, green: 0.15, blue: 0.13)
                        .opacity(0.9 * smoothstep(0.1, 0.4, pose.lidClosure) * (1 - pose.happiness)),
                    style: StrokeStyle(lineWidth: rig.leftEye.radiusY * size.height * 0.16, lineCap: .round)
                )
        }
        .frame(width: size.width, height: size.height)
    }
}

/// Fallback for builds without the compiled Metal library: a magnified,
/// radially masked copy of the art over each cheek. Close to the shader's
/// bulge in the face, but it cannot push the silhouette outward.
private struct FallbackCheek: View {
    let art: CompanionArt
    let center: CompanionRig.Point
    let pose: CompanionPose
    let size: CGSize

    var body: some View {
        let radius = art.rig.cheekRadius * size.width
        let anchor = UnitPoint(x: center.x, y: center.y)
        Image(decorative: art.base, scale: 1)
            .resizable()
            .frame(width: size.width, height: size.height)
            .scaleEffect(1 + CompanionShaders.inflation(cheekPuff: pose.cheekPuff) * 0.4, anchor: anchor)
            .mask {
                RadialGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.3),
                        .init(color: .clear, location: 1),
                    ],
                    center: anchor,
                    startRadius: 0,
                    endRadius: radius
                )
            }
    }
}

private struct BlushLayer: View {
    let rig: CompanionRig
    let intensity: Double
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            blush(rig.leftBlush)
            blush(rig.rightBlush)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func blush(_ ellipse: CompanionRig.Ellipse) -> some View {
        let width = ellipse.radiusX * size.width * 3
        let height = ellipse.radiusY * size.height * 3
        return Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 1, green: 0.62, blue: 0.66).opacity(0.42 * intensity),
                        Color(red: 1, green: 0.62, blue: 0.66).opacity(0),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: width / 2
                )
            )
            .frame(width: width, height: height)
            .offset(
                x: ellipse.center.x * size.width - width / 2,
                y: ellipse.center.y * size.height - height / 2
            )
    }
}

/// The lid regions of both eyes (what the lid plate shows through).
struct LidShape: Shape {
    let rig: CompanionRig
    let pose: CompanionPose

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (eye, side) in [(rig.leftEye, -1.0), (rig.rightEye, 1.0)] {
            let model = LidModel(
                closure: pose.lidClosure,
                happiness: pose.happiness,
                sadness: pose.sadness,
                outerSide: side
            )
            let map = EyeMapping(eye: eye, rect: rect)
            let xs = stride(from: -1.0, through: 1.0, by: 1.0 / 16).map { $0 }
            // Upper lid: from the rim down to the lid edge (or meeting line).
            var upper: [CGPoint] = xs.map { map.point($0, -LidModel.rim($0)) }
            upper += xs.reversed().map { x in
                let s = LidModel.rim(x)
                let edge = model.meeting(x) ?? min(max(model.upper(x), -s), s)
                return map.point(x, edge)
            }
            path.addLines(upper)
            path.closeSubpath()
            // Lower lid: from the lid edge (or meeting line) down to the rim.
            var lower: [CGPoint] = xs.map { x in
                let s = LidModel.rim(x)
                let edge = model.meeting(x) ?? min(max(model.lower(x), -s), s)
                return map.point(x, edge)
            }
            lower += xs.reversed().map { map.point($0, LidModel.rim($0)) }
            path.addLines(lower)
            path.closeSubpath()
        }
        return path
    }
}

/// The lash line along the upper lid's edge.
struct LashShape: Shape {
    let rig: CompanionRig
    let pose: CompanionPose

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard pose.lidClosure > 0.05 else { return path }
        for (eye, side) in [(rig.leftEye, -1.0), (rig.rightEye, 1.0)] {
            let model = LidModel(
                closure: pose.lidClosure,
                happiness: pose.happiness,
                sadness: pose.sadness,
                outerSide: side
            )
            let map = EyeMapping(eye: eye, rect: rect)
            let xs = stride(from: -0.92, through: 0.92, by: 0.92 / 12).map { $0 }
            path.addLines(xs.map { x in
                let s = LidModel.rim(x)
                return map.point(x, model.meeting(x) ?? min(max(model.upper(x), -s), s))
            })
        }
        return path
    }
}

/// Maps an eye's normalized coordinates to points in the art frame.
private struct EyeMapping {
    let eye: CompanionRig.Ellipse
    let rect: CGRect

    func point(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(
            x: rect.minX + (eye.center.x + x * eye.radiusX) * rect.width,
            y: rect.minY + (eye.center.y + y * eye.radiusY) * rect.height
        )
    }
}

#Preview("Interactive") {
    @Previewable @State var vitality = 0.8
    @Previewable @State var energy = 0.25
    @Previewable @State var celebrations = 0
    VStack(spacing: PofuSpacing.l) {
        CompanionView(vitality: vitality, energy: energy, celebrations: celebrations)
            .frame(maxWidth: 320)
        Slider(value: $energy) { Text(verbatim: "Energy") }
        Slider(value: $vitality) { Text(verbatim: "Vitality") }
        Button {
            celebrations += 1
        } label: {
            Text(verbatim: "Celebrate")
        }
        .buttonStyle(.borderedProminent)
    }
    .padding(PofuSpacing.xl)
    .background(Color(red: 0.99, green: 0.93, blue: 0.9))
}

#Preview("Vitality range") {
    HStack(spacing: PofuSpacing.s) {
        ForEach([1.0, 0.6, 0.3, 0.05], id: \.self) { value in
            CompanionView(vitality: value, energy: value)
        }
    }
    .padding(PofuSpacing.l)
    .background(Color(red: 0.99, green: 0.93, blue: 0.9))
}
#endif
