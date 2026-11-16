import PofuDesignSystem
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// D6 of docs/design/world-presentation-build-spec.md, the measurement WP9 starts with: does a layer moved
/// by a `.repeatForever` animation cost the app any `body` evaluations while it moves (the render server
/// animates it), against the same layer drawn through `PofuTimeline` at `PofuFrameRate.drift` (the app
/// draws every frame)? Body count at most 3 over 3 s: render-server animation is free. The counts are
/// written to `d6-measurement.txt` in `WORLD_SCREENSHOTS_DIR` and attached; the cloud floor ships on the
/// `PofuTimeline` path either way, which needs no judgement, and WP9's follow-up moves layers across when this
/// says they can go.
final class RenderServerMotionTests: XCTestCase {
    /// Counts, in a reference type a view body may touch.
    final class Counter { var n = 0 }

    struct RenderServerProbe: View {
        let counter: Counter
        @State private var moved = false

        var body: some View {
            counter.n += 1
            return Circle().fill(.white)
                .frame(width: 60, height: 60)
                .offset(x: moved ? 40 : 0)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: true), value: moved)
                .onAppear { moved = true }
        }
    }

    struct TimelineProbe: View {
        let counter: Counter

        var body: some View {
            PofuTimeline(hz: PofuFrameRate.drift) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                counter.n += 1
                return Canvas { ctx, _ in
                    ctx.fill(Path(ellipseIn: CGRect(x: 20 + 20 * sin(t), y: 0, width: 60, height: 60)), with: .color(.white))
                }
            }
            .frame(width: 200, height: 80)
        }
    }

    @MainActor
    private func measure<V: View>(_ counter: Counter, scene: UIWindowScene, _ view: V) async throws -> Int {
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let before = counter.n
        try await Task.sleep(nanoseconds: 3_000_000_000)
        let moving = counter.n - before
        window.isHidden = true
        return moving
    }

    @MainActor
    func testMeasureRenderServerAgainstTheTimeline() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let a = Counter(), b = Counter()
        let renderServer = try await measure(a, scene: scene, RenderServerProbe(counter: a))
        let timeline = try await measure(b, scene: scene, TimelineProbe(counter: b))
        let text = "D6: render-server offset animation, body evaluations over 3 s: \(renderServer) (limit 3: \(renderServer <= 3 ? "free" : "not free")); PofuTimeline at drift (\(PofuFrameRate.drift) Hz), content evaluations over 3 s: \(timeline)\n"
        print(text)
        let attachment = XCTAttachment(string: text)
        attachment.lifetime = .keepAlways
        add(attachment)
        let folder: URL
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            folder = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            folder = FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try text.write(to: folder.appendingPathComponent("d6-measurement.txt"), atomically: true, encoding: .utf8)
    }
}
