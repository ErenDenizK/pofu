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
