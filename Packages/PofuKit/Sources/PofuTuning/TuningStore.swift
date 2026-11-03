import Foundation
import Observation

/// The live tuning values: the bundled defaults with the founder's
/// changes laid over them. Changes persist on this device only (they are a
/// tuning session, not user data) as flat keys, so a renamed value in a
/// later build drops its stale override instead of failing to load.
@MainActor
@Observable
public final class TuningStore {
    public private(set) var values: TuningValues {
        didSet { flat = values.flattened() }
    }
    public let defaults: TuningValues
    /// `values` as flat keys, cached for the panel's many rows.
    public private(set) var flat: [String: Double]

    private let defaultFlat: [String: Double]
    private let storage: UserDefaults?
    private let storageKey: String

    /// Where overrides persist by default.
    nonisolated public static let defaultStorageKey = "tuning.overrides"
    /// The key before the English rename (2026-11-03); moved on first read.
    nonisolated static let legacyStorageKey = "ayar.overrides"

    /// - Parameters:
    ///   - defaults: The values "Sıfırla" returns to.
    ///   - storage: Where changes persist; `nil` keeps them in memory.
    public init(defaults: TuningValues = .defaults, storage: UserDefaults? = .standard, storageKey: String = TuningStore.defaultStorageKey) {
        self.defaults = defaults
        self.storage = storage
        self.storageKey = storageKey
        if storageKey == Self.defaultStorageKey, storage?.object(forKey: storageKey) == nil,
           let legacy = storage?.dictionary(forKey: Self.legacyStorageKey)
        {
            storage?.set(legacy, forKey: storageKey)
            storage?.removeObject(forKey: Self.legacyStorageKey)
        }
        let saved = storage?.dictionary(forKey: storageKey) ?? [:]
        let overrides = saved.compactMapValues { ($0 as? NSNumber)?.doubleValue }
        let values = TuningValues(base: defaults, overrides: overrides)
        self.values = values
        flat = values.flattened()
        defaultFlat = defaults.flattened()
    }

    /// The value at a flat key, or `nil` for an unknown key.
    public func value(_ key: String) -> Double? {
        flat[key]
    }

    public func defaultValue(_ key: String) -> Double? {
        defaultFlat[key]
    }

    /// Whether `key` differs from its default.
    public func isChanged(_ key: String) -> Bool {
        guard let value = flat[key], let original = defaultFlat[key] else { return false }
        return abs(value - original) > 1e-9
    }

    /// Sets a key, snapped to its spec.
    public func set(_ key: String, to value: Double) {
        let snapped = TuningSpec.spec(for: key)?.quantize(value) ?? value
        var next = flat
        guard let current = next[key], current != snapped else { return }
        next[key] = snapped
        values = TuningValues(base: defaults, overrides: next)
        save()
    }

    public func reset(_ key: String) {
        guard let original = defaultValue(key) else { return }
        set(key, to: original)
    }

    public func resetAll() {
        values = defaults
        save()
    }

    public var changes: [TuningChange] {
        values.changes(from: defaults)
    }

    /// The JSON "Dışa aktar" shares.
    public func exportJSON() -> String {
        TuningExport(values: values, defaults: defaults).json()
    }

    private func save() {
        guard let storage else { return }
        let changed = changes
        if changed.isEmpty {
            storage.removeObject(forKey: storageKey)
        } else {
            storage.set(Dictionary(uniqueKeysWithValues: changed.map { ($0.key, $0.value) }), forKey: storageKey)
        }
    }
}
