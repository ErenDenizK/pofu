/// The apps Pofu offers to stand in front of. The product targets
/// Instagram, YouTube and TikTok; the enum keeps its other cases so a
/// choice already stored still decodes and its shield still works.
extension ProtectedApp {
    /// The onboarding picker's apps, in order.
    public static let offered: [ProtectedApp] = [.instagram, .youtube, .tiktok]
}
