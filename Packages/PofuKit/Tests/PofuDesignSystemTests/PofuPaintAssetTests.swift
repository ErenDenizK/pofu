import Foundation
import Testing
@testable import PofuDesignSystem

/// Every painted case names a baked PNG in the package's resources, so a case never falls back to
/// its symbol because of a typo or a missing bake.
struct PofuPaintAssetTests {
    private static let resources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/PofuDesignSystem/Resources")

    @Test func everyPaintCaseHasItsPNG() {
        for paint in PofuPaint.allCases {
            let file = Self.resources.appendingPathComponent("\(paint.rawValue).png")
            #expect(FileManager.default.fileExists(atPath: file.path), "\(paint.rawValue)")
        }
    }

    @Test func theBatch128IconsAreAllCases() {
        let names = "sound wind sprout tea key list cloud star breath wand hourglass moon hand grid sun lantern calendar drop"
            .split(separator: " ")
        for name in names {
            #expect(PofuPaint(rawValue: "paint-duo-\(name)") != nil, "\(name)")
        }
    }
}
