import Foundation

/// The motion simulation behind `CompanionView`: idle life (breathing,
/// sway, blinks), reactions (tap squish, hop), and slow state (vitality,
/// cheek pouches), all on springs.
///
/// It is a value type with no clock of its own: the view advances it with
/// `step(_:)` from its display timeline, and tests advance it with fixed
/// steps. Every constant matches the web prototype in
/// `design/prototypes/companion-motion/index.html`; see
/// `docs/design/companion-motion.md` for the reasoning.
public struct CompanionMotion: Sendable {
    /// Gravity in character heights per second squared; snappy and toy-like.
    public static let gravity = 3.2

    /// Target vitality in `0...1`. Pofu eases toward it slowly.
    public var vitality: Double {
        get { vitalitySpring.target }
        set { vitalitySpring.target = clampUnit(newValue) }
    }

    /// Target cheek fill (stored energy) in `0...1`. Gaining energy makes
    /// Pofu gulp.
    public var energy: Double {
        get { cheekSpring.target }
        set {
            let value = clampUnit(newValue)
            if value > cheekSpring.target + 0.01 {
                squash.velocity -= 1.2
                react(happiness: 0.5, duration: 0.5)
            }
            cheekSpring.target = value
        }
    }

    /// Accessibility: no hops, sway, or ripple; expressions still change.
    public var reduceMotion = false

    /// Idle blinks. Screenshots turn them off, so a still frame never
    /// catches Pofu with his eyes shut; expressions still close the lids.
    public var blinks = true

    /// How he breathes and blinks (the tuning lab panel tunes it live).
    public var life = CompanionLife.standard

    public private(set) var time: Double = 0

    private var breathPhase: Double = 0
    private var squash = CompanionSpring(response: 0.42, dampingFraction: 0.28)
    private var vitalitySpring: CompanionSpring
    private var cheekSpring: CompanionSpring
    private var tuft = CompanionSpring(response: 0.7, dampingFraction: 0.22)
    private var lean = CompanionSpring(response: 0.9, dampingFraction: 0.5)
    private var happy = CompanionSpring(response: 0.22, dampingFraction: 0.9)
    private var blushSpring = CompanionSpring(response: 0.4, dampingFraction: 1)

    private var hopHeight: Double = 0
    private var hopVelocity: Double = 0
    private var airborne = false
    private var hopsLeft = 0
    private var hopTimer: Double?
    private var expressionUntil: Double?

    private var blinkStart: Double = -10
    private var nextBlink: Double
    private var random: CompanionRandom

    public init(vitality: Double = 0.8, energy: Double = 0.25, seed: UInt64 = 7) {
        vitalitySpring = CompanionSpring(value: clampUnit(vitality), response: 1.4, dampingFraction: 1)
        cheekSpring = CompanionSpring(value: clampUnit(energy), response: 0.55, dampingFraction: 0.38)
        random = CompanionRandom(seed: seed)
        nextBlink = 1.6
    }

    // MARK: - Events

    /// A tap: squish down, spring back with a jiggle, a happy squint.
    public mutating func tap() {
        squash.velocity -= 2.4
        tuft.velocity += 4
        react(happiness: 0.75, duration: 0.65)
    }

    /// A celebration: anticipation, two hops (the second smaller), happy
    /// eyes, blush. With Reduce Motion, only the expression changes.
    public mutating func celebrate() {
        react(happiness: 1, duration: 2)
        guard !reduceMotion else { return }
        hopsLeft = 2
        hopTimer = 0
    }

    /// Blink now.
    public mutating func blink() {
        blinkStart = time
    }

    private mutating func react(happiness: Double, duration: Double) {
        happy.target = happiness
        blushSpring.target = 1
        expressionUntil = max(expressionUntil ?? 0, time + duration)
    }

    // MARK: - Simulation

