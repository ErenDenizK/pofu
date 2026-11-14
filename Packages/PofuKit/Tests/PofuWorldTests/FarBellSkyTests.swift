import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// The far bell's notes in the sky (docs/design/days-17-21-v1.md, PR 2).
@Suite("Far bell sky")
struct FarBellSkyTests {
    @Test func theLightIsInTheSkyOverTheIsland() throws {
        let plate = try #require(PlateIsland.load("home"))
        let p = FarBellSky.light
        #expect(p.x > 0 && p.x < plate.plateSize.maxX)
        #expect(p.y > 0 && p.y < plate.islandBox.minY, "above the island's top")
    }

    @Test func theLightGrowsByTheNight() {
        let steps = (1...4).compactMap { FarBellSky.glow(step: $0, bellDay: false) }
        let bell = FarBellSky.glow(step: nil, bellDay: true)
        #expect(steps.count == 4)
        let all = steps + [bell ?? 0]
        for (a, b) in zip(all, all.dropFirst()) { #expect(a < b) }
        #expect(abs(steps[0] - 0.35) < 1e-9 && abs(steps[3] - 0.8) < 1e-9 && bell == 1.0)
        #expect(FarBellSky.glow(step: nil, bellDay: false) == nil)
    }

    @Test func aRingLivesOncePerNote() throws {
        for isFar in [true, false] {
            let note = FarBellTune.Note(step: 0, at: 0.5, isFar: isFar)
            #expect(FarBellSky.ring(note: note, age: 0.49, reduceMotion: false) == nil)
            #expect(FarBellSky.ring(note: note, age: 0.5 + FarBellSky.ringLife + 0.01, reduceMotion: false) == nil)
            let early = try #require(FarBellSky.ring(note: note, age: 0.6, reduceMotion: false))
            let late = try #require(FarBellSky.ring(note: note, age: 1.4, reduceMotion: false))
            #expect(early.radius < late.radius)
            #expect(early.opacity > late.opacity)
            let end = try #require(FarBellSky.ring(note: note, age: 0.5 + FarBellSky.ringLife, reduceMotion: false))
            #expect(end.opacity < 1e-9)
        }
    }

    @Test func noRingUnderReduceMotion() {
        let note = FarBellTune.Note(step: 0, at: 0, isFar: true)
        #expect(FarBellSky.ring(note: note, age: 0.5, reduceMotion: true) == nil)
    }
}

@Suite("Far bell sky, seen")
struct FarBellSkySeenTests {
    @Test func theFarRingIsBigAndTheLightIsAHalo() throws {
        let note = FarBellTune.Note(step: 0, at: 0, isFar: true)
        let end = try #require(FarBellSky.ring(note: note, age: FarBellSky.ringLife * 0.99, reduceMotion: false))
        #expect(end.radius > 80)
        #expect(FarBellSky.haloRadius(glow: 0.35) > 20)
        #expect(FarBellSky.haloRadius(glow: 0.35) < FarBellSky.haloRadius(glow: 1.0))
    }

    @Test func thePulseIsSlowAndStillUnderReduceMotion() {
        for t in stride(from: 0.0, to: 10.0, by: 0.37) {
            #expect(FarBellSky.pulse(at: t, reduceMotion: true) == 1)
            let p = FarBellSky.pulse(at: t, reduceMotion: false)
            #expect(p >= 0.78 - 1e-9 && p <= 1 + 1e-9)
        }
    }
}
