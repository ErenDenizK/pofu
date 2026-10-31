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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var driver = CompanionDriver()
    @State private var taps = 0

    public init(
        vitality: Double,
        energy: Double = 0.25,
        celebrations: Int = 0,
        art: CompanionArt? = .placeholder
    ) {
        self.vitality = vitality
        self.energy = energy
        self.celebrations = celebrations
        self.art = art
    }

    public var body: some View {
        Group {
            if let art {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                    CompanionStage(
                        art: art,
                        pose: driver.pose(
                            at: context.date,
                            vitality: vitality,
                            energy: energy,
                            reduceMotion: reduceMotion
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
        }
    }
}

/// Owns the motion simulation across view updates and advances it with
/// the display clock. Deliberately not observable: the timeline redraws
/// every frame anyway, and mutating it while rendering must not schedule
/// extra view updates.
@MainActor
final class CompanionDriver {
    private var motion = CompanionMotion()
    private var lastDate: Date?

    func pose(at date: Date, vitality: Double, energy: Double, reduceMotion: Bool) -> CompanionPose {
        if lastDate == nil {
            // Start settled at the given state, without a gulp or a slow
            // fade-in on first appearance.
            motion = CompanionMotion(vitality: vitality, energy: energy)
        }
        let elapsed = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        motion.reduceMotion = reduceMotion
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

    /// Headroom above the art (for hops) and floor room below (for the
    /// shadow), as fractions of the art height; side margins as a fraction
    /// of its width.
    static let headroom = 0.24
    static let floorRoom = 0.06
    static let sideMargin = 0.1

    static func aspectRatio(for rig: CompanionRig) -> Double {
        rig.aspectRatio * (1 + 2 * sideMargin) / (1 + headroom + floorRoom)
    }

    var body: some View {
        GeometryReader { proxy in
            let rig = art.rig
            let artWidth = proxy.size.width / (1 + 2 * Self.sideMargin)
            let artHeight = artWidth / rig.aspectRatio
            let artOrigin = CGPoint(x: artWidth * Self.sideMargin, y: artHeight * Self.headroom)
            let groundY = artOrigin.y + rig.ground.y * artHeight
            let groundX = artOrigin.x + rig.ground.x * artWidth
            let pad = artWidth * 0.1

            ZStack(alignment: .topLeading) {
                ContactShadow(pose: pose, artWidth: artWidth)
                    .position(x: groundX, y: groundY + artHeight * 0.006)

                CompanionFigure(art: art, pose: pose, size: CGSize(width: artWidth, height: artHeight))
                    .padding(pad)
                    .distortionEffect(
                        CompanionShaders.deform(
                            pose: pose,
                            rig: rig,
                            artRect: CGRect(x: pad, y: pad, width: artWidth, height: artHeight)
                        ),
                        maxSampleOffset: CGSize(width: pad, height: pad),
                        isEnabled: CompanionShaders.isAvailable
                    )
                    .saturation(pose.saturation)
                    .brightness(pose.brightness)
                    .scaleEffect(
                        x: pose.scaleX,
                        y: pose.scaleY,
                        anchor: UnitPoint(
                            x: (pad + rig.ground.x * artWidth) / (artWidth + 2 * pad),
                            y: (pad + rig.ground.y * artHeight) / (artHeight + 2 * pad)
                        )
                    )
                    .transformEffect(Self.lean(pose.lean, groundY: pad + rig.ground.y * artHeight))
                    .offset(y: -pose.hop * artHeight)
                    .position(x: artOrigin.x + artWidth / 2, y: artOrigin.y + artHeight / 2)
            }
        }
    }

    /// A shear that keeps the ground line fixed and moves the top by
    /// `lean` times the height: a soft body bending, not a rigid tilt.
    static func lean(_ lean: Double, groundY: Double) -> CGAffineTransform {
        CGAffineTransform(a: 1, b: 0, c: -lean, d: 1, tx: lean * groundY, ty: 0)
    }
}

/// The soft floor shadow; it shrinks and fades as Pofu leaves the ground.
private struct ContactShadow: View {
    let pose: CompanionPose
    let artWidth: Double

    var body: some View {
        let lift = pose.shadowScale
        Ellipse()
            .fill(Color(red: 0.55, green: 0.32, blue: 0.25).opacity(0.2 * (0.35 + 0.65 * lift)))
            .frame(
                width: artWidth * 0.78 * pose.scaleX * (0.55 + 0.45 * lift),
                height: artWidth * 0.07 * (0.6 + 0.4 * lift)
            )
            .blur(radius: artWidth * 0.025)
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
                    .mask(LidShape(rig: rig, pose: pose))
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
            .mask(
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
            )
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
