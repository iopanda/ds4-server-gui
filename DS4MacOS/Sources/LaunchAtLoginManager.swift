import Foundation
import ServiceManagement

// MARK: - LaunchAtLoginManager
// Uses SMAppService (macOS 13+) to register/unregister the app as a login item.
// NOTE: Requires a proper Developer ID or App Store signature.
// Ad-hoc signed builds will silently fail — isSupported returns false in that case.

final class LaunchAtLoginManager {

    static let shared = LaunchAtLoginManager()
    private init() {}

    /// Whether the current app signature supports SMAppService.
    /// Ad-hoc signed apps (codesign -s -) are not permitted by macOS.
    var isSupported: Bool {
        // Check if the app has a real team identifier (not ad-hoc)
        guard let info = Bundle.main.infoDictionary,
              let _ = info["CFBundleIdentifier"] as? String else { return false }
        // SMAppService status returns .notRegistered (not .requiresApproval or error) when supported
        let status = SMAppService.mainApp.status
        return status != .notFound
    }

    /// Whether the app is currently registered to launch at login.
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enable or disable launch at login. Returns true on success.
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        // Skip silently for ad-hoc / unsigned builds
        guard isSupported else { return false }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            // Only log if it's unexpected (not the known ad-hoc permission error)
            let desc = error.localizedDescription
            if !desc.contains("not permitted") && !desc.contains("Operation not permitted") {
                LogWindowController.shared.append("[WARN] LaunchAtLogin: \(desc)\n")
            }
            return false
        }
    }
}
