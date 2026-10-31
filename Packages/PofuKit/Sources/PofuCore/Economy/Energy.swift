/// The currency of Pofu's economy, in whole units.
///
/// Energy is earned through real-life activities and spent on bounded unlock
/// windows. The user-facing name is not final; the domain name is `Energy`.
/// Fractions never exist: every rule that produces energy rounds explicitly
/// (earning rounds down, prices round up), see `docs/product/economy.md`.
public struct Energy: Hashable, Comparable, Sendable, AdditiveArithmetic,
    ExpressibleByIntegerLiteral, CustomStringConvertible
{
    /// The number of whole energy units.
    public var units: Int

    public init(_ units: Int) {
        self.units = units
    }

    public init(integerLiteral value: Int) {
        self.units = value
    }

    public static let zero = Energy(0)

    public static func + (lhs: Energy, rhs: Energy) -> Energy {
        Energy(lhs.units + rhs.units)
    }

    public static func - (lhs: Energy, rhs: Energy) -> Energy {
        Energy(lhs.units - rhs.units)
    }

    public static func < (lhs: Energy, rhs: Energy) -> Bool {
        lhs.units < rhs.units
    }

    public var description: String {
        "\(units) energy"
    }
}

extension Energy: Codable {
    /// Energy encodes as a bare integer, which keeps persisted state and
    /// configuration files readable.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.units = try container.decode(Int.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(units)
    }
}
