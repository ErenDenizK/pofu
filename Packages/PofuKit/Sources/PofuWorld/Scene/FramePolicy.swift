import Foundation
import Observation

// The frame-rate policy (`docs/design/experience-v1.md` §4): what rate the
// world draws at, and which effects run, by what the player is doing, the
// Low Power Mode setting and the thermal state. Pure and tested; the scene's
// `TimelineView` reads `WorldPower.directive` for its interval and pause.

/// What the world is doing, in the order of §4.1's table.
public enum FrameState: String, CaseIterable, Hashable, Sendable {
    /// Finger down, pinch, momentum, flight, brush impulses.
    case direct
    /// A build, collect, reward payoff, rack focus.
    case moment
    /// The visit window after an arrival or a touch: sway, particles,
    /// flicker, sky drift.
    case ambient
    /// Nothing moves: the frame is cached and the timeline is paused.
    case settled
    /// A sheet or cover is up: the world is flattened and still.
    case covered
    /// A garden round; the world is unloaded.
    case minigame
    /// The scene is not active.
    case background
}

/// The iOS thermal state, without Foundation's platform-specific type.
public enum ThermalLevel: Int, Comparable, Hashable, Sendable {
    case nominal, fair, serious, critical

    public static func < (a: ThermalLevel, b: ThermalLevel) -> Bool { a.rawValue < b.rawValue }
}

/// What the player and the scene are asking for right now. The highest
/// applicable state wins (`FramePolicy.state(for:)`).
public struct FrameDemand: Hashable, Sendable {
    public var isActive = true
    public var isCovered = false
    public var isMinigame = false
    /// Finger down, pinch, momentum, flight, brush impulses.
    public var isDirect = false
    /// Build, collect, reward payoff, rack focus.
    public var isMoment = false
    /// Inside the visit window after an arrival or a touch.
    public var isVisiting = false

    public init(
        isActive: Bool = true,
        isCovered: Bool = false,
        isMinigame: Bool = false,
        isDirect: Bool = false,
        isMoment: Bool = false,
        isVisiting: Bool = false
    ) {
        self.isActive = isActive
        self.isCovered = isCovered
        self.isMinigame = isMinigame
        self.isDirect = isDirect
        self.isMoment = isMoment
        self.isVisiting = isVisiting
    }
}

/// The system's say: Low Power Mode, the (held) thermal state, Reduce
/// Motion.
public struct FrameConditions: Hashable, Sendable {
    public var lowPower = false
    public var thermal: ThermalLevel = .nominal
    public var reduceMotion = false

    public init(lowPower: Bool = false, thermal: ThermalLevel = .nominal, reduceMotion: Bool = false) {
        self.lowPower = lowPower
        self.thermal = thermal
        self.reduceMotion = reduceMotion
    }

    public static let nominal = FrameConditions()
}

/// A frame-rate request, in the shape of `CAFrameRateRange`.
public struct FrameRateRange: Hashable, Sendable {
    public var minimum: Double
    public var maximum: Double
    public var preferred: Double

    public init(minimum: Double, maximum: Double, preferred: Double) {
        self.minimum = minimum
        self.maximum = maximum
        self.preferred = preferred
    }
}

/// What the scene does in a state under the conditions.
public struct FrameDirective: Hashable, Sendable {
    /// The state the policy settled on, after Low Power and thermal limits
    /// (an Ambient request in Low Power Mode comes back `.settled`).
    public var state: FrameState
    /// Frames per second; 0 is paused, the frame cached.
    public var hz: Double
    /// The requested range, for the display link or the `SKView`.
    public var range: FrameRateRange
    /// The depth-of-field pass; never during Direct.
    public var depthOfField: Bool
    /// Pollen and fireflies.
    public var particles: Bool
    /// The sun's light shafts.
    public var shafts: Bool
    /// The lantern's flicker (the Ambient state only).
    public var flicker: Bool
    /// The world is drawn flat and still, for the sheet's glass to sample.
    public var flattensWorld: Bool

    public var isPaused: Bool { hz <= 0 }

    /// The `TimelineView` interval, in seconds: 1/hz, or a harmless 1/30
    /// while paused (the timeline's `paused` flag stops it anyway).
    public var timelineInterval: Double { hz > 0 ? 1 / hz : 1.0 / 30.0 }
}

