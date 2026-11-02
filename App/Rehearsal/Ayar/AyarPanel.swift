#if DEBUG
import PofuCore
import PofuDesignSystem
import PofuTuning
import SwiftUI
import UIKit

/// The Ayar panel: a glass card over the bottom of the screen, so the
/// world stays visible above it while a value changes. Sliders are drawn
/// from `TuningSpec`, not written per value.
///
/// Its copy is Turkish only and kept out of the string catalog: a debug
/// tool for the founder, compiled out of release builds.
struct AyarPanel: View {
    let model: AppModel
    let store: TuningStore
    let session: AyarSession

    @State private var confirmsReset = false

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header
                sections
                Divider()
                ScrollView {
                    content
                        .padding(PofuSpacing.m)
                }
                .scrollIndicators(.hidden)
            }
            .frame(height: min(proxy.size.height * 0.5, 460))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, PofuSpacing.xs)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .confirmationDialog(Text(verbatim: "Tüm ayarlar sıfırlansın mı?"), isPresented: $confirmsReset, titleVisibility: .visible) {
            Button(role: .destructive) {
                store.resetAll()
            } label: {
                Text(verbatim: "Sıfırla")
            }
        } message: {
            Text(verbatim: "Değerler paketteki varsayılanlara döner.")
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: PofuSpacing.s) {
            Image(systemName: "slider.horizontal.3")
                .accessibilityHidden(true)
            Text(verbatim: "Ayar")
                .font(PofuFont.headline)
            let count = store.changes.count
            if count > 0 {
                Text(verbatim: "\(count) değişiklik")
                    .font(PofuFont.caption)
                    .foregroundStyle(PofuColor.textSecondary)
            }
            Spacer(minLength: PofuSpacing.xs)
            ShareLink(item: store.exportJSON(), preview: SharePreview(Text(verbatim: "Pofu ayarları"))) {
                Label {
                    Text(verbatim: "Dışa aktar")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
                .font(PofuFont.subheadline)
            }
            Button {
                confirmsReset = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 36, height: PofuSize.minimumTouch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.changes.isEmpty)
            .accessibilityLabel(Text(verbatim: "Tümünü sıfırla"))
            Button {
                session.isOpen = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textSecondary)
                    .frame(width: 36, height: PofuSize.minimumTouch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "Kapat"))
        }
        .foregroundStyle(PofuColor.textPrimary)
        .padding(.horizontal, PofuSpacing.m)
        .padding(.top, PofuSpacing.xs)
    }

    private var sections: some View {
        ScrollView(.horizontal) {
            HStack(spacing: PofuSpacing.xs) {
                ForEach(AyarSection.allCases) { section in
                    let isOn = session.section == section
                    Button {
                        session.section = section
                    } label: {
                        Label {
                            Text(verbatim: AyarLabels.title(section))
                        } icon: {
                            Image(systemName: AyarLabels.symbol(section))
                        }
                        .font(PofuFont.subheadline)
                        .padding(.horizontal, PofuSpacing.s)
                        .frame(minHeight: 34)
                        .background(Capsule(style: .continuous).fill(isOn ? PofuColor.accent.opacity(0.22) : .clear))
                        .contentShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isOn ? PofuColor.textPrimary : PofuColor.textSecondary)
                }
            }
            .padding(.horizontal, PofuSpacing.m)
            .padding(.bottom, PofuSpacing.xs)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Sections

    @ViewBuilder private var content: some View {
        switch session.section {
        case .colour: colour
        case .camera: camera
        case .depth: depth
        case .pofu: pofu
        case .haptics: haptics
        case .seeds: seeds
        case .garden: garden
        }
    }

    /// The garden game's feel (`TuningValues.Garden`), live while it plays.
    private var garden: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            note("Bahçe oyunu açıkken değişiklik anında oyuna yansır. Sürüklemeyi denemek için paneli kapat; değerler kalır.")
            ForEach(TuningSpec.all.filter { $0.domain == "garden" }) { spec in
                TuningRow(store: store, key: spec.key)
            }
        }
    }

    private var colour: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            Picker(selection: Binding(get: { session.pinnedPhase }, set: { session.pinnedPhase = $0 })) {
                Text(verbatim: "Saat").tag(AyarPhase?.none)
                ForEach(AyarPhase.allCases) { phase in
                    Text(verbatim: AyarLabels.title(phase)).tag(AyarPhase?.some(phase))
                }
            } label: {
                Text(verbatim: "Günün saati")
            }
            .pickerStyle(.segmented)
            let phase = session.pinnedPhase ?? .day
            note(session.pinnedPhase == nil
                ? "Dünya saati izliyor. Bir zamanı sabitleyip onun rengini ayarla; şimdi gündüz değerleri gösteriliyor."
                : "\(AyarLabels.title(phase)) sabit. Değişiklik sahneye anında yansır.")
            ForEach(["exposure", "saturation", "contrast", "warmth", "vignette"], id: \.self) { name in
                TuningRow(store: store, key: "\(phase.gradeKey).\(name)")
            }
        }
    }

    private var camera: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.l) {
            note("Önizle ile yayı hisset. Sahne kamerası bu değerleri, görünüm turu 3 birleşince okuyacak.")
            ForEach(["travel", "far", "release", "focus", "buildPush"], id: \.self) { name in
                VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                    Text(verbatim: AyarLabels.spring(name))
                        .font(PofuFont.headline)
                    TuningRow(store: store, key: "camera.\(name).duration")
                    TuningRow(store: store, key: "camera.\(name).bounce")
                    SpringPreview(
                        duration: store.value("camera.\(name).duration") ?? 0.9,
                        bounce: store.value("camera.\(name).bounce") ?? 0.1
                    )
                }
            }
        }
    }

    private var depth: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            Toggle(isOn: Binding(get: { session.hd2d }, set: { session.hd2d = $0 })) {
                Text(verbatim: "HD-2D (ışık, parıltı, tilt-shift)")
            }
            Toggle(isOn: Binding(get: { session.depthMotion }, set: { session.depthMotion = $0 })) {
                Text(verbatim: "Hareketle derinlik")
            }
            note("Anahtarlar canlı. Kaydırıcılar, görünüm turu 3 birleşince sahneye bağlanacak.")
            TuningRow(store: store, key: "depth.parallax")
            TuningRow(store: store, key: "depth.tiltShiftIsland")
            TuningRow(store: store, key: "depth.tiltShiftHome")
        }
    }

    private var pofu: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            BreathPreview(store: store)
            note("Önizleme nefesi beş kat büyütür. Pofu bu değerleri, görünüm turu 3 birleşince okuyacak.")
            ForEach(["breathPeriodLow", "breathPeriodHigh", "breathAmplitudeLow", "breathAmplitudeHigh", "blinkIntervalMin", "blinkIntervalMax"], id: \.self) { name in
                TuningRow(store: store, key: "companion.\(name)")
            }
        }
    }

    private var haptics: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            note("Dene ile o şiddeti hisset.")
            ForEach(["pofuTap", "collectTap", "buildSwap", "hopAppearDay", "hopAppearNight", "breathStart"], id: \.self) { name in
                HapticRow(store: store, key: "haptics.\(name)", weighted: name == "buildSwap")
            }
        }
    }

    private var seeds: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            note("Tohum verimi oyun kurallarında (PofuCore) durur; burada yalnızca okunur. Saatte tohum, sakinlikten önce, seviye 1–5.")
            let rules = SeedRules()
            Text(verbatim: "Direnilen her uzanma: +\(rules.skipGift.units) tohum, günde \(rules.giftedSkipsPerDay) kez")
                .font(PofuFont.subheadline)
            ForEach(ArchipelagoCatalog.standard.stations(on: .aycicegi)) { station in
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: station.id.rawValue)
                        .font(PofuFont.headline)
                    Text(verbatim: (1...station.maxLevel).map { level in
                        station.seedsPerHour(at: level).formatted(.number.precision(.fractionLength(0...2)))
                    }.joined(separator: " · "))
                        .font(PofuFont.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(PofuColor.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func note(_ text: String) -> some View {
        Text(verbatim: text)
            .font(PofuFont.caption)
            .foregroundStyle(PofuColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Rows

/// One tunable value: its name, its value, a reset when changed, and a
/// slider on its spec's range and step.
private struct TuningRow: View {
    let store: TuningStore
    let key: String

    var body: some View {
        if let spec = TuningSpec.spec(for: key), let value = store.value(key) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: PofuSpacing.xs) {
                    Text(verbatim: AyarLabels.value(key))
                        .font(PofuFont.subheadline)
                    Spacer(minLength: PofuSpacing.xs)
                    if store.isChanged(key) {
                        Button {
                            store.reset(key)
                        } label: {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(PofuColor.accent)
                        .accessibilityLabel(Text(verbatim: "Varsayılana dön"))
                    }
                    Text(verbatim: value.formatted(.number.precision(.fractionLength(0...3))))
                        .font(PofuFont.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(store.isChanged(key) ? PofuColor.accent : PofuColor.textSecondary)
                }
                Slider(
                    value: Binding(get: { value }, set: { store.set(key, to: $0) }),
                    // No `step:` here: iOS 26 draws a tick per step. The
                    // store snaps to the spec's step instead.
                    in: spec.range
                ) {
                    Text(verbatim: AyarLabels.value(key))
                }
                Text(verbatim: key)
                    .font(PofuFont.caption)
                    .foregroundStyle(PofuColor.textSecondary.opacity(0.7))
            }
        }
    }
}

/// A haptic intensity with a button that plays it, as the app plays it:
/// a soft impact, or a weighted one for the build's swap.
private struct HapticRow: View {
    let store: TuningStore
    let key: String
    let weighted: Bool

    @State private var plays = 0

    var body: some View {
        let intensity = store.value(key) ?? 0.5
        HStack(alignment: .bottom, spacing: PofuSpacing.s) {
            TuningRow(store: store, key: key)
            Button {
                plays += 1
            } label: {
                Text(verbatim: "Dene")
                    .font(PofuFont.subheadline)
                    .padding(.horizontal, PofuSpacing.s)
                    .frame(minHeight: 34)
            }
            .buttonStyle(.glass)
        }
        .sensoryFeedback(
            weighted ? .impact(weight: .medium, intensity: intensity) : .impact(flexibility: .soft, intensity: intensity),
            trigger: plays
        )
    }
}

/// A dot that crosses its track on the spring, back and forth.
private struct SpringPreview: View {
    let duration: Double
    let bounce: Double

    @State private var across = false

    var body: some View {
        HStack(spacing: PofuSpacing.s) {
            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(PofuColor.sunken)
                    .overlay(alignment: .leading) {
                        Circle()
                            .fill(PofuColor.accent)
                            .frame(width: 22, height: 22)
                            .offset(x: across ? proxy.size.width - 22 : 0)
                    }
            }
            .frame(height: 22)
            Button {
                withAnimation(.spring(duration: duration, bounce: bounce)) {
                    across.toggle()
                }
            } label: {
                Text(verbatim: "Önizle")
                    .font(PofuFont.subheadline)
                    .padding(.horizontal, PofuSpacing.s)
                    .frame(minHeight: 34)
            }
            .buttonStyle(.glass)
        }
    }
}

/// Two breathing discs, tired and thriving, on the tuned period and
/// amplitude (the amplitude five times larger, so it reads).
private struct BreathPreview: View {
    let store: TuningStore

    var body: some View {
        let values = store.values.companion
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: PofuSpacing.xl) {
                disc(t: t, period: values.breathPeriodLow, amplitude: values.breathAmplitudeLow, label: "Yorgun")
                disc(t: t, period: values.breathPeriodHigh, amplitude: values.breathAmplitudeHigh, label: "Canlı")
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 96)
    }

    private func disc(t: Double, period: Double, amplitude: Double, label: String) -> some View {
        let breath = -cos(2 * .pi * t / max(period, 0.1)) * amplitude * 5
        return VStack(spacing: PofuSpacing.xs) {
            Ellipse()
                .fill(PofuColor.accent.opacity(0.6))
                .frame(width: 56, height: 56)
                .scaleEffect(x: 1 - breath * 0.55, y: 1 + breath, anchor: .bottom)
            Text(verbatim: label)
                .font(PofuFont.caption)
                .foregroundStyle(PofuColor.textSecondary)
        }
    }
}

// MARK: - Labels

/// The panel's Turkish names for sections and keys.
enum AyarLabels {
    static func title(_ section: AyarSection) -> String {
        switch section {
        case .colour: "Renk"
        case .camera: "Kamera"
        case .depth: "Derinlik"
        case .pofu: "Pofu"
        case .haptics: "Dokunuş"
        case .seeds: "Tohum"
        case .garden: "Bahçe"
        }
    }

    static func symbol(_ section: AyarSection) -> String {
        switch section {
        case .colour: "paintpalette"
        case .camera: "camera"
        case .depth: "square.3.layers.3d"
        case .pofu: "pawprint"
        case .haptics: "hand.tap"
        case .seeds: "leaf"
        case .garden: "square.grid.3x3"
        }
    }

    static func title(_ phase: AyarPhase) -> String {
        switch phase {
        case .day: "Gündüz"
        case .golden: "Altın saat"
        case .night: "Gece"
        }
    }

    static func spring(_ name: String) -> String {
        switch name {
        case "travel": "Ev ↔ Ada"
        case "far": "Ev ↔ Harita"
        case "release": "Sürüklemeyi bırakma"
        case "focus": "Odaklanma"
        case "buildPush": "İnşa yakınlaşması"
        default: name
        }
    }

    static func value(_ key: String) -> String {
        let name = key.split(separator: ".").last.map(String.init) ?? key
        switch name {
        case "duration": return "Süre (sn)"
        case "bounce": return "Sekme"
        case "parallax": return "Paralaks"
        case "tiltShiftIsland": return "Alan derinliği · Ada"
        case "tiltShiftHome": return "Alan derinliği · Ev"
        case "exposure": return "Pozlama"
        case "saturation": return "Doygunluk"
        case "contrast": return "Kontrast"
        case "warmth": return "Sıcaklık"
        case "vignette": return "Vinyet"
        case "breathPeriodLow": return "Nefes süresi · yorgun (sn)"
        case "breathPeriodHigh": return "Nefes süresi · canlı (sn)"
        case "breathAmplitudeLow": return "Nefes genliği · yorgun"
        case "breathAmplitudeHigh": return "Nefes genliği · canlı"
        case "blinkIntervalMin": return "Göz kırpma · en kısa (sn)"
        case "blinkIntervalMax": return "Göz kırpma · en uzun (sn)"
        case "pofuTap": return "Pofu'ya dokunma"
        case "collectTap": return "Topla"
        case "buildSwap": return "İnşa"
        case "hopAppearDay": return "Hop! gündüz"
        case "hopAppearNight": return "Hop! gece"
        case "breathStart": return "Nefes başlangıcı"
        case "trayScale": return "Tepsideki fide boyu"
        case "liftCells": return "Parmağın üstünde (hücre)"
        case "followStiffness": return "Takip sıkılığı"
        case "snapTolerance": return "Yapışma payı (hücre)"
        case "pickUp": return "Kaldırma (sn)"
        case "snapToCell": return "Yerine kayma (sn)"
        case "squash": return "Ezilme (sn)"
        case "squashAmount": return "Ezilme miktarı"
        case "trayReturn": return "Tepsiye dönüş (sn)"
        case "deal": return "Yeni fide (sn)"
        case "dealStagger": return "Yeni fide arası (sn)"
        case "bloomStagger": return "Çiçek dalgası arası (sn)"
        case "bloomPop": return "Çiçek açma (sn)"
        case "bloomHold": return "Çiçek bekleme (sn)"
        case "bloomOvershoot": return "Çiçek sekmesi"
        case "seedFlight": return "Çekirdek uçuşu (sn)"
        case "seedSize": return "Çekirdek boyu (pt)"
        case "seedsPerLine": return "Sıra başına çekirdek"
        case "glowStrength": return "Dolacak sıra parlaklığı"
        case "shakeMaximum": return "Sarsıntı tavanı (pt)"
        case "hapticLift": return "Dokunuş · kaldırma"
        case "hapticPlant": return "Dokunuş · dikme"
        case "hapticBloom": return "Dokunuş · çiçek"
        case "hapticCheek": return "Dokunuş · yanak"
        default: return name
        }
    }
}
#endif
