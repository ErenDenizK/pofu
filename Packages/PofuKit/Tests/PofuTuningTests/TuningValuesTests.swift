import Foundation
import Testing
@testable import PofuTuning

@Suite("Tuning values")
struct TuningValuesTests {
    @Test func theBundledDefaultsDecode() throws {
        let values = try TuningValues.bundled()
        #expect(values == TuningValues.defaults)
    }

    /// The defaults match the constants in the code today, so the panel
    /// starts from what the founder already sees (`WorldSprings`,
    /// `LookTuning`, `BreathingCurve`, the haptics in Home and Hop!).
    @Test func theDefaultsAreTodaysConstants() {
        let d = TuningValues.defaults
        #expect(d.camera.travel == .init(duration: 0.90, bounce: 0.10))
        #expect(d.camera.far == .init(duration: 1.10, bounce: 0.08))
        #expect(d.camera.release == .init(duration: 0.55, bounce: 0.08))
        #expect(d.camera.focus == .init(duration: 0.70, bounce: 0.12))
        #expect(d.camera.buildPush == .init(duration: 0.60, bounce: 0.10))
        #expect(d.depth.parallax == 1)
        #expect(d.depth.tiltShiftIsland == 1.7)
        #expect(d.depth.tiltShiftHome == 1.3)
        #expect(d.companion.breathPeriodLow == 4.6)
        #expect(d.companion.breathPeriodHigh == 3.3)
        #expect(d.companion.breathAmplitudeLow == 0.024)
        #expect(d.companion.breathAmplitudeHigh == 0.016)
        #expect(d.haptics.pofuTap == 0.7)
        #expect(d.haptics.collectTap == 0.5)
        #expect(d.haptics.hopAppearDay == 0.6)
        #expect(d.haptics.hopAppearNight == 0.35)
    }

    /// `PofuWorld.HomeTiming` carries the same defaults (PofuWorld does not
    /// link PofuTuning, so the numbers are mirrored and pinned here).
    @Test func theHomeDefaultsMatchHomeTiming() {
        let home = TuningValues.defaults.home
        #expect(home.pawsPress == 0.3)
        #expect(home.cheekRelease == 0.45)
        #expect(home.jarFill == 0.6)
        #expect(home.lanternGlow == 1.2)
        #expect(home.potBloom == 0.5)
        #expect(home.jarCapacity == 120)
    }

    @Test func theGradeTrimsStartAsTheIdentity() {
        let grade = TuningValues.defaults.grade
        #expect(grade.day == .identity)
        #expect(grade.golden == .identity)
        #expect(grade.night == .identity)
    }

    @Test func valuesRoundTripThroughJSON() throws {
        var values = TuningValues.defaults
        values.camera.travel.duration = 0.75
        values.grade.night.warmth = -0.2
        let data = try JSONEncoder().encode(values)
        #expect(try JSONDecoder().decode(TuningValues.self, from: data) == values)
    }

    @Test func flatKeysRoundTrip() throws {
        let flat = TuningValues.defaults.flattened()
        #expect(flat["camera.travel.duration"] == 0.9)
        #expect(flat["grade.golden.saturation"] == 1)
        #expect(try TuningValues(flat: flat) == .defaults)
    }

    @Test func everyKeyHasExactlyOneSpecAndItsDefaultIsInRange() {
        let flat = TuningValues.defaults.flattened()
        let specKeys = TuningSpec.all.map(\.key)
        #expect(Set(specKeys).count == specKeys.count)
        #expect(Set(specKeys) == Set(flat.keys))
        for spec in TuningSpec.all {
            let value = flat[spec.key] ?? .nan
            #expect(spec.range.contains(value), "\(spec.key) = \(value) is outside \(spec.range)")
            #expect(spec.quantize(value) == value, "\(spec.key) default is off its step")
        }
    }

