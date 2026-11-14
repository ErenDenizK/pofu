// The skin switch (UI system v2 §2 and §4): one enum decides whether the
// four over-world chrome roles are Liquid Glass or crafted (clay and
// paper). Everything else is native in both skins. Pure data, so the policy
// is tested on any platform; the views are in `PofuSkinViews.swift`.

/// The only switch: how the over-world chrome is made.
public enum PofuSkin: String, CaseIterable, Hashable, Sendable {
    case glass
    case crafted
}

/// The closed list of what the switch may touch (UI system v2 §4.1): four
/// roles, the action role in two weights.
public enum PofuChromeRole: Hashable, Sendable {
    case primaryAction
    case secondaryAction
    case iconButton
    case worldTag
    case glance
}

/// Resolves the effective skin, in priority order: accessibility (Reduce
/// Transparency forces crafted, which is opaque), the developer override
/// (Prova panel, launch argument `-PofuSkin crafted`), the beta assignment,
/// then the default.
public struct PofuSkinPolicy: Hashable, Sendable {
    /// Reduce Transparency is on.
    public var reduceTransparency: Bool
    /// Set from Settings, the Prova panel or a launch argument.
    public var developerOverride: PofuSkin?
    /// Per-role developer overrides, so a mixed result (crafted tag, glass
    /// gear) is one configuration, not a fork.
    public var roleOverrides: [PofuChromeRole: PofuSkin]
    /// The friends-beta assignment, when there is one.
    public var betaAssignment: PofuSkin?
    /// Glass until the A/B decides.
    public var defaultSkin: PofuSkin

    public init(
        reduceTransparency: Bool = false,
        developerOverride: PofuSkin? = nil,
        roleOverrides: [PofuChromeRole: PofuSkin] = [:],
        betaAssignment: PofuSkin? = nil,
        defaultSkin: PofuSkin = .glass
    ) {
        self.reduceTransparency = reduceTransparency
        self.developerOverride = developerOverride
        self.roleOverrides = roleOverrides
        self.betaAssignment = betaAssignment
        self.defaultSkin = defaultSkin
    }

    /// The skin for the app as a whole.
    public var skin: PofuSkin {
        if reduceTransparency { return .crafted }
        return developerOverride ?? betaAssignment ?? defaultSkin
    }

    /// The skin for one role. Reduce Transparency still wins.
    public func skin(for role: PofuChromeRole) -> PofuSkin {
        if reduceTransparency { return .crafted }
        return roleOverrides[role] ?? skin
    }

    /// The skin a view should draw: `skin`, unless Reduce Transparency
    /// asks for the opaque faces.
    public static func effective(_ skin: PofuSkin, reduceTransparency: Bool) -> PofuSkin {
        reduceTransparency ? .crafted : skin
    }

    /// The developer override from `UserDefaults` (launch argument
    /// `-PofuSkin crafted` lands there too).
    public static func override(from rawValue: String?) -> PofuSkin? {
        rawValue.flatMap { PofuSkin(rawValue: $0.lowercased()) }
    }
}

/// The roles asset wave 0 painted on Home and in the shared kit.
public enum PofuPaintedRole: CaseIterable, Sendable {
    /// The round button (gear, place control): clay disc.
    case disc
    /// The glance and the daily line: linen card.
    case linen
    /// The speech bubble's paper, its painted tail and its ribbon tab.
    case bubble
    /// The honey plaque of the one verb.
    case plaque
    /// The chrome following the world's night instead of the system.
    case worldLight
}

/// What a painted role is made of under a skin.
public enum PofuRoleFace: Sendable {
    /// The glass skin: native glass where the role had it, otherwise the
    /// code-drawn face the role had before asset wave 0.
    case glass
    /// The baked painted face.
    case painted
}

extension PofuSkinPolicy {
    /// The face of a wave-0 role. Painted faces belong to the crafted skin
    /// (Reduce Transparency included); the glass skin is unchanged.
    public static func face(for role: PofuPaintedRole, skin: PofuSkin, reduceTransparency: Bool) -> PofuRoleFace {
        effective(skin, reduceTransparency: reduceTransparency) == .glass ? .glass : .painted
    }
}
