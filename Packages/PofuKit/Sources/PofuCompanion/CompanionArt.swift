#if canImport(ImageIO)
import CoreGraphics
import Foundation
import ImageIO

/// The companion's bitmap art and the rig that describes it.
///
/// Images are decoded once with ImageIO, which behaves the same on iOS and
/// macOS (so tests can verify the bundled resources) and does not depend
/// on asset catalogs, which command-line SwiftPM builds do not compile.
public struct CompanionArt: @unchecked Sendable {
    // CGImage is immutable and thread-safe; the unchecked conformance only
    // papers over its missing annotation in older SDKs.

    /// The full-body image with transparent background.
    public let base: CGImage
    /// The lid plate: fur painted over the eyes, cropped to
    /// `rig.lidPlateOrigin` / `rig.lidPlateSize`. Revealed above the lid
    /// line for blinks and below it for happy eyes.
    public let lidPlate: CGImage?
    public let rig: CompanionRig

    public init(base: CGImage, lidPlate: CGImage?, rig: CompanionRig) {
        self.base = base
        self.lidPlate = lidPlate
        self.rig = rig
    }

    /// The bundled placeholder hamster, or `nil` if the resources are
    /// missing from the bundle.
    public static let placeholder: CompanionArt? = {
        guard let base = loadImage(named: "pofu-hamster") else { return nil }
        return CompanionArt(base: base, lidPlate: loadImage(named: "pofu-hamster-lids"), rig: .hamster)
    }()

    /// The URL of a bundled PNG resource.
    public static func resourceURL(named name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "png")
    }

    static func loadImage(named name: String) -> CGImage? {
        guard
            let url = resourceURL(named: name),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
#endif
