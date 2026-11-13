import Foundation
import PofuCore
import Testing

@testable import PofuWorld

/// The build speaks with one voice: one word for the seed in every
/// catalogue, a met goal that says the level is ready, a wonder island's
/// state, and the Today header's painting.
@Suite struct OneVoiceTests {
    /// Every Turkish value of the app's and the world's string catalogues.
    private func turkishValues() throws -> [(key: String, value: String)] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let paths = [
            root.appendingPathComponent("App/Resources/Localizable.xcstrings"),
            root.appendingPathComponent("Packages/PofuKit/Sources/PofuWorld/Resources/Localizable.xcstrings"),
        ]
        var out: [(String, String)] = []
        for path in paths {
            let data = try Data(contentsOf: path)
            let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            let strings = try #require(json["strings"] as? [String: Any])
            for (key, entry) in strings {
                guard let loc = (entry as? [String: Any])?["localizations"] as? [String: Any], let tr = loc["tr"] else { continue }
                collect(tr, key: key, into: &out)
            }
        }
        return out
    }

    private func collect(_ node: Any, key: String, into out: inout [(String, String)]) {
        if let dict = node as? [String: Any] {
            if let value = dict["value"] as? String { out.append((key, value)) }
            for child in dict.values { collect(child, key: key, into: &out) }
        }
    }

    /// The seed is "çekirdek" everywhere (docs/product/economy.md, the voice
    /// guide, the jar): no "tohum" in a Turkish string.
    @Test func theSeedHasOneTurkishWord() throws {
        let values = try turkishValues()
        #expect(values.count > 100)
        let stray = values.filter { $0.value.lowercased().contains("tohum") }
        #expect(stray.isEmpty, "\(stray.map(\.key))")
        #expect(values.contains { $0.key.contains("seeds in the jar") && $0.value.contains("çekirdek") })
    }

    @Test func aMetGoalSaysTheLevelIsReady() {
        let met = IslandLevelRequirement(level: 4, tendedDaysLeft: 0, levelsLeft: 0)
        #expect(GoalLine(met) == .ready(island: 4))
        #expect(GoalLine(IslandLevelRequirement(level: 4, tendedDaysLeft: 0, levelsLeft: 2)) == .levels(island: 4, left: 2))
        #expect(GoalLine(IslandLevelRequirement(level: 4, tendedDaysLeft: 3, levelsLeft: 0)) == .days(island: 4, left: 3))
        #expect(GoalLine(IslandLevelRequirement(level: 4, tendedDaysLeft: 1, levelsLeft: 1)) == .levels(island: 4, left: 1))
    }

    @Test func aWonderIslandSaysItsState() {
        #expect(WonderState(stage: 0) == .asleep)
        #expect(WonderState(stage: 1) == .healing(stage: 1))
        #expect(WonderState(stage: 3) == .healing(stage: 3))
        #expect(WonderState(stage: WonderIslands.healedStage) == .healed)
    }

    @Test func theTodayHeaderFindsThePaintingOfTheHour() {
        guard let day = HomePlateCrop.artName(islandLevel: 5, hour: 12) else {
            Issue.record("no painting for level 5 by day")
            return
        }
        #expect(day.contains("day"))
        let night = HomePlateCrop.artName(islandLevel: 5, hour: 23)
        #expect(night != nil && night != day)
        let fit = HomePlateCrop.fill(plateWidth: 1000, plateHeight: 1500, in: CGSize(width: 300, height: 140))
        #expect(fit.image.width >= 300 && fit.image.height >= 140)
        #expect(fit.y <= 0 && fit.y + fit.image.height >= 140)
    }
}

/// One Turkish word for each game idea the trial shows: a reach is the door
/// knocking ("kapı çaldı"), never "açma isteği" or "uzanma"; letting one go
/// is "Boş ver", never "atlamak".
@Suite struct OneWordPerIdeaTests {
    @Test func aReachAndASkipHaveOneTurkishWordEach() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let paths = [
            "App/Resources/Localizable.xcstrings",
            "Packages/PofuKit/Sources/PofuWorld/Resources/Localizable.xcstrings",
            "Packages/PofuKit/Sources/PofuGames/Resources/Localizable.xcstrings",
        ]
        let banned = ["açma isteği", "uzanma", "uzanış", "atlayış", "atlamak"]
        var stray: [String] = []
        for path in paths {
            let text = try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8).lowercased()
            for word in banned where text.contains(word) {
                stray.append("\(path): \(word)")
            }
        }
        #expect(stray.isEmpty, "\(stray)")
    }
}
