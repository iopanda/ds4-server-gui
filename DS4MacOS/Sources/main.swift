import AppKit
import Foundation

// Debug helper: always writes to a file (bypasses pipe redirection)
func dbgLog(_ s: String) {
    let line = s + "\n"
    if let data = line.data(using: .utf8) {
        let url = URL(fileURLWithPath: "/tmp/ds4-xcode-debug.log")
        if FileManager.default.fileExists(atPath: url.path),
           let fh = try? FileHandle(forWritingTo: url) {
            fh.seekToEndOfFile(); fh.write(data); fh.closeFile()
        } else {
            try? data.write(to: url)
        }
    }
}

dbgLog("=== DS4 main.swift start ===")
dbgLog("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
dbgLog("resourceURL: \(Bundle.main.resourceURL?.path ?? "nil")")

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
dbgLog("activation policy set")

let appDelegate = AppDelegate()
app.delegate = appDelegate
dbgLog("delegate set, entering run()")

DispatchQueue.main.async {
    dbgLog("setup() starting")
    appDelegate.setup()
    dbgLog("setup() done")
}

app.run()
dbgLog("run() returned")
