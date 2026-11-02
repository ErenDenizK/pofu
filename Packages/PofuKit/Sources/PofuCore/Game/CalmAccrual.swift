import Foundation

/// How an open changed calm.
public struct CalmChange: Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable, Codable {
        /// A quick check: the bonus halved.
        case quickCheck
        /// Any other open, including a chained quick check: calm reset.
        case fullOpen
    }

    public var kind: Kind
    public var beforeTenths: Int
    public var afterTenths: Int

    public init(kind: Kind, beforeTenths: Int, afterTenths: Int) {
        self.kind = kind
        self.beforeTenths = beforeTenths
        self.afterTenths = afterTenths
    }

    /// Whether calm actually went down (it cannot below ×1.0).
    public var lowered: Bool {
        afterTenths < beforeTenths
    }
}

/// The calm multiplier (*huzur*): ×1.0 to ×2.0, growing with observed calm
/// time (game design §5, ADR-0015).
///
/// - **Growth:** +0.1 per `stepMinutes` of continuous calm waking time.
///   Only time Pofu observes away from the guarded apps counts; unobserved
///   time and time spent looking at Pofu past the grace (A20) grow
///   nothing. Bedtime holds the run; a calm night adds +0.2.
/// - **Quick check** (a pass of 3 minutes or less): the bonus halves,
///   rounded down to 0.1 (×1.6 → ×1.3, ×2.0 → ×1.5). A quick check that
///   starts less than 20 minutes after the previous one's end counts as a
///   full open.
/// - **Full open:** any other open, including the emergency pass and a
///   friend's: calm resets to ×1.0.
///
/// Calm is kept in integer tenths, so every rule is exact.
public struct CalmAccrual: Hashable, Sendable, Codable {
    /// Calm in tenths: 10 is ×1.0, 20 is ×2.0.
    public internal(set) var tenths: Int
    /// Continuous calm waking minutes toward the next step.
    public internal(set) var runMinutes: Int
    /// When the last short pass (a quick check or a chained one) ends, for
    /// the chain rule.
    public internal(set) var lastQuickCheckEnd: Date?

    public init(rules: CalmRules = CalmRules()) {
        self.init(tenths: rules.minimumTenths, rules: rules)
    }

    public init(tenths: Int, rules: CalmRules = CalmRules()) {
        self.tenths = Self.clamped(tenths, rules)
        self.runMinutes = 0
        self.lastQuickCheckEnd = nil
    }

    /// Calm as a multiplier, ×1.0 to ×2.0.
    public var multiplier: Double {
        Double(tenths) / 10
    }

    /// Whether calm is at its maximum.
    public func isFull(rules: CalmRules) -> Bool {
        tenths >= rules.maximumTenths
    }

    /// How far the ring has filled toward the next +0.1, `0..<1`; 1 when
    /// calm is full.
    public func progressToNextStep(rules: CalmRules) -> Double {
        guard !isFull(rules: rules) else { return 1 }
        guard rules.stepMinutes > 0 else { return 0 }
        return Double(runMinutes % rules.stepMinutes) / Double(rules.stepMinutes)
    }

    // MARK: - Changes

    /// One minute of observed calm waking time.
    ///
    /// - Returns: Whether calm grew a step.
    @discardableResult
    public mutating func calmMinute(rules: CalmRules) -> Bool {
        runMinutes += 1
        guard rules.stepMinutes > 0, runMinutes % rules.stepMinutes == 0, tenths < rules.maximumTenths else {
            return false
        }
        tenths = Self.clamped(tenths + 1, rules)
        return true
    }

    /// The continuous run broke: a guarded app is open, or the time is
    /// unobserved. Calm itself stays; only the progress toward the next
    /// step is lost.
    public mutating func breakRun() {
        runMinutes = 0
    }

    /// A guarded app opened at `startedAt` with a pass of `passMinutes`.
    @discardableResult
    public mutating func opened(passMinutes: Int, isEmergency: Bool, startedAt: Date, rules: CalmRules) -> CalmChange {
        let before = tenths
        let isShort = passMinutes <= rules.quickCheckMinutes
        let chained = lastQuickCheckEnd.map { startedAt.timeIntervalSince($0) < rules.quickCheckChain } ?? false
        let kind: CalmChange.Kind = isShort && !isEmergency && !chained ? .quickCheck : .fullOpen
        switch kind {
        case .quickCheck:
            tenths = Self.halved(tenths, rules: rules)
        case .fullOpen:
            tenths = rules.minimumTenths
        }
        if isShort {
            lastQuickCheckEnd = startedAt.addingTimeInterval(TimeInterval(max(0, passMinutes)) * 60)
        }
        runMinutes = 0
        return CalmChange(kind: kind, beforeTenths: before, afterTenths: tenths)
    }

    /// A calm night: +0.2, up to the maximum.
    public mutating func calmNight(rules: CalmRules) {
        tenths = Self.clamped(tenths + rules.calmNightTenths, rules)
    }

    /// `tenths` with its bonus over ×1.0 halved, rounded down to a tenth.
    public static func halved(_ tenths: Int, rules: CalmRules) -> Int {
        let bonus = max(0, tenths - rules.minimumTenths)
        return clamped(rules.minimumTenths + bonus / 2, rules)
    }

    private static func clamped(_ tenths: Int, _ rules: CalmRules) -> Int {
        min(max(tenths, rules.minimumTenths), max(rules.minimumTenths, rules.maximumTenths))
    }
}
