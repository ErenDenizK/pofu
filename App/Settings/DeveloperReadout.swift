import PofuCore
import PofuDesignSystem
import SwiftUI

/// The founder's readout of the gate (gate v2, section 10): per day, every
/// reach and how it ended, with the strict number (taps only) beside the
/// full one. A table, not a chart; shareable as text for the weekly report.
///
/// Rehearsal mode's numbers are never shown as real: they come from its own
/// store, every section says "simulated", and the event log filters by
/// source.
struct DeveloperReadout: View {
    let model: AppModel

    @State private var filter: EventSourceFilter = .all
    @State private var events: [LoggedEvent] = []

    private var days: [GateReadoutDay] {
        GateReadout.days(endingOn: model.today, count: 7, from: model.state.checkIns, calendar: model.economy.calendar)
    }

    private var isSimulated: Bool {
        model.eventSource == .simulated
    }

    /// The day tables come from this store's check-ins, which are all of
    /// this launch's source.
    private var showsDays: Bool {
        filter.includes(model.eventSource)
    }

    private var report: String {
        let lines = days.map(\.summary).joined(separator: "\n")
        return isSimulated ? "SIMULATED (Rehearsal mode), not real use\n" + lines : lines
    }

    var body: some View {
        List {
            if isSimulated {
                Section {
                    Label {
                        Text(verbatim: "Rehearsal mode: every number here is simulated and kept apart from live data.")
                    } icon: {
                        Image(systemName: "theatermasks.fill")
                    }
                    .foregroundStyle(PofuColor.warning)
                }
            }
            Section {
                LabeledContent {
                    Text(verbatim: "\(model.measuredGuardedMinutesToday ?? 0) / \(model.gateRules.dailyHourMinutes)")
                } label: {
                    Text(verbatim: "Measured minutes today")
                }
                LabeledContent {
                    Text(verbatim: "\(model.screenTimeLedger.overLimitOpens(on: model.today))")
                } label: {
                    Text(verbatim: "Breaths today")
                }
                LabeledContent {
                    Text(verbatim: "\(model.screenTimeLedger.pendingReaches.count)")
                } label: {
                    Text(verbatim: "Reaches waiting to resolve")
                }
                Toggle(isOn: Binding(
                    get: { model.tryOpenParentalControlsApp },
                    set: { model.setTryOpenParentalControlsApp($0) }
                )) {
                    Text(verbatim: "Spike: open Pofu from the shield (iOS 26.5)")
                }
            } header: {
                Text(verbatim: isSimulated ? "Gate (simulated)" : "Gate")
            } footer: {
                Text(verbatim: "The spike answers \"Pofu'yla aç\" with .openParentalControlsApp; the notification stays as the fallback. Day-1 case 23.")
            }
            Section {
                let world = model.world
                LabeledContent {
                    Text(verbatim: world.activity.rawValue)
                } label: {
                    Text(verbatim: "World")
                }
                LabeledContent {
                    Text(verbatim: String(format: "×%.1f (%.0f %% to the next step)", world.calm, world.calmProgress * 100))
                } label: {
                    Text(verbatim: "Calm")
                }
                LabeledContent {
                    Text(verbatim: String(format: "%.1f · %@", world.wellbeing, world.band.rawValue))
                } label: {
                    Text(verbatim: "Wellbeing")
                }
                LabeledContent {
                    Text(verbatim: "\(world.pending.total.units) waiting · \(world.jar.units) in the jar\(world.isHolding ? " · held" : "")")
                } label: {
                    Text(verbatim: "Seeds")
                }
                LabeledContent {
                    Text(verbatim: "\(world.tendedDays) tended · \(world.calmNights) calm nights · stage \(world.homeStage)")
                } label: {
                    Text(verbatim: "Days")
                }
                LabeledContent {
                    Text(verbatim: "\(world.guardedMinutesToday) / \(world.dailyHourMinutes) · \(world.overLimitOpensToday) over the hour")
                } label: {
                    Text(verbatim: "Guarded minutes (game)")
                }
            } header: {
                Text(verbatim: isSimulated ? "Game model (simulated, not shown yet)" : "Game model (not shown yet)")
            }
            eventLog
            if showsDays {
                ForEach(days, id: \.day) { day in
                    Section {
                        row("Reaches", day.reaches)
                        row("Resisted (all)", day.resisted)
                        row("Resisted by tap", day.resistedByTap)
                        row("Shield skips", day.shieldSkips)
                        row("Silent leaves", day.silentLeaves)
                        row("Abandoned requests", day.abandonedRequests)
                        row("Cancelled requests", day.cancelledRequests)
                        row("Quick checks", day.quickChecks)
                        row("Hop! skips", day.hopSkips)
                        row("Hop! opens", day.hopOpens)
                    } header: {
                        Text(verbatim: isSimulated ? "\(day.day.description) (simulated)" : day.day.description)
                    }
                }
            }
        }
        .navigationTitle(Text(verbatim: "Readout"))
        .toolbar {
            ShareLink(item: report)
        }
        .onAppear {
            events = model.recentEvents()
        }
    }

    /// The event log's newest entries, by source.
    private var eventLog: some View {
        Section {
            Picker(selection: $filter) {
                Text(verbatim: "All").tag(EventSourceFilter.all)
                Text(verbatim: "Live").tag(EventSourceFilter.live)
                Text(verbatim: "Simulated").tag(EventSourceFilter.simulated)
            } label: {
                Text(verbatim: "Source")
            }
            .pickerStyle(.segmented)
            let shown = Array(events.filtered(by: filter).suffix(40).reversed())
            if shown.isEmpty {
                Text(verbatim: "Nothing logged from this source here.")
                    .foregroundStyle(PofuColor.textSecondary)
            }
            ForEach(shown) { entry in
                HStack(spacing: PofuSpacing.s) {
                    Text(entry.at.formatted(date: .omitted, time: .shortened))
                        .monospacedDigit()
                        .foregroundStyle(PofuColor.textSecondary)
                    Text(verbatim: Self.kind(of: entry.event))
                    Spacer(minLength: 0)
                    if entry.source == .simulated {
                        Text(verbatim: "simulated")
                            .font(PofuFont.caption)
                            .foregroundStyle(PofuColor.warning)
                    }
                }
                .font(PofuFont.footnote)
            }
        } header: {
            Text(verbatim: "Event log")
        } footer: {
            let simulated = events.filter { $0.source == .simulated }.count
            Text(verbatim: "Last \(events.count): \(events.count - simulated) live · \(simulated) simulated. The day tables below count this store's reaches, which are all \(isSimulated ? "simulated" : "live"); the filter hides them for the other source.")
        }
    }

    private static func kind(of event: PofuEvent) -> String {
        Mirror(reflecting: event).children.first?.label ?? String(describing: event)
    }

    private func row(_ title: String, _ value: Int) -> some View {
        LabeledContent {
            Text(verbatim: "\(value)")
                .monospacedDigit()
        } label: {
            Text(verbatim: title)
        }
    }
}