/// The policy's numbers. Tunable; `directRate` is 60 for the beta and moves
/// to 120 after measurement (§4.1).
public struct FramePolicy: Hashable, Sendable {
    public var directRate = 60.0
    public var momentRate = 60.0
    public var ambientRate = 30.0
    public var minigameRate = 60.0
    /// The ambient visit window, in seconds (§4.1: about 8).
    public var visitSeconds = 8.0
    /// How long the system must stay at a lower thermal state before the
    /// policy steps back up.
    public var stepUpSeconds = 30.0

    public init() {}

    public static let standard = FramePolicy()

    /// The state for a demand: background beats covered beats a minigame
    /// beats Direct, Moment, Ambient and Settled.
    public func state(for demand: FrameDemand) -> FrameState {
        if !demand.isActive { return .background }
        if demand.isCovered { return .covered }
        if demand.isMinigame { return .minigame }
        if demand.isDirect { return .direct }
        if demand.isMoment { return .moment }
        if demand.isVisiting { return .ambient }
        return .settled
    }

    /// What to do in `state` under `conditions`: the tables of §4.1.
    public func directive(for state: FrameState, conditions: FrameConditions = .nominal) -> FrameDirective {
        let lowPower = conditions.lowPower
        let thermal = conditions.thermal
        let serious = thermal >= .serious
        let critical = thermal >= .critical

        var effective = state
        var hz: Double
        switch state {
        case .direct:
            hz = directRate
            if lowPower || thermal >= .fair { hz = min(hz, 60) }
            if critical { hz = min(hz, 30) }
        case .moment:
            hz = momentRate
            if serious { hz = min(hz, 30) }
        case .ambient:
            // Low Power Mode, a serious thermal state and Reduce Motion skip
            // Ambient: straight to Settled. Critical shows the settled world.
            if lowPower || serious || conditions.reduceMotion {
                effective = .settled
                hz = 0
            } else {
                hz = ambientRate
            }
        case .minigame:
            hz = minigameRate
            if serious { hz = min(hz, 30) }
        case .settled, .covered, .background:
            hz = 0
        }
        if critical && hz > 30 { hz = 30 }

        let live = effective != .covered && effective != .background
        let calmEffects = !lowPower && !serious
        return FrameDirective(
            state: effective,
            hz: hz,
            range: range(hz: hz, state: effective),
            depthOfField: live && effective != .direct && effective != .minigame && calmEffects,
            particles: live && effective != .minigame && calmEffects,
            shafts: live && effective != .minigame && calmEffects,
            flicker: effective == .ambient,
            flattensWorld: effective == .covered
        )
    }

    /// The directive for a demand in one step.
    public func directive(for demand: FrameDemand, conditions: FrameConditions = .nominal) -> FrameDirective {
        directive(for: state(for: demand), conditions: conditions)
    }

    private func range(hz: Double, state: FrameState) -> FrameRateRange {
        guard hz > 0 else { return FrameRateRange(minimum: 0, maximum: 0, preferred: 0) }
        // Direct asks for the display's top rate when it can have it.
        if state == .direct, hz > 60 {
            return FrameRateRange(minimum: 80, maximum: hz, preferred: hz)
        }
        return FrameRateRange(minimum: min(hz, 30), maximum: hz, preferred: hz)
    }

    /// Ambient time is quantised to 1/30 s, so sway and particles step at
    /// the rate the policy draws them.
    public static func ambientTime(_ t: Double) -> Double {
        guard t.isFinite else { return 0 }
        return (t * 30).rounded(.down) / 30
    }
}

/// Holds the thermal state with a hysteresis: a rise is taken at once, a
/// fall only after the system has stayed lower for `stepUpSeconds`, so the
/// policy never oscillates.
public struct ThermalGovernor: Hashable, Sendable {
    public private(set) var held: ThermalLevel
    private var lowerSince: Double?
    public var stepUpSeconds: Double

    public init(held: ThermalLevel = .nominal, stepUpSeconds: Double = FramePolicy.standard.stepUpSeconds) {
        self.held = held
        self.stepUpSeconds = stepUpSeconds
    }

