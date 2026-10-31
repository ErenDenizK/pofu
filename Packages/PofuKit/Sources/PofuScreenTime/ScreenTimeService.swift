import Foundation

/// The boundary between Pofu and Apple's Screen Time frameworks (ADR-0003).
///
/// Two implementations exist, or will:
/// - `SimulatedScreenTimeService`: deterministic and scriptable, for
///   development on a free provisioning profile, previews, and tests.
/// - `LiveScreenTimeService` (Phase 2, needs the paid membership):
///   FamilyControls for authorization and selection, ManagedSettings for
///   shields, DeviceActivity for schedules and thresholds.
///
/// Nothing outside the live implementation may import those frameworks.
public protocol ScreenTimeService: Sendable {
    // MARK: Authorization

    func authorizationStatus() async -> ScreenTimeAuthorizationStatus

    /// Asks the user for Screen Time access and returns the resulting
    /// status. Declining is a normal outcome (`.denied`), not an error.
    ///
    /// - Throws: `ScreenTimeError.unavailable` when the system cannot ask.
    func requestAuthorization() async throws -> ScreenTimeAuthorizationStatus

    // MARK: Selection

    /// The apps, categories, and domains the user marked as distracting.
    func distractingSelection() async -> DistractionSelection

    /// Stores the selection the user made in the system activity picker.
    ///
    /// - Throws: `ScreenTimeError.notAuthorized` without authorization.
    func updateDistractingSelection(_ selection: DistractionSelection) async throws

    // MARK: Shields

    /// Shields everything in `selection` under the name `id`, replacing
    /// what `id` shielded before.
    ///
    /// - Throws: `ScreenTimeError.notAuthorized` or `.emptySelection`.
    func applyShield(_ id: ShieldID, to selection: DistractionSelection) async throws

    /// Removes the shields named `id`. Shields under other names stay.
    func removeShield(_ id: ShieldID) async

    /// Every shield currently applied, by name.
    func activeShields() async -> [ShieldID: DistractionSelection]

    // MARK: Thresholds

    /// Starts monitoring `schedule`, replacing a schedule with the same id.
    ///
    /// - Throws: `ScreenTimeError.notAuthorized`, `.emptySelection`, or
    ///   `.invalidThreshold`.
    func scheduleThreshold(_ schedule: ThresholdSchedule) async throws

    /// Stops monitoring the schedule with `id`.
    func cancelThreshold(_ id: ThresholdID) async

    /// Every schedule being monitored, ordered by id.
    func scheduledThresholds() async -> [ThresholdSchedule]

    // MARK: Events

    /// A new stream of every event from now on. Each call returns an
    /// independent stream; it ends when the consumer stops iterating.
    func events() async -> AsyncStream<ScreenTimeEvent>
}
