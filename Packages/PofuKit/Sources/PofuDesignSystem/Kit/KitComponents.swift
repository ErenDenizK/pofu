#if canImport(SwiftUI)
import SwiftUI

// Chip, toast, speech bubble and progress groove of the kit (UI v3
// section 5). All code-drawn; each has an art hook in `PofuKitArt`.

// MARK: - Chip

/// A felt chip: filters, reasons, the app chip. Selected = honey felt and
/// a stitched border. The visual is 32 pt; the hit target is 44.
public struct PofuChipStyle: ButtonStyle {
    public var isSelected: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    public func makeBody(configuration: Configuration) -> some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        let shape = Capsule(style: .continuous)
        let pressed = configuration.isPressed
        configuration.label
            .font(PofuFont.subheadline)
            .foregroundStyle(isSelected && palette.isNight ? palette.ink : palette.onPaper)
            .padding(.horizontal, PofuSpacing.m + 2)
            .padding(.vertical, PofuSpacing.xs + 2)
            .frame(minHeight: PofuSize.chipHeight)
            .background {
                PofuKitFace(isSelected ? .chipFeltSelected : .chipFelt) {
                    ZStack {
                        shape.fill(isSelected ? palette.feltSelected : palette.felt)
                        PofuGrainOverlay(opacity: 0.12)
                        shape.pofuInnerShadow(palette.edge.opacity(0.12), width: 3, blur: 2, y: 1)
                        if isSelected {
                            shape.inset(by: 3)
                                .stroke(palette.ink.opacity(0.55), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 3]))
                        }
                        if resolver.isHighContrast {
                            shape.strokeBorder(palette.onPaper, lineWidth: 2)
                        }
                    }
                    .clipShape(shape)
                }
                .brightness(pressed ? -0.06 : 0)
            }
            .frame(minHeight: PofuSize.minimumTouch)
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.55)
            .scaleEffect(pressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? PofuMotion.reduced : PofuMotion.squish, value: pressed)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Toast

/// A paper strip with a stitched edge, turned a degree, for a short line.
public struct PofuToast: View {
    let text: LocalizedStringKey
    let systemImage: String?

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init(_ text: LocalizedStringKey, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }

    public var body: some View {
        let palette = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast).palette
        HStack(spacing: PofuSpacing.s) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(PofuFont.headline)
                    .foregroundStyle(palette.isNight ? palette.honey : palette.honeyBottom)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(PofuFont.subheadline)
                .foregroundStyle(palette.onPaper)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PofuSpacing.l)
        .padding(.vertical, PofuSpacing.m)
        .frame(minHeight: PofuSize.minimumTouch)
        .background { PofuPaperSurface(cornerRadius: PofuRadius.medium, kind: .stitched) }
        .rotationEffect(.degrees(-1))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

private struct PofuToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: LocalizedStringKey
    let systemImage: String?
    let isWin: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented {
                PofuToast(text, systemImage: systemImage)
                    .padding(.horizontal, PofuSpacing.screen)
                    .padding(.top, PofuSpacing.s)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .task {
                        #if os(iOS)
                        if isWin { PofuHaptics.shared.play(.resist) }
                        #endif
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation(.easeInOut(duration: 0.3)) { isPresented = false }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    /// Slides a toast in from the top for 2.5 s. `isWin` adds the soft
    /// success haptic; only wins get one.
    public func pofuToast(isPresented: Binding<Bool>, _ text: LocalizedStringKey, systemImage: String? = nil, isWin: Bool = false) -> some View {
        modifier(PofuToastModifier(isPresented: isPresented, text: text, systemImage: systemImage, isWin: isWin))
    }
}

// MARK: - Speech bubble

/// Paper with a cut tail below and a soft cocoa edge.
struct PofuPaperBubbleShape: Shape {
    static let tailHeight: CGFloat = 12
    /// 0...1 along the bottom edge.
    var tailPosition: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: max(rect.height - Self.tailHeight, 0))
        var path = Path(roundedRect: body, cornerRadius: PofuRadius.medium, style: .continuous)
        let x = rect.minX + PofuRadius.large + (rect.width - PofuRadius.large * 2) * tailPosition
        path.move(to: CGPoint(x: x - 9, y: body.maxY - 0.5))
        path.addLine(to: CGPoint(x: x + 3, y: rect.maxY))
        path.addLine(to: CGPoint(x: x + 11, y: body.maxY - 0.5))
        path.closeSubpath()
        return path
    }
}

