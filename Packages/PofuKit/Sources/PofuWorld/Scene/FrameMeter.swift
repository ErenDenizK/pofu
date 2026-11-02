#if os(iOS)
import Darwin
import QuartzCore
import SwiftUI

/// What the frame meter measured over one window.
public struct FrameStats: Hashable, Sendable, CustomStringConvertible {
    public var frames: Int
    public var seconds: Double
    /// Intervals between delivered frames, in milliseconds. A frame that
    /// missed its deadline (CPU or GPU) shows as a longer interval.
    public var p50: Double
    public var p95: Double
    public var max: Double
    /// The app process's CPU time over the window, as a share of one core.
    public var cpuPercent: Double

    public var fps: Double {
        seconds > 0 ? Double(frames) / seconds : 0
    }

    public var description: String {
        String(format: "%.0f fps, frame p50 %.1f ms, p95 %.1f ms, max %.1f ms, CPU %.0f%% of a core (%ld frames in %.1f s)",
               fps, p50, p95, max, cpuPercent, frames, seconds)
    }
}

/// A simple frame-time counter: a display link records the interval
/// between delivered frames, and `getrusage` the process's CPU time.
///
/// GPU time cannot be read from inside the app for SwiftUI's rendering
/// (the render server composites out of process); a GPU-bound effect shows
/// up as long frame intervals instead. Instruments has the GPU timeline.
@MainActor
public final class FrameMeter {
    private var link: CADisplayLink?
    private var target: Target?
    private var last: CFTimeInterval?
    private var intervals: [Double] = []
    private var startTime: CFTimeInterval = 0
    private var startCPU: Double = 0

    public init() {}

    public func start() {
        stop()
        intervals = []
        last = nil
        startTime = CACurrentMediaTime()
        startCPU = Self.processCPUSeconds()
        let target = Target { [weak self] link in
            self?.tick(link)
        }
        let link = CADisplayLink(target: target, selector: #selector(Target.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.target = target
        self.link = link
    }

    /// Stops measuring and returns the window's statistics.
    @discardableResult
    public func stop() -> FrameStats {
        link?.invalidate()
        link = nil
        target = nil
        let seconds = Swift.max(CACurrentMediaTime() - startTime, 0.001)
        let cpu = Self.processCPUSeconds() - startCPU
        let sorted = intervals.sorted()
        func pct(_ q: Double) -> Double {
            sorted.isEmpty ? 0 : sorted[Swift.min(sorted.count - 1, Int((Double(sorted.count - 1) * q).rounded()))]
        }
        return FrameStats(
            frames: intervals.count,
            seconds: seconds,
            p50: pct(0.5),
            p95: pct(0.95),
            max: sorted.last ?? 0,
            cpuPercent: cpu / seconds * 100
        )
    }

    /// The statistics so far, without stopping.
    public func peek() -> FrameStats {
        let seconds = Swift.max(CACurrentMediaTime() - startTime, 0.001)
        let sorted = intervals.sorted()
        let p = { (q: Double) -> Double in
            sorted.isEmpty ? 0 : sorted[Swift.min(sorted.count - 1, Int((Double(sorted.count - 1) * q).rounded()))]
        }
        return FrameStats(frames: intervals.count, seconds: seconds, p50: p(0.5), p95: p(0.95), max: sorted.last ?? 0,
                          cpuPercent: (Self.processCPUSeconds() - startCPU) / seconds * 100)
    }

    private func tick(_ link: CADisplayLink) {
        if let last {
            intervals.append((link.timestamp - last) * 1000)
        }
        last = link.timestamp
    }

    /// User plus system CPU time of this process, in seconds.
    static func processCPUSeconds() -> Double {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { return 0 }
        func seconds(_ t: timeval) -> Double { Double(t.tv_sec) + Double(t.tv_usec) / 1_000_000 }
        return seconds(usage.ru_utime) + seconds(usage.ru_stime)
    }

    private final class Target: NSObject {
        let handler: @MainActor (CADisplayLink) -> Void

        init(handler: @escaping @MainActor (CADisplayLink) -> Void) {
            self.handler = handler
        }

        @MainActor @objc func tick(_ link: CADisplayLink) {
            handler(link)
        }
    }
}

/// The debug overlay: the meter's last second, refreshed twice a second.
struct FrameMeterOverlay: View {
    @State private var meter = FrameMeter()
    @State private var text = "…"

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 6))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                while !Task.isCancelled {
                    meter.start()
                    try? await Task.sleep(for: .milliseconds(1000))
                    let s = meter.stop()
                    text = String(format: "%.0f fps · p95 %.1f ms · CPU %.0f%%", s.fps, s.p95, s.cpuPercent)
                }
            }
    }
}
#endif
