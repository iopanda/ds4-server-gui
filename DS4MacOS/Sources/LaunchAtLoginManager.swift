import Foundation
import ServiceManagement

// MARK: - LaunchAtLoginManager
// Uses SMAppService (macOS 13+) to register/unregister the app as a login item.

final class LaunchAtLoginManager {

    static let shared = LaunchAtLoginManager()
    private init() {}

    /// Whether the app is currently registered to launch at login.
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enable or disable launch at login. Returns true on success.
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            LogWindowController.shared.append("[WARN] LaunchAtLogin setEnabled(\(enabled)) failed: \(error.localizedDescription)\n")
            return false
        }
    }
}
