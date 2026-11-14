import Foundation
@testable import PofuDesignSystem
import Testing

/// The one rule for continuous redraws (`PofuTimeline`): a still painting must not redraw at the display rate.
struct PofuFrameRuleTests {
    @Test func ambientStopsWhenNothingShouldMove() {
        func paused(_ requested: Bool = false, active: Bool = true, reduce: Bool = false, low: Bool = false) -> Bool {
            PofuFrameRule.isPaused(kind: .ambient, requested: requested, active: active, reduceMotion: reduce, lowPower: low)
        }
        #expect(!paused())
        #expect(paused(true))
        #expect(paused(active: false))
        #expect(paused(reduce: true))
        #expect(paused(low: true))
    }

    @Test func essentialKeepsRunningUnderReduceMotionAndLowPower() {
        #expect(!PofuFrameRule.isPaused(kind: .essential, requested: false, active: true, reduceMotion: true, lowPower: true))
        #expect(PofuFrameRule.isPaused(kind: .essential, requested: true, active: true, reduceMotion: false, lowPower: false))
        #expect(PofuFrameRule.isPaused(kind: .essential, requested: false, active: false, reduceMotion: false, lowPower: false))
    }

    @Test func intervalNeverExceedsSixtyHertz() {
        #expect(PofuFrameRule.interval(hz: 120) == 1.0 / 60.0)
        #expect(PofuFrameRule.interval(hz: 15) == 1.0 / 15.0)
        #expect(PofuFrameRule.interval(hz: 0) == 1.0)
    }

    /// Every continuous timeline in the three packages goes through `PofuTimeline`; a bare `TimelineView`
    /// with `.animation` is display rate. Clock timers (`.periodic`, `.everyMinute`) are not redraw loops.
    @Test func noBareAnimationTimelines() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources")
        var scanned = 0
        var offenders: [String] = []
        for target in ["PofuWorld", "PofuCompanion", "PofuDesignSystem"] {
            let dir = sources.appendingPathComponent(target)
            let files = try #require(FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil))
            for case let url as URL in files where url.pathExtension == "swift" {
                if url.lastPathComponent == "PofuTimeline.swift" { continue }
                scanned += 1
                let text = try String(contentsOf: url, encoding: .utf8)
                for (n, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
                where line.contains("TimelineView(") && line.contains(".animation") && !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                    offenders.append("\(target)/\(url.lastPathComponent):\(n + 1)")
                }
            }
        }
        #expect(scanned > 50)
        #expect(offenders.isEmpty, "use PofuTimeline: \(offenders)")
    }

    /// Nothing asks for 120 Hz, so the plist key that unlocks it stays out.
    @Test func infoPlistDoesNotUnlockProMotion() throws {
        let plist = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Config/Info.plist")
        let text = try String(contentsOf: plist, encoding: .utf8)
        #expect(!text.contains("CADisableMinimumFrameDurationOnPhone"))
    }
}