/// A speech bubble made of paper: a speaker tab, live text, and a tail
/// toward the mouth. The one bubble (asset system v1 section 2.3): the
/// painted paper, tail and ribbon tab when they are baked, code-drawn
/// otherwise. Grows from the mouth.
public struct PofuPaperBubble<Content: View>: View {
    let speaker: LocalizedStringKey?
    let tint: Color
    /// 0...1 along the bottom edge; `nil` draws no tail (a line in the
    /// bottom band, below its speaker).
    let tailPosition: CGFloat?
    let content: Content

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    /// The painted paper, tail and tab are the crafted skin's; the glass
    /// skin draws the code-drawn bubble it drew before asset wave 0.
    @Environment(\.pofuPaintedChrome) private var paintsChrome

    /// The painted tail's size; its flat top overlaps the paper's lip.
    static var paintedTail: CGSize { CGSize(width: 22, height: 17) }
    static var tailOverlap: CGFloat { paintedTail.height - PofuPaperBubbleShape.tailHeight }

    public init(speaker: LocalizedStringKey? = nil, tint: Color = PofuKitPalette.rgb(0xE8946B), tailPosition: CGFloat? = 0.5, @ViewBuilder content: () -> Content) {
        self.speaker = speaker
        self.tint = tint
        self.tailPosition = tailPosition
        self.content = content()
    }

    /// Grows from the mouth, 0.25 s.
    public static var transition: AnyTransition {
        .scale(scale: 0.6, anchor: .bottom).combined(with: .opacity)
    }

    public var body: some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        let tail = tailPosition.map { PofuPaperBubbleShape(tailPosition: $0) }
        VStack(alignment: .leading, spacing: PofuSpacing.xs) {
            if let speaker {
                Text(speaker)
                    .font(PofuFont.caption.weight(.bold))
                    .foregroundStyle(PofuKitPalette.day.ink)
                    .padding(.leading, paintsChrome ? PofuSpacing.s + 4 : PofuSpacing.s + 2)
                    .padding(.trailing, PofuSpacing.s + 2)
                    .padding(.vertical, PofuSpacing.xxs + 1)
                    .background {
                        if resolver.isHighContrast || !paintsChrome {
                            Capsule(style: .continuous).fill(tint)
                        } else {
                            PofuKitFace(.tabRibbon) {
                                Capsule(style: .continuous).fill(tint)
                            }
                        }
                    }
                    .accessibilityAddTraits(.isHeader)
            }
            content
                .font(PofuFont.headline)
                .foregroundStyle(palette.onPaper)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PofuSpacing.l)
        .padding(.top, PofuSpacing.m)
        .padding(.bottom, PofuSpacing.m + (tail == nil ? 0 : PofuPaperBubbleShape.tailHeight))
        .background {
            ZStack {
                if resolver.isHighContrast {
                    outline(tail).fill(palette.paperTop)
                    outline(tail).stroke(palette.onPaper, lineWidth: 2)
                } else {
                    face(palette, tail: tail)
                }
            }
            .shadow(color: palette.edge.opacity(palette.isNight ? 0.5 : 0.14), radius: 8, y: 4)
        }
        .accessibilityElement(children: .combine)
    }

    private func outline(_ tail: PofuPaperBubbleShape?) -> AnyShape {
        tail.map { AnyShape($0) } ?? AnyShape(RoundedRectangle(cornerRadius: PofuRadius.medium, style: .continuous))
    }

    @ViewBuilder
    private func face(_ palette: PofuKitPalette, tail: PofuPaperBubbleShape?) -> some View {
        let paper: PofuKitArt = palette.isNight ? .bubblePaperNight : .bubblePaper
        let tailArt: PofuKitArt = palette.isNight ? .bubbleTailNight : .bubbleTail
        if paintsChrome, paper.isPainted, tail == nil || tailArt.isPainted {
            GeometryReader { proxy in
                let paperHeight = proxy.size.height - (tail == nil ? 0 : PofuPaperBubbleShape.tailHeight)
                ZStack(alignment: .topLeading) {
                    PofuKitFace(paper) { EmptyView() }
                        .frame(width: proxy.size.width, height: paperHeight)
                    if let tailPosition {
                        let size = Self.paintedTail
                        let x = PofuRadius.large + (proxy.size.width - PofuRadius.large * 2) * tailPosition
                        PofuKitFace(tailArt) { EmptyView() }
                            .frame(width: size.width, height: size.height)
                            .position(x: x + 1, y: paperHeight - Self.tailOverlap + size.height / 2)
                    }
                }
            }
        } else {
            let shape = outline(tail)
            ZStack {
                shape.fill(LinearGradient(colors: [palette.paperTop, palette.paperBottom], startPoint: .top, endPoint: .bottom))
                PofuGrainOverlay(opacity: 0.06).clipShape(shape)
                shape.stroke(palette.edge.opacity(palette.isNight ? 0.6 : 0.22), lineWidth: 1.2)
            }
        }
    }
}

