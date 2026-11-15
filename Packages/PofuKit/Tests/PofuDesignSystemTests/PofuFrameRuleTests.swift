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

    @Test func touchIntervalReaches120OnlyUnderFinger() {
        #expect(PofuFrameRule.interval(hz: 120, underFinger: true) == 1.0 / 120.0)
        #expect(PofuFrameRule.interval(hz: 200, underFinger: true) == 1.0 / 120.0)
        #expect(PofuFrameRule.interval(hz: 60, underFinger: true) == 1.0 / 60.0)
        #expect(PofuFrameRule.interval(hz: 120, underFinger: false) == 1.0 / 60.0)
    }

    private func swiftSources() throws -> [(name: String, lines: [String])] {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources")
        var out: [(String, [String])] = []
        let files = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
        for case let url as URL in files where url.pathExtension == "swift" {
            let text = try String(contentsOf: url, encoding: .utf8)
            out.append((url.lastPathComponent, text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)))
        }
        return out
    }

    /// Only the Direct tier asks for more than 60 Hz: `underFinger:` is passed by the island's timeline alone,
    /// `PofuFrameRate.touch` is read only by the rule, the SpriteKit games ask for 30 and 60, and the measurement tool asks for 120.
    @Test func onlyTheDirectTierAsksFor120() throws {
        var underFinger: [String] = []
        var touch: [String] = []
        var ranges: [String] = []
        for (name, lines) in try swiftSources() {
            for (n, raw) in lines.enumerated() {
                let line = raw.trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("//") { continue }
                let at = "\(name):\(n + 1)"
                if line.contains("underFinger: policy.hz") { underFinger.append(at) }
                if line.contains("PofuFrameRate.touch") { touch.append(at) }
                if line.contains("preferredFrameRateRange") || line.contains("preferredFramesPerSecond") { ranges.append(name) }
            }
        }
        #expect(underFinger.count == 1 && underFinger[0].hasPrefix("IslandScene.swift"), "\(underFinger)")
        #expect(touch.allSatisfy { $0.hasPrefix("PofuTimeline.swift") }, "\(touch)")
        // The two SpriteKit games ask for 30 and 60 (never more).
        #expect(Set(ranges) == ["FrameMeter.swift", "FlowGameView.swift", "GardenGameView.swift"], "\(ranges)")
    }

    /// The plist key that unlocks 120 Hz is present, and says who may use it.
    @Test func infoPlistUnlocksProMotionForFramePolicy() throws {
        let plist = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Config/Info.plist")
        let text = try String(contentsOf: plist, encoding: .utf8)
        #expect(text.contains("CADisableMinimumFrameDurationOnPhone"))
        #expect(text.contains("FramePolicy"))
    }
}
