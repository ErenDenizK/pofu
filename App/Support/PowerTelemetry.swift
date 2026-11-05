import MetricKit
import os

/// Dev-only power and performance telemetry (`docs/design/experience-v1.md`
/// §4.2). MetricKit delivers the previous day's payload; this writes the
/// metrics the frame-rate policy is tuned by to the unified log
/// (subsystem `com.erendenizk.pofu`, category `power`), where Console or
/// `log stream` reads them. Nothing leaves the device and nothing here
/// touches the user's data, so every field is `.public`.
///
/// The four signposts the scripted beats look for are `flight`, `sheet`,
/// `visit` and `firstWorldFrame`: wrap the work with
/// `PowerTelemetry.begin(.flight)` and `PowerTelemetry.end(.flight)`.
final class PowerTelemetry: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    /// The moments MXSignpostMetric aggregates.
    enum Beat: String {
        case flight
        case sheet
        case visit
        case firstWorldFrame

        fileprivate var name: StaticString {
            switch self {
            case .flight: "flight"
            case .sheet: "sheet"
            case .visit: "visit"
            case .firstWorldFrame: "firstWorldFrame"
            }
        }
    }

    /// A log handle MetricKit collects signposts from.
    private static let signpostLog = MXMetricManager.makeLogHandle(category: "pofu.power")

    private static let logger = Logger(subsystem: "com.erendenizk.pofu", category: "power")

    /// Starts listening. Call once at launch, in developer builds.
    static func install() {
        MXMetricManager.shared.add(shared)
    }

    private static let shared = PowerTelemetry()

    static func begin(_ beat: Beat) {
        mxSignpost(.begin, log: signpostLog, name: beat.name)
    }

    static func end(_ beat: Beat) {
        mxSignpost(.end, log: signpostLog, name: beat.name)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            let from = payload.timeStampBegin.formatted(.iso8601)
            let to = payload.timeStampEnd.formatted(.iso8601)
            let log = Self.logger
            log.info("payload \(from, privacy: .public) to \(to, privacy: .public)")
            if let cpu = payload.cpuMetrics {
                log.info("cpu cumulative \(cpu.cumulativeCPUTime.converted(to: .seconds).value, privacy: .public) s")
            }
            if let gpu = payload.gpuMetrics {
                log.info("gpu cumulative \(gpu.cumulativeGPUTime.converted(to: .seconds).value, privacy: .public) s")
            }
            if let display = payload.displayMetrics?.averagePixelLuminance {
                log.info("display average pixel luminance \(display.averageValue.value, privacy: .public) apl")
            }
            if let launch = payload.applicationLaunchMetrics {
                log.info("launch first-draw samples \(launch.histogrammedTimeToFirstDraw.totalBucketCount, privacy: .public)")
            }
            if let exits = payload.applicationExitMetrics {
                log.info("foreground normal exits \(exits.foregroundExitData.cumulativeNormalAppExitCount, privacy: .public)")
            }
            for signpost in payload.signpostMetrics ?? [] {
                log.info("signpost \(signpost.signpostName, privacy: .public) count \(signpost.totalCount, privacy: .public)")
            }
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let hangs = payload.hangDiagnostics?.count ?? 0
            let cpu = payload.cpuExceptionDiagnostics?.count ?? 0
            Self.logger.info("diagnostics: \(hangs, privacy: .public) hangs, \(cpu, privacy: .public) CPU exceptions")
        }
    }
}
