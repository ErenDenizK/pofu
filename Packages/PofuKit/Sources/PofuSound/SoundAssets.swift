import Foundation

/// Where the pre-rendered cues live in the module bundle.
enum SoundAssets {
    static func url(for name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "caf", subdirectory: "Resources")
    }
}