    @Test func overridesIgnoreUnknownKeysAndNonFiniteValues() {
        let values = TuningValues(
            base: .defaults,
            overrides: ["camera.travel.bounce": 0.2, "camera.oldSpring.duration": 3, "depth.parallax": .nan]
        )
        #expect(values.camera.travel.bounce == 0.2)
        #expect(values.depth.parallax == 1)
        #expect(values.changes(from: .defaults).map(\.key) == ["camera.travel.bounce"])
    }

    @Test func quantizeClampsSnapsAndCleansFloatNoise() throws {
        let spec = try #require(TuningSpec.spec(for: "camera.travel.duration"))
        #expect(spec.quantize(0.8312) == 0.85)
        #expect(spec.quantize(9) == 2.5)
        #expect(spec.quantize(-1) == 0.15)
        let warmth = try #require(TuningSpec.spec(for: "grade.day.warmth"))
        #expect(warmth.quantize(0.3) == 0.3)
        #expect(warmth.quantize(-0.071) == -0.08)
    }

    @Test func gradeTrimsBlendByWeight() {
        let warm = TuningValues.GradeTrim(exposure: 1.2, warmth: 0.5)
        let blended = TuningValues.GradeTrim.blend([(warm, 0.5), (.identity, 0.5)])
        #expect(abs(blended.exposure - 1.1) < 1e-12)
        #expect(abs(blended.warmth - 0.25) < 1e-12)
        #expect(TuningValues.GradeTrim.blend([(.identity, 1)]) == .identity)
    }
}

@Suite("Tuning export and store")
@MainActor
struct TuningStoreTests {
    @Test func anUntouchedExportHasNoChanges() throws {
        let export = try TuningExport.decode(TuningExport(values: .defaults).json())
        #expect(export.kind == "pofu-tuning")
        #expect(export.schema == 1)
        #expect(export.changed.isEmpty)
        #expect(export.values == .defaults)
    }

    @Test func theExportListsChangesAndCarriesTheCompleteValues() throws {
        let store = TuningStore(storage: nil)
        store.set("camera.travel.duration", to: 0.8)
        store.set("haptics.pofuTap", to: 0.9)
        let json = store.exportJSON()
        #expect(json.contains("\"camera.travel.duration\""))
        #expect(json.contains("\"default\" : 0.9"))
        let export = try TuningExport.decode(json)
        #expect(export.changed.count == 2)
        #expect(export.changed["camera.travel.duration"] == .init(defaultValue: 0.9, value: 0.8))
        #expect(export.values.camera.travel.duration == 0.8)
        #expect(export.values.haptics.pofuTap == 0.9)
    }

    @Test func setSnapsToTheSpecAndResetReturnsToTheDefault() {
        let store = TuningStore(storage: nil)
        store.set("camera.focus.bounce", to: 0.2349)
        #expect(store.values.camera.focus.bounce == 0.23)
        store.reset("camera.focus.bounce")
        #expect(store.values == .defaults)
        store.set("depth.parallax", to: 1.5)
        store.set("grade.night.exposure", to: 1.1)
        #expect(store.changes.count == 2)
        store.resetAll()
        #expect(store.changes.isEmpty)
    }

    @Test func changesPersistAndReload() throws {
        let suite = "TuningStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = TuningStore(storage: defaults)
        store.set("companion.breathPeriodLow", to: 5.2)
        let reloaded = TuningStore(storage: defaults)
        #expect(reloaded.values.companion.breathPeriodLow == 5.2)
        reloaded.resetAll()
        #expect(defaults.dictionary(forKey: TuningStore.defaultStorageKey) == nil)
    }

    @Test func overridesSavedUnderTheOldKeyMoveToTheNewOne() throws {
        let suite = "TuningStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["companion.breathPeriodLow": 5.2], forKey: "ayar.overrides")
        let store = TuningStore(storage: defaults)
        #expect(store.values.companion.breathPeriodLow == 5.2)
        #expect(defaults.dictionary(forKey: "ayar.overrides") == nil)
        #expect(defaults.dictionary(forKey: TuningStore.defaultStorageKey) != nil)
    }
}
