import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// The player-path frames (`path-dNN-*`) are the studio's truth for the
/// look: every one of them must be the painted world, never the sprite
/// island. The frames are rendered on iOS only; this guards on any
/// platform that the painted Home exists for every state the path reaches,
/// and that the path's look keeps the paintings on.
@Suite("Player path plates")
struct PlayerPathPlateTests {
    static let path = PlayerPath.tester()

    @Test func theLookOfAPathFrameHasThePaintingsOn() {
        let look = WorldLook.playerPath(hour: 9)
        #expect(look.homePlates, "a path frame never renders the sprite island")
        #expect(look.hourOverride == 9)
        #expect(look.weatherOverride == nil, "the weather is the run's own seeded day")
    }

    @Test func everyPathHomeIsAPainting() throws {
        let plate = try #require(HomePlate.shipped)
        for day in Self.path {
            for (name, world, hour) in [("09:00", day.morning, 9.0), ("23:00", day.night, 23.0)] {
                let resolved = HomePlate.resolve(plate, world: world, look: .playerPath(hour: hour), calendar: Calendar.current)
                #expect(resolved != nil, "day \(day.day) at \(name) (IL\(world.islandLevel)) has no painted Home")
            }
        }
    }
}
