import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// "Fill my cheeks": pick an activity and a length, then start an honor
/// timer (ADR-0004: trust first). Seeds arrive when the timer ends.
struct EarnSheet: View {
    let model: AppModel

    @Environment(\.dismiss) private var dismiss
    @State private var kind: ActivityKind = .focus
    @State private var minutes = 25
    @State private var started = 0

    private let kinds: [ActivityKind] = [.focus, .study, .walk, .exercise, .chores, .creative]
    private let durations = [15, 25, 45, 60]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: PofuSpacing.s), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PofuSpacing.l) {
                    Text("What are we doing?")
                        .pofuSectionHeader()
                    LazyVGrid(columns: columns, spacing: PofuSpacing.s) {
                        ForEach(kinds, id: \.self) { item in
                            Button {
                                kind = item
                            } label: {
                                VStack(spacing: PofuSpacing.xs) {
                                    Image(systemName: item.symbolName)
                                        .font(PofuFont.title3)
                                    Text(item.label)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.vertical, PofuSpacing.xs)
                            }
                            .buttonStyle(PofuChoiceStyle(isSelected: kind == item, cornerRadius: PofuRadius.large))
                            .accessibilityAddTraits(kind == item ? .isSelected : [])
                        }
                    }

                    Text("How long?")
                        .pofuSectionHeader()
                    HStack(spacing: PofuSpacing.s) {
                        ForEach(durations, id: \.self) { value in
                            Button {
                                minutes = value
                            } label: {
                                // The unit sits under the numeral, so four
                                // chips fit at every size without shrinking.
                                VStack(spacing: 0) {
                                    Text(value, format: .number)
                                        .font(PofuFont.title3.monospacedDigit())
                                    Text("min", comment: "Under a duration chip: minutes, abbreviated.")
                                        .font(PofuFont.caption)
                                }
                            }
                            .buttonStyle(PofuChoiceStyle(isSelected: minutes == value, cornerRadius: PofuRadius.large))
                            .accessibilityLabel(Text("\(value) minutes"))
                            .accessibilityAddTraits(minutes == value ? .isSelected : [])
                        }
                    }

                    Text("Honor system: I trust you. Lock your phone and come back when the timer is done.")
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(PofuSpacing.screen)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Start sits on an opaque bar: the chips scroll under its edge
            // and never under the button itself, at any detent.
            .pofuFooter(surface: PofuColor.sunken) {
                VStack(spacing: PofuSpacing.s) {
                    HStack(spacing: PofuSpacing.s) {
                        SeedIcon(size: 18)
                        Text("\(minutes) minutes ≈ \(model.preview(minutes: minutes).units) seeds")
                            .font(PofuFont.headline)
                            .foregroundStyle(PofuColor.textPrimary)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)

                    Button {
                        started += 1
                        model.startSession(kind: kind, minutes: minutes)
                        dismiss()
                    } label: {
                        Text("Start")
                    }
                    .buttonStyle(PofuPrimaryButtonStyle())
                }
            }
            .navigationTitle(Text("Fill my cheeks"))
            .pofuSheetChrome()
            .sensoryFeedback(.selection, trigger: kind)
            .sensoryFeedback(.selection, trigger: minutes)
            .sensoryFeedback(.start, trigger: started)
        }
    }
}

/// The running honor session, over Pofu's room: Pofu focuses with the
/// user, the timer counts down, and seeds are credited at the end with the
/// cheeks-fill moment.
struct FocusSessionView: View {
    let model: AppModel

    @State private var confirmsEnd = false
    @State private var celebrations = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PofuColor.accentTint, PofuColor.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if let result = model.earningResult {
                cheeksFill(result)
            } else if let session = model.activeSession {
                running(session)
            }
        }
    }

    // MARK: Running

    private func running(_ session: ActiveSession) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = session.remaining(at: context.date)
            let total = Double(max(1, session.plannedMinutes * 60))
            let progress = 1 - remaining / total
            let soFar = model.economy.grossEnergy(for: session.completed(at: context.date)).units
            VStack(spacing: PofuSpacing.l) {
                VStack(spacing: PofuSpacing.xs) {
                    Text("\(Text(session.kind.label)) · \(session.plannedMinutes) min")
                        .font(PofuFont.subheadline)
                        .foregroundStyle(PofuColor.accent)
                    Text("Focusing with you")
                        .font(PofuFont.title3)
                        .foregroundStyle(PofuColor.textSecondary)
                }
                .padding(.top, PofuSpacing.xl)

                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .stroke(PofuColor.accentTint, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(PofuColor.accent.opacity(0.7), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    CompanionView(vitality: model.vitality, energy: model.cheekFill)
                        .padding(PofuSpacing.xxl)
                }
                .frame(maxWidth: 300, maxHeight: 300)
                .accessibilityHidden(true)
                Spacer(minLength: 0)

                Text(Duration.seconds(remaining.rounded(.up)), format: .time(pattern: .minuteSecond))
                    .font(.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(PofuColor.textPrimary)
                    .contentTransition(.numericText(countsDown: true))
                    .accessibilityLabel(Text("Time left"))
                    .accessibilityValue(Text(Duration.seconds(remaining.rounded(.up)), format: .units(allowed: [.minutes, .seconds], width: .wide)))

                HStack(spacing: PofuSpacing.s) {
                    SeedIcon(size: 16)
                    Text("+\(soFar) seeds so far")
                }
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.textPrimary)
                .padding(.horizontal, PofuSpacing.l)
                .padding(.vertical, PofuSpacing.s)
                .background(Capsule(style: .continuous).fill(PofuColor.raised))

                Text("Lock your phone. I'll be here when you're back.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                    .multilineTextAlignment(.center)

                Button("End early") {
                    confirmsEnd = true
                }
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.accent)
                .frame(minHeight: PofuSize.minimumTouch)
                .confirmationDialog(
                    Text("End now? You keep \(soFar) seeds."),
                    isPresented: $confirmsEnd,
                    titleVisibility: .visible
                ) {
                    Button("End and keep my seeds") {
                        model.finishSession()
                    }
                    Button("Keep going", role: .cancel) {}
                }
            }
            .padding(.horizontal, PofuSpacing.screen)
            .padding(.bottom, PofuSpacing.l)
        }
        .task(id: session) {
            // Credit the session the moment its timer runs out, including
            // when Pofu is opened after it ended.
            let remaining = session.remaining(at: model.currentTime())
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }
            guard !Task.isCancelled, model.activeSession == session else { return }
            model.finishSession()
        }
    }

    // MARK: Cheeks fill

    private func cheeksFill(_ result: EarningResult) -> some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            CompanionView(vitality: model.vitality, energy: model.cheekFill, celebrations: celebrations)
                .frame(maxWidth: 280)
            Text("+\(result.earned.units)")
                .font(PofuFont.numeral)
                .foregroundStyle(PofuColor.textPrimary)
            SpeechBubble {
                if result.earned > .zero {
                    Text("Nom. My cheeks are full of good minutes.")
                } else if result.forfeitedToCap > .zero {
                    Text("My cheeks can't fit more honor seeds today.")
                } else {
                    Text("Too short to count, but I saw that.")
                }
            }
            if result.forfeitedToCap > .zero {
                Text("\(result.forfeitedToCap.units) seeds didn't fit under today's honor cap.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button("Done") {
                model.dismissEarningResult()
            }
            .buttonStyle(PofuPrimaryButtonStyle())
        }
        .padding(.horizontal, PofuSpacing.screen)
        .padding(.bottom, PofuSpacing.l)
        .sensoryFeedback(.success, trigger: celebrations)
        .task {
            celebrations += 1
        }
    }
}