    /// Feeds an observation at `time` (seconds, any monotonic clock) and
    /// returns the level to act on.
    @discardableResult
    public mutating func observe(_ level: ThermalLevel, at time: Double) -> ThermalLevel {
        if level >= held {
            held = level
            lowerSince = nil
        } else if let since = lowerSince {
            if time - since >= stepUpSeconds {
                held = level
                lowerSince = nil
            }
        } else {
            lowerSince = time
        }
        return held
    }
}

/// The world's power state: Low Power Mode, the held thermal state, Reduce
/// Motion and what the scene is asking for. The scene sets `demand`; its
/// `TimelineView` reads `directive`. Observable, so a change of directive
/// re-evaluates the views that read it.
@MainActor
@Observable
public final class WorldPower {
    public var policy: FramePolicy
    /// What the scene is asking for. Set the fields as they change.
    public var demand = FrameDemand()
    public private(set) var conditions: FrameConditions
    private var governor: ThermalGovernor
    /// The visit window's end, on `clock`; nil outside a visit.
    private var visitEnd: Double?
    @ObservationIgnored private let clock: @MainActor () -> Double
    #if os(iOS)
    @ObservationIgnored var systemObservers: [NSObjectProtocol] = []
    @ObservationIgnored var stepUpTask: Task<Void, Never>?
    #endif

    public init(
        policy: FramePolicy = .standard,
        conditions: FrameConditions = .nominal,
        clock: @escaping @MainActor () -> Double = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.policy = policy
        self.conditions = conditions
        self.governor = ThermalGovernor(held: conditions.thermal, stepUpSeconds: policy.stepUpSeconds)
        self.clock = clock
    }

    /// The directive now: the demand (with the visit window applied) under
    /// the held conditions.
    public var directive: FrameDirective {
        var d = demand
        d.isVisiting = d.isVisiting || isInVisit
        return policy.directive(for: d, conditions: conditions)
    }

    /// Whether the timeline needs to run (the `needsFrames` seam).
    public var needsFrames: Bool { !directive.isPaused }

    /// An arrival or a touch: opens (or extends) the visit window.
    public func beginVisit() {
        visitEnd = clock() + policy.visitSeconds
    }

    /// Whether the visit window is open now.
    public var isInVisit: Bool {
        guard let visitEnd else { return false }
        return clock() < visitEnd
    }

    /// Feeds the system's state. The thermal level goes through the
    /// hysteresis; Low Power Mode and Reduce Motion apply at once.
    public func update(lowPower: Bool, thermal: ThermalLevel, reduceMotion: Bool) {
        let held = governor.observe(thermal, at: clock())
        let next = FrameConditions(lowPower: lowPower, thermal: held, reduceMotion: reduceMotion)
        if next != conditions { conditions = next }
    }
}

#if os(iOS)
import QuartzCore
import UIKit

extension ThermalLevel {
    public init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .serious
        }
    }
}

extension FrameRateRange {
    public var caRange: CAFrameRateRange {
        CAFrameRateRange(minimum: Float(minimum), maximum: Float(maximum), preferred: Float(preferred))
    }
}

extension WorldPower {
    /// Reads the system's state now and again whenever Low Power Mode, the
    /// thermal state or Reduce Motion changes. Call once from the scene's
    /// host; the observers live as long as this object does.
    public func startObservingSystem() {
        guard systemObservers.isEmpty else { return }
        refresh()
        let names: [Notification.Name] = [
            .NSProcessInfoPowerStateDidChange,
            ProcessInfo.thermalStateDidChangeNotification,
            UIAccessibility.reduceMotionStatusDidChangeNotification,
        ]
        systemObservers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }

    func refresh() {
        let info = ProcessInfo.processInfo
        update(
            lowPower: info.isLowPowerModeEnabled,
            thermal: ThermalLevel(info.thermalState),
            reduceMotion: UIAccessibility.isReduceMotionEnabled
        )
        // A fall in the thermal state is taken only after `stepUpSeconds`
        // lower, and nothing else wakes us then: look again.
        if ThermalLevel(info.thermalState) < conditions.thermal, stepUpTask == nil {
            let wait = policy.stepUpSeconds + 1
            stepUpTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(wait))
                guard !Task.isCancelled else { return }
                self?.stepUpTask = nil
                self?.refresh()
            }
        }
    }
}
#endif