// MARK: - Progress groove

/// A carved wood groove with a honey fill. The fill springs to its value;
/// at full there is one glint and a soft haptic.
public struct PofuGroove: View {
    let progress: Double
    let pips: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 16
    @State private var glint = false

    public init(progress: Double, pips: Int = 0) {
        self.progress = progress
        self.pips = pips
    }

    private var clamped: Double { min(max(progress, 0), 1) }

    public var body: some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        let shape = Capsule(style: .continuous)
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                PofuKitFace(.grooveWood) {
                    ZStack {
                        shape.fill(LinearGradient(colors: [palette.woodBottom, palette.woodTop], startPoint: .top, endPoint: .bottom))
                        PofuGrainOverlay(opacity: 0.1).clipShape(shape)
                        shape.pofuInnerShadow(palette.edge.opacity(0.45), width: 5, blur: 2.5, y: 2)
                    }
                }
                shape
                    .fill(LinearGradient(colors: [palette.honeyTop, palette.honey, palette.honeyBottom], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        shape.fill(.white.opacity(0.35)).frame(height: height * 0.22).padding(.horizontal, height * 0.3).padding(.top, 2)
                    }
                    .overlay {
                        if glint {
                            shape.fill(LinearGradient(colors: [.white.opacity(0), .white.opacity(0.7), .white.opacity(0)], startPoint: .leading, endPoint: .trailing))
                                .transition(.opacity)
                        }
                    }
                    .frame(width: max(height, width * clamped))
                    .opacity(clamped > 0 ? 1 : 0)
                    .animation(reduceMotion ? PofuMotion.reduced : PofuMotion.settle, value: clamped)
                ForEach(0..<max(pips - 1, 0), id: \.self) { index in
                    Circle()
                        .fill(palette.edge.opacity(0.35))
                        .frame(width: 3, height: 3)
                        .offset(x: width * CGFloat(index + 1) / CGFloat(pips) - 1.5)
                }
                if resolver.isHighContrast {
                    shape.strokeBorder(palette.onPaper, lineWidth: 2)
                }
            }
            .clipShape(shape)
        }
        .frame(height: height)
        .onChange(of: clamped >= 1) { _, full in
            guard full else { return }
            #if os(iOS)
            PofuHaptics.shared.play(.resist)
            #endif
            withAnimation(.easeInOut(duration: 0.4)) { glint = true }
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeInOut(duration: 0.4)) { glint = false }
            }
        }
        .accessibilityElement()
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}
#endif
