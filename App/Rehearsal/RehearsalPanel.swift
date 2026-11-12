import PofuCore
import PofuDesignSystem
import SwiftUI

/// The Prova panel: a small glass control over Pofu in Rehearsal mode.
/// Reaching for an app stands in for opening it on the Home Screen; the
/// time controls stand in for usage and for time passing. Draggable, and
/// collapses to a pill.
struct RehearsalPanel: View {
    let model: AppModel
    let rehearsal: RehearsalStage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Where the user left the panel, from its resting place.
    @AppStorage("rehearsal.panel.bottom.x") private var restingX: Double = 0
    @AppStorage("rehearsal.panel.bottom.y") private var restingY: Double = 0
    /// "glass" or "crafted"; empty follows the default skin.
    @AppStorage("PofuSkin") private var skinOverride = ""
    @State private var drag: CGSize = .zero
    @State private var confirmsReset = false
    @State private var isBusy = false

    var body: some View {
        GeometryReader { proxy in
            content
                .offset(clamped(in: proxy.size))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, PofuSpacing.s)
                .padding(.leading, PofuSpacing.s)
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: rehearsal.isPanelExpanded)
        .confirmationDialog(Text("Reset the rehearsal?"), isPresented: $confirmsReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                model.resetRehearsal()
            }
        } message: {
            Text("Setup, seeds and the island start over. Live data is not touched.")
        }
    }

    @ViewBuilder private var content: some View {
        if rehearsal.isPanelExpanded {
            expanded
                .frame(width: 228)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottomLeading)))
        } else {
            collapsed
                .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
                .transition(.opacity)
        }
    }

    private var collapsed: some View {
        Button {
            rehearsal.isPanelExpanded = true
        } label: {
            Label {
                Text("Rehearsal")
            } icon: {
                Image(systemName: "theatermasks.fill")
            }
            .font(PofuFont.subheadline)
            .foregroundStyle(PofuColor.textPrimary)
            .padding(.horizontal, PofuSpacing.m)
            .frame(minHeight: PofuSize.minimumTouch)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .gesture(moving)
        .accessibilityHint(Text("Shows the rehearsal controls"))
    }

    private var expanded: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            header
            ForEach(RehearsalCatalog.reachable, id: \.self) { app in
                control(reachLabel(for: app), symbol: app.symbolName) {
                    model.rehearsalReach(for: app)
                }
            }
            if model.isAwaitingSignOfLife {
                Text("Reach once to wake the island")
                    .font(PofuFont.caption)
                    .foregroundStyle(PofuColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            control(Text("+15 min of use"), symbol: "hourglass.badge.plus") {
                isBusy = true
                Task {
                    await model.rehearsalAddUsage()
                    isBusy = false
                }
            }
            .disabled(isBusy)
            control(Text("1 hour ahead"), symbol: "goforward") {
                model.rehearsalJump(.quietHour)
            }
            nightOrMorning
            // The day skip (vertical slice): straight to the next morning, whatever the hour, to see
            // days 1 to 3 unfold in minutes.
            control(Text(verbatim: "Next day"), symbol: "forward.end.fill") {
                model.rehearsalJump(.nextDay)
            }
            Divider()
            // The skin of the over-world chrome, to feel both on the phone.
            Picker(selection: $skinOverride) {
                Text("Glass").tag("glass")
                Text("Crafted").tag("crafted")
            } label: {
                Text("Skin")
            }
            .pickerStyle(.segmented)
            Divider()
            // Rounds are earned (two a day, one per resisted reach) and
            // credited to the pouch: the same ledger the product will use.
            let rounds = model.playableRounds
            control(Text("Play the garden (\(rounds))"), symbol: "square.grid.3x3.fill") {
                rehearsal.isPanelExpanded = false
                model.playGarden()
            }
            .disabled(rounds == 0)
            Divider()
            #if DEBUG
            // tuning lab: the live tuning panel (debug builds only).
            control(Text(verbatim: "Ayar"), symbol: "slider.horizontal.3") {
                TuningLab.session.isOpen = true
            }
            #endif
            control(Text("Reset"), symbol: "arrow.counterclockwise", role: .destructive) {
                confirmsReset = true
            }
        }
        .padding(PofuSpacing.m)
    }

    private var header: some View {
        HStack(spacing: PofuSpacing.xs) {
            Image(systemName: "theatermasks.fill")
                .accessibilityHidden(true)
            Text("Rehearsal")
                .font(PofuFont.headline)
            Text("Day \(model.world.tendedDays + 1)")
                .font(PofuFont.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(PofuColor.textSecondary)
            Spacer(minLength: PofuSpacing.xs)
            TimelineView(.everyMinute) { _ in
                Text(verbatim: clockText)
                    .font(PofuFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(PofuColor.textSecondary)
            }
            .id(rehearsal.jumps)
            Button {
                rehearsal.isPanelExpanded = false
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textSecondary)
                    .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Collapse"))
        }
        .foregroundStyle(PofuColor.textPrimary)
        .contentShape(Rectangle())
        .gesture(moving)
    }

    /// Night when it is day, morning at night.
    @ViewBuilder private var nightOrMorning: some View {
        switch model.rehearsalTime.nightOrMorning(at: rehearsal.clock.now) {
        case .morning:
            control(Text("Morning"), symbol: "sunrise.fill") {
                model.rehearsalJump(.morning)
            }
        case .night, .quietHour, .nextDay:
            control(Text("Night"), symbol: "moon.stars.fill") {
                model.rehearsalJump(.night)
            }
        }
    }

    private func control(_ title: Text, symbol: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Label {
                title
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } icon: {
                Image(systemName: symbol)
                    .frame(width: 22)
            }
            .font(PofuFont.subheadline)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? PofuColor.warning : PofuColor.textPrimary)
    }

    private func reachLabel(for app: ProtectedApp) -> Text {
        switch app {
        case .instagram: Text("Reach for Instagram")
        case .youtube: Text("Reach for YouTube")
        case .tiktok: Text("Reach for TikTok")
        default: Text(verbatim: app.displayName)
        }
    }

    /// The rehearsed time, and how far ahead of the real one it runs.
    private var clockText: String {
        let now = rehearsal.clock.now
        let time = now.formatted(date: .omitted, time: .shortened)
        let ahead = rehearsal.clock.offsetSeconds
        guard ahead >= 60 else { return time }
        let skipped = Duration.seconds(ahead).formatted(.units(allowed: [.days, .hours, .minutes], width: .narrow, maximumUnitCount: 2))
        return "\(time) · +\(skipped)"
    }

    private var moving: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                drag = value.translation
            }
            .onEnded { value in
                restingX += Double(value.translation.width)
                restingY += Double(value.translation.height)
                drag = .zero
            }
    }

    /// The offset from the bottom-leading corner (above the safe area),
    /// kept on screen and below the top bar: dragging up is negative.
    private func clamped(in size: CGSize) -> CGSize {
        let width: CGFloat = rehearsal.isPanelExpanded ? 228 : 120
        let wantedX = CGFloat(restingX) + drag.width
        let wantedY = CGFloat(restingY) + drag.height
        let x = max(0, min(size.width - width - PofuSpacing.l, wantedX))
        let y = min(0, max(-max(0, size.height - 440), wantedY))
        return CGSize(width: x, height: y)
    }
}
