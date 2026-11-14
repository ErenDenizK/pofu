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
        // The felt chips are light at night too (no night twin was painted), so their label is ink.
        let painted = (isSelected ? PofuKitArt.chipFeltSelected : PofuKitArt.chipFelt).isPainted
        configuration.label
            .font(PofuFont.subheadline)
            .foregroundStyle(isSelected && palette.isNight || (painted && !resolver.isHighContrast) ? palette.ink : palette.onPaper)
            .padding(.horizontal, PofuSpacing.m + 2)
            .padding(.vertical, PofuSpacing.xs + 2)
            .frame(minHeight: PofuSize.chipHeight)
            .background {
                chipFace(palette: palette, resolver: resolver, shape: shape)
                .brightness(pressed ? -0.06 : 0)
            }
            .frame(minHeight: PofuSize.minimumTouch)
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.55)
            .scaleEffect(pressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? PofuMotion.reduced : PofuMotion.squish, value: pressed)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The painted felt chip; the drawn felt under Increase Contrast (which needs its own edge) or
    /// while unbaked.
    @ViewBuilder
    private func chipFace(palette: PofuKitPalette, resolver: PofuKitStyleResolver, shape: Capsule) -> some View {
        if resolver.isHighContrast {
            drawnChip(palette: palette, resolver: resolver, shape: shape)
        } else {
            PofuKitFace(isSelected ? .chipFeltSelected : .chipFelt) {
                drawnChip(palette: palette, resolver: resolver, shape: shape)
            }
        }
    }

    private func drawnChip(palette: PofuKitPalette, resolver: PofuKitStyleResolver, shape: Capsule) -> some View {
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
        .background { PofuStripSurface() }
        .rotationEffect(.degrees(-1))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

/// The toast's paper strip: the painted stitched strip (day or night twin), the stitched paper
/// surface under Increase Contrast or while the strip is unbaked. For short lines of one or two rows.
public struct PofuStripSurface: View {
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init() {}

    public var body: some View {
        let palette = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast).palette
        let strip: PofuKitArt = palette.isNight ? .toastStripNight : .toastStrip
        if contrast != .increased, strip.isPainted {
            PofuKitFace(strip) { EmptyView() }
                .shadow(color: palette.edge.opacity(palette.isNight ? 0.5 : 0.12), radius: 10, y: 4)
        } else {
            PofuPaperSurface(cornerRadius: PofuRadius.medium, kind: .stitched)
        }
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

/// The speaker's tab: the painted ribbon with a short label on it (a name, a kicker), a
/// code-drawn capsule while the ribbon is unbaked or under Increase Contrast.
public struct PofuSpeakerTab: View {
    let label: Text
    let tint: Color

    @Environment(\.colorSchemeContrast) private var contrast

    public init(_ label: Text, tint: Color = PofuKitPalette.rgb(0xE8946B)) {
        self.label = label
        self.tint = tint
    }

    public var body: some View {
        label
            .font(PofuFont.caption.weight(.bold))
            .foregroundStyle(PofuKitPalette.day.ink)
            .padding(.leading, PofuSpacing.s + 4)
            .padding(.trailing, PofuSpacing.s + 2)
            .padding(.vertical, PofuSpacing.xxs + 1)
            .background {
                if contrast == .increased {
                    Capsule(style: .continuous).fill(tint)
                } else {
                    PofuKitFace(.tabRibbon) {
                        Capsule(style: .continuous).fill(tint)
                    }
                }
            }
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Speech bubble

/// Paper with a cut tail below and a soft cocoa edge.
struct PofuPaperBubbleShape: Shape {
    static let tailHeight: CGFloat = 12
    /// 0...1 along the tail's edge.
    var tailPosition: CGFloat = 0.5
    /// The edge the tail leaves: `.top` mirrors the bubble, for a card below its speaker.
    var tailEdge: VerticalEdge = .bottom

    func path(in rect: CGRect) -> Path {
        let path = bottomTailPath(in: rect)
        guard tailEdge == .top else { return path }
        return path.applying(CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -(rect.minY + rect.maxY)))
    }

    private func bottomTailPath(in rect: CGRect) -> Path {
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
    let speaker: Text?
    let tint: Color
    /// 0...1 along the tail's edge; `nil` draws no tail (a line in the
    /// bottom band, below its speaker).
    let tailPosition: CGFloat?
    /// The edge the tail leaves: `.bottom` toward a mouth above, `.top` for a card hung below its speaker.
    let tailEdge: VerticalEdge
    let content: Content
    var combinesAccessibility = true

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    /// The painted tail's size; its flat top overlaps the paper's lip.
    static var paintedTail: CGSize { CGSize(width: 22, height: 17) }
    static var tailOverlap: CGFloat { paintedTail.height - PofuPaperBubbleShape.tailHeight }

    public init(speaker: LocalizedStringKey? = nil, tint: Color = PofuKitPalette.rgb(0xE8946B), tailPosition: CGFloat? = 0.5, tailEdge: VerticalEdge = .bottom, @ViewBuilder content: () -> Content) {
        self.init(speakerText: speaker.map { Text($0) }, tint: tint, tailPosition: tailPosition, tailEdge: tailEdge, content: content)
    }

    /// The speaker as a verbatim `Text` (a resident's name is data, not a string key).
    public init(speakerText: Text?, tint: Color = PofuKitPalette.rgb(0xE8946B), tailPosition: CGFloat? = 0.5, tailEdge: VerticalEdge = .bottom, @ViewBuilder content: () -> Content) {
        self.speaker = speakerText
        self.tint = tint
        self.tailPosition = tailPosition
        self.tailEdge = tailEdge
        self.content = content()
    }

    /// A bubble that holds a control (a button) keeps its children separate for VoiceOver
    /// instead of reading as one line.
    public func holdingControls() -> Self {
        var copy = self
        copy.combinesAccessibility = false
        return copy
    }

    /// Grows from the mouth, 0.25 s.
    public static var transition: AnyTransition {
        .scale(scale: 0.6, anchor: .bottom).combined(with: .opacity)
    }

    public var body: some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        let tail = tailPosition.map { PofuPaperBubbleShape(tailPosition: $0, tailEdge: tailEdge) }
        VStack(alignment: .leading, spacing: PofuSpacing.xs) {
            if let speaker {
                PofuSpeakerTab(speaker, tint: tint)
            }
            content
                .font(PofuFont.headline)
                .foregroundStyle(palette.onPaper)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, PofuSpacing.l)
        .padding(.top, PofuSpacing.m + (tail != nil && tailEdge == .top ? PofuPaperBubbleShape.tailHeight : 0))
        .padding(.bottom, PofuSpacing.m + (tail != nil && tailEdge == .bottom ? PofuPaperBubbleShape.tailHeight : 0))
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
        .accessibilityElement(children: combinesAccessibility ? .combine : .contain)
    }

    private func outline(_ tail: PofuPaperBubbleShape?) -> AnyShape {
        tail.map { AnyShape($0) } ?? AnyShape(RoundedRectangle(cornerRadius: PofuRadius.medium, style: .continuous))
    }

    @ViewBuilder
    private func face(_ palette: PofuKitPalette, tail: PofuPaperBubbleShape?) -> some View {
        let paper: PofuKitArt = palette.isNight ? .bubblePaperNight : .bubblePaper
        let tailArt: PofuKitArt = palette.isNight ? .bubbleTailNight : .bubbleTail
        if paper.isPainted, tail == nil || tailArt.isPainted {
            GeometryReader { proxy in
                let tailHeight = tail == nil ? 0 : PofuPaperBubbleShape.tailHeight
                let paperHeight = proxy.size.height - tailHeight
                let onTop = tailEdge == .top
                ZStack(alignment: .topLeading) {
                    PofuKitFace(paper) { EmptyView() }
                        .frame(width: proxy.size.width, height: paperHeight)
                        .offset(y: onTop ? tailHeight : 0)
                    if let tailPosition {
                        let size = Self.paintedTail
                        let x = PofuRadius.large + (proxy.size.width - PofuRadius.large * 2) * tailPosition
                        PofuKitFace(tailArt) { EmptyView() }
                            .frame(width: size.width, height: size.height)
                            .rotationEffect(.degrees(onTop ? 180 : 0))
                            .position(x: x + 1, y: onTop ? tailHeight + Self.tailOverlap - size.height / 2 : paperHeight - Self.tailOverlap + size.height / 2)
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
        let painted = PofuKitArt.grooveWood.isPainted && !resolver.isHighContrast
        GeometryReader { proxy in
            let width = proxy.size.width
            // The painted groove has a honey rim; the fill sits inside it.
            let inset = painted ? height * 0.16 : 0
            let inner = width - inset * 2
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
                    .frame(width: max(height - inset * 2, inner * clamped), height: height - inset * 2)
                    .padding(.leading, inset)
                    .opacity(clamped > 0 ? 1 : 0)
                    .animation(reduceMotion ? PofuMotion.reduced : PofuMotion.settle, value: clamped)
                ForEach(0..<max(pips - 1, 0), id: \.self) { index in
                    Circle()
                        .fill(palette.edge.opacity(0.35))
                        .frame(width: 3, height: 3)
                        .offset(x: inset + inner * CGFloat(index + 1) / CGFloat(pips) - 1.5)
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
