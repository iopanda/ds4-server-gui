import Foundation

// MARK: - Settings (UserDefaults backed)

final class Settings {
    static let shared = Settings()
    private init() { migrateIfNeeded() }

    // Cannot use own Bundle ID as suite name (macOS restriction), append .prefs suffix
    static let suiteName = "DS4ServerAppPreferences"
    private let defaults = UserDefaults(suiteName: Settings.suiteName) ?? UserDefaults.standard

    private func migrateIfNeeded() {
        guard let newD = UserDefaults(suiteName: Settings.suiteName) else { return }
        let keys = ["modelPath", "port", "host", "ctxSize", "enableDiskKV",
                    "kvDiskDir", "kvDiskSpaceMB", "enableCORS", "noThink", "powerPercent"]
        // Migrate from UserDefaults.standard (old bundle ID suite is unsafe to access, read from standard)
        var migrated = false
        for key in keys {
            if let val = UserDefaults.standard.object(forKey: key),
               newD.object(forKey: key) == nil {
                newD.set(val, forKey: key)
                migrated = true
            }
        }
        // Fix incorrect default: ctxSize was mistakenly defaulted to 100000 instead of 32768.
        // Reset silently if the user never changed it from that bad default.
        if newD.integer(forKey: Key.ctxSize) == 100000 {
            newD.set(32768, forKey: Key.ctxSize)
            migrated = true
        }
        if migrated { newD.synchronize() }
    }

    private enum Key {
        static let modelPath        = "modelPath"
        static let port             = "port"
        static let host             = "host"
        static let ctxSize          = "ctxSize"
        static let enableDiskKV     = "enableDiskKV"
        static let kvDiskDir        = "kvDiskDir"
        static let kvDiskSpaceMB    = "kvDiskSpaceMB"
        static let enableCORS       = "enableCORS"
        static let noThink          = "noThink"
        static let powerPercent     = "powerPercent"
    }

    var modelPath: String {
        get { defaults.string(forKey: Key.modelPath) ?? "" }
        set { defaults.set(newValue, forKey: Key.modelPath) }
    }


    var port: Int {
        get { let v = defaults.integer(forKey: Key.port); return v > 0 ? v : 8000 }
        set { defaults.set(newValue, forKey: Key.port) }
    }

    var host: String {
        get { let v = defaults.string(forKey: Key.host) ?? ""; return v.isEmpty ? "127.0.0.1" : v }
        set { defaults.set(newValue, forKey: Key.host) }
    }

    var ctxSize: Int {
        get { let v = defaults.integer(forKey: Key.ctxSize); return v > 0 ? v : 32768 }
        set { defaults.set(newValue, forKey: Key.ctxSize) }
    }

    var enableDiskKV: Bool {
        get { defaults.bool(forKey: Key.enableDiskKV) }
        set { defaults.set(newValue, forKey: Key.enableDiskKV) }
    }

    var kvDiskDir: String {
        get { defaults.string(forKey: Key.kvDiskDir) ?? "" }
        set { defaults.set(newValue, forKey: Key.kvDiskDir) }
    }

    var kvDiskSpaceMB: Int {
        get { let v = defaults.integer(forKey: Key.kvDiskSpaceMB); return v > 0 ? v : 8192 }
        set { defaults.set(newValue, forKey: Key.kvDiskSpaceMB) }
    }

    var enableCORS: Bool {
        get { defaults.bool(forKey: Key.enableCORS) }
        set { defaults.set(newValue, forKey: Key.enableCORS) }
    }

    var noThink: Bool {
        get { defaults.bool(forKey: Key.noThink) }
        set { defaults.set(newValue, forKey: Key.noThink) }
    }

    var powerPercent: Int {
        get { let v = defaults.integer(forKey: Key.powerPercent); return v > 0 ? v : 100 }
        set { defaults.set(min(100, max(1, newValue)), forKey: Key.powerPercent) }
    }
}
