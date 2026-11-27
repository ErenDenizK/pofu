import Darwin
import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Memory the phone holds for Home, measured (docs/design/texture-budget-v1.md, PR 3). Rule v1 counts texture
/// pixels at 4 bytes each (what HEIC decodes to). This reads the process's `phys_footprint` before and after
/// Home is hosted, so the count is checked against what the simulator really holds. CI runs it alone
/// (`-only-testing`) so no earlier test has decoded a Home image.
final class TextureMemoryTests: XCTestCase {
    /// Rule v1 decoded, section 3 of the spec: day 0 and day 0 plus night 0 (a crossfade), in MB.
    private let countedDay0MB = 37.6
    private let countedCrossfadeMB = 75.4

    @MainActor
    func testHomeHoldsWhatTheBudgetCounts() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let f0 = footprintMB()
        let day = try await host(hour: 12, scene: scene)
        try await Task.sleep(for: .milliseconds(1500)) // the far picture renders at 0.6 s
        let f1 = footprintMB()
        let night = try await host(hour: 22.5, scene: scene)
        try await Task.sleep(for: .milliseconds(1500))
        let f2 = footprintMB()

        let d1 = f1 - f0
        let d2 = f2 - f0
        print(String(
            format: "texture-memory: day-0 %.1f MB (counted %.1f), day-0+night-0 %.1f MB (counted %.1f)",
            d1, countedDay0MB, d2, countedCrossfadeMB
        ))
        print(String(format: "texture-memory-ratio: day-0 %.2f, crossfade %.2f", d1 / countedDay0MB, d2 / countedCrossfadeMB))
        for window in [day, night] {
            window.isHidden = true
            window.rootViewController = nil
        }
        let ratio = d1 / countedDay0MB
        XCTAssertTrue((0.6...1.6).contains(ratio), "measured/counted day-0 ratio \(ratio) is outside 0.6 to 1.6")
    }

    @MainActor
    private func host(hour: Double, scene: UIWindowScene) async throws -> UIWindow {
        let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
        let world = IslandSamples.world(
            clock: nil,
            tendedDays: 60,
            levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 3, .workshop: 5, .bagelCart: 5, .pier: 5, .lighthouse: 5],
            jar: Energy(214),
            islands: [.home, .harbor],
            islandLevel: 10,
            wellbeing: 84
        )
        let island = IslandSceneModel(framing: .mid)
        let home = WorldHomeModel(now: { now }, schedulesCues: false)
        let inputs = VisitInputs(now: now, world: world, lastSettled: now.addingTimeInterval(-5 * 60), calendar: .current)
        home.beginVisit(VisitQueue.plan(inputs))
        home.acknowledgeCurrentBeat()
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = .clear
        let view = WorldHome(
            world: world,
            today: TodaySummary(beads: [false, true, false, true], guardedMinutes: 22, dailyHourMinutes: 60),
            scene: island,
            home: home,
            actions: WorldHome.Actions(collect: { nil }, build: { _ in nil }, openSettings: {}, repair: {}, openToday: {})
        )
        .environment(\.worldLook, look)
        .environment(\.worldStillFrame, true)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 4
        window.makeKeyAndVisible()
        return window
    }

    /// `phys_footprint` in MB (`task_info`, `TASK_VM_INFO`): the number the system's memory limit uses.
    private func footprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self(), task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        XCTAssertEqual(status, KERN_SUCCESS, "task_info failed")
        return Double(info.phys_footprint) / 1_048_576
    }
}