    /// Advances the simulation by `duration` seconds.
    public mutating func step(_ duration: Double) {
        guard duration.isFinite, duration > 0 else { return }
        let dt = min(duration, 0.1)
        time += dt
        let v = clampUnit(vitalitySpring.value)

        breathPhase += dt * 2 * Double.pi / BreathingCurve.period(vitality: v, life: life)
        stepHop(dt)

        if let until = expressionUntil, time > until {
            happy.target = 0
            blushSpring.target = 0
            expressionUntil = nil
        }

        // Blinks every 2.5–6 s (rarer when low), sometimes doubled.
        if time >= nextBlink {
            blinkStart = time
            let double = random.next() < 0.2
            let gap = double ? 0.32 : random.next(in: life.blinkRange) * lerp(1.4, 1, v)
            nextBlink = time + gap
        }

        // Idle sway: two incommensurate sines read as organic.
        let calm = reduceMotion ? 0.0 : 1.0
        let sway = sin(time * 0.83) * 0.6 + sin(time * 0.31 + 1.7) * 0.4
        lean.target = calm * sway * lerp(0.5, 1, v)
        // Follow-through: the tuft trails the body and droops when low.
        tuft.target = -lean.velocity * 0.25 - (1 - v) * 0.55

        squash.step(dt)
        vitalitySpring.step(dt)
        cheekSpring.step(dt)
        tuft.step(dt)
        lean.step(dt)
        happy.step(dt)
        blushSpring.step(dt)
    }

    private mutating func stepHop(_ dt: Double) {
        if var timer = hopTimer, !airborne {
            timer += dt
            hopTimer = timer
            squash.target = -0.13
            if timer > 0.14 {
                squash.target = 0
                airborne = true
                let height = hopsLeft >= 2 ? 0.2 : 0.11
                hopVelocity = (2 * Self.gravity * height).squareRoot()
                squash.velocity += 4.5
                tuft.velocity -= 3
            }
        }
        guard airborne else { return }
        hopVelocity -= Self.gravity * dt
        hopHeight += hopVelocity * dt
        if hopHeight <= 0 {
            hopHeight = 0
            airborne = false
            squash.value = min(squash.value, -0.03)
            squash.velocity = -2.3
            tuft.velocity += 5
            hopsLeft -= 1
            hopTimer = hopsLeft > 0 ? 0.06 : nil
        }
    }

    // MARK: - Output

    /// The renderable pose for the current moment.
    public var pose: CompanionPose {
        let v = clampUnit(vitalitySpring.value)
        let calm = reduceMotion ? 0.25 : 1.0
        let breath = BreathingCurve.scales(phase: breathPhase, vitality: v, life: life)
        let flight = airborne ? min(max(hopVelocity / 9, -0.05), 0.12) : 0
        let squashed = SquashModel.scales(squash: squash.value + flight)
        let slump = SquashModel.slump(vitality: v)
        let blinkClosure = blinks ? BlinkCurve.closure(elapsed: time - blinkStart) : 0
        let sleepy = (1 - smoothstep(0.25, 0.75, v)) * 0.42
        let happiness = clampUnit(happy.value)

        var pose = CompanionPose()
        pose.scaleX = (1 + (breath.x - 1) * calm) * squashed.x * slump.x
        pose.scaleY = (1 + (breath.y - 1) * calm) * squashed.y * slump.y
        pose.lean = lean.value * 0.015 * calm
        pose.hop = hopHeight
        pose.cheekPuff = max(0, cheekSpring.value)
        pose.lidClosure = max(blinkClosure, sleepy, happiness * 0.1)
        pose.happiness = happiness
        pose.sadness = 1 - smoothstep(0.2, 0.6, v)
        pose.blush = clampUnit(clampUnit(blushSpring.value) * 0.6 + clampUnit(cheekSpring.value) * 0.35)
        pose.saturation = lerp(0.22, 1.08, v)
        pose.brightness = lerp(-0.06, 0.01, v)
        pose.tuftAngle = tuft.value * calm
        pose.shadowScale = 1 / (1 + hopHeight / 0.25)
        pose.furRipple = lerp(0.35, 1, v) * (reduceMotion ? 0 : 1)
        pose.time = time
        return pose
    }

    /// The settled vitality Pofu currently shows (it lags the target).
    public var displayedVitality: Double { clampUnit(vitalitySpring.value) }

    /// Whether Pofu is in the air.
    public var isAirborne: Bool { airborne }
}
