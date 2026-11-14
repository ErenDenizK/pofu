import Foundation

/// Whether developer-only UI shows. Read from UserDefaults, so the launch
/// argument `-PofuDeveloper YES` turns it on, the same way `-PofuSkin`
/// works. It does not depend on the build configuration: a Release build
/// with the argument shows the developer tools, a Debug build without it
/// does not.
enum DeveloperFlag {
    static let key = "PofuDeveloper"

    static var isOn: Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
