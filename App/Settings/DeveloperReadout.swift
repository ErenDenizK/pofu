import PofuCore
import PofuDesignSystem
import SwiftUI

/// The founder's readout of the gate (gate v2, section 10): per day, every
/// reach and how it ended, with the strict number (taps only) beside the
/// full one. A table, not a chart; shareable as text for the weekly report.
struct DeveloperReadout: View {
    let model: AppModel

    private var days: [GateReadoutDay] {
        GateReadout.days(endingOn: model.today, count: 7, from: model.state.checkIns, calendar: model.economy.calendar)
    }

    private var report: String {
        days.map(\.summary).joined(separator: "\n")
    }

    var body: some View {
        List {
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
                Text(verbatim: "Gate")
            } footer: {
                Text(verbatim: "The spike answers \"Pofu'yla aç\" with .openParentalControlsApp; the notification stays as the fallback. Day-1 case 23.")
            }
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
                    Text(verbatim: day.day.description)
                }
            }
        }
        .navigationTitle(Text(verbatim: "Readout"))
        .toolbar {
            ShareLink(item: report)
        }
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
