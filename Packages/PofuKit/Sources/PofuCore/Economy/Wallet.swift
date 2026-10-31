import Foundation

/// The persisted economic state of one user.
///
/// A wallet is plain data. Every change goes through `Economy`, which
/// enforces the rules; the setters are therefore internal to PofuCore.
public struct Wallet: Hashable, Sendable, Codable {
    /// Spendable energy. Never negative.
    public internal(set) var balance: Energy
    /// The most recent local day whose allowance has been granted. Also the
    /// newest day the wallet has seen.
    public internal(set) var lastAllowanceDay: LocalDay?
    /// Honor-system energy credited per day, for the honor cap.
    public internal(set) var honorEarnedByDay: [LocalDay: Energy]
    /// Step energy credited per day, so cumulative step totals are credited
    /// incrementally and never twice.
    public internal(set) var stepEnergyByDay: [LocalDay: Energy]
    /// All activity energy credited per day (honor, verified, and steps),
    /// which feeds the companion's vitality.
    public internal(set) var activityEnergyByDay: [LocalDay: Energy]
    /// Instants of recent paid unlocks, for price escalation.
    public internal(set) var unlockPurchases: [Date]

    /// Creates a wallet. A negative opening balance is clamped to zero.
    public init(balance: Energy = .zero) {
        self.balance = max(balance, .zero)
        self.lastAllowanceDay = nil
        self.honorEarnedByDay = [:]
        self.stepEnergyByDay = [:]
        self.activityEnergyByDay = [:]
        self.unlockPurchases = []
    }

    /// Activity energy credited on `day`.
    public func activityEnergy(on day: LocalDay) -> Energy {
        activityEnergyByDay[day, default: .zero]
    }

    /// Honor-system energy credited on `day`.
    public func honorEnergy(on day: LocalDay) -> Energy {
        honorEarnedByDay[day, default: .zero]
    }
}
