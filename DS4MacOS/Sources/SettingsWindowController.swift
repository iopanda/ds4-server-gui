import AppKit
import ServiceManagement

// MARK: - SettingsWindowController

final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    var onApply: (() -> Void)?

    // Server tab
    private var modelPathField: NSTextField!
    private var portField: NSTextField!
    private var hostField: NSTextField!
    private var corsCheck: NSButton!
    private var launchAtLoginCheck: NSButton!

    // Performance tab
    private var ctxField: NSTextField!
    private var noThinkCheck: NSButton!
    private var powerSlider: NSSlider!
    private var powerLabel: NSTextField!
    private var ssdStreamingCheck: NSButton!
    private var ssdCacheField: NSTextField!
    private var threadsField: NSTextField!
    private var prefillChunkField: NSTextField!

    // Storage tab
    private var diskKVCheck: NSButton!
    private var kvDirField: NSTextField!
    private var kvSizeField: NSTextField!

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "DS4 Server Settings"
        window.center()
        window.titlebarAppearsTransparent = false
        super.init(window: window)
        window.delegate = self
        buildUI()
        loadValues()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build UI

    private func buildUI() {
        guard let cv = window?.contentView else { return }

        let tabView = NSTabView(frame: NSRect(x: 0, y: 50, width: 500, height: 360))
        tabView.autoresizingMask = [.width, .height]
        tabView.tabViewType = .topTabsBezelBorder
        cv.addSubview(tabView)

        // Tabs
        let serverTab = NSTabViewItem(identifier: "server")
        serverTab.label = L("settings.tab.server")
        serverTab.view = buildServerTab()
        tabView.addTabViewItem(serverTab)

        let perfTab = NSTabViewItem(identifier: "performance")
        perfTab.label = L("settings.tab.performance")
        perfTab.view = buildPerformanceTab()
        tabView.addTabViewItem(perfTab)

        let storageTab = NSTabViewItem(identifier: "storage")
        storageTab.label = L("settings.tab.storage")
        storageTab.view = buildStorageTab()
        tabView.addTabViewItem(storageTab)

        // Bottom buttons
        let applyBtn = NSButton(title: L("settings.button.apply"),
                                target: self, action: #selector(applyClicked))
        applyBtn.bezelStyle = .rounded
        applyBtn.keyEquivalent = "\r"
        applyBtn.frame = NSRect(x: 386, y: 12, width: 100, height: 28)
        cv.addSubview(applyBtn)

        let cancelBtn = NSButton(title: L("settings.button.cancel"),
                                 target: self, action: #selector(cancelClicked))
        cancelBtn.frame = NSRect(x: 306, y: 12, width: 74, height: 28)
        cv.addSubview(cancelBtn)
    }

    // MARK: - Server Tab

    private func buildServerTab() -> NSView {
        let v = NSView()

        // Model file row
        let modelGroup = makeGroup(title: L("settings.group.model"), frame: NSRect(x: 16, y: 196, width: 460, height: 72))
        modelPathField = makeField(placeholder: L("settings.placeholder.model"), frame: NSRect(x: 12, y: 14, width: 364, height: 22))
        let browseBtn = NSButton(title: L("settings.button.browse"), target: self, action: #selector(browseModelClicked))
        browseBtn.frame = NSRect(x: 382, y: 14, width: 66, height: 22)
        browseBtn.tag = 1
        let modelDesc = makeLabel(L("settings.desc.model"), small: true)
        modelDesc.frame = NSRect(x: 12, y: 38, width: 436, height: 16)
        modelGroup.contentView?.addSubview(modelDesc)
        modelGroup.contentView?.addSubview(modelPathField)
        modelGroup.contentView?.addSubview(browseBtn)
        v.addSubview(modelGroup)

        // Network group
        let netGroup = makeGroup(title: L("settings.group.network"), frame: NSRect(x: 16, y: 80, width: 460, height: 106))

        // Port
        let portLabel = makeLabel(L("settings.label.port"))
        portLabel.frame = NSRect(x: 12, y: 64, width: 120, height: 20)
        portField = makeField(placeholder: "8000", frame: NSRect(x: 136, y: 62, width: 80, height: 22))
        let portHint = makeLabel(L("settings.hint.port"), small: true)
        portHint.frame = NSRect(x: 224, y: 64, width: 220, height: 18)
        portHint.textColor = .tertiaryLabelColor

        // Host
        let hostLabel = makeLabel(L("settings.label.host"))
        hostLabel.frame = NSRect(x: 12, y: 36, width: 120, height: 20)
        hostField = makeField(placeholder: "127.0.0.1", frame: NSRect(x: 136, y: 34, width: 160, height: 22))
        let hostHint = makeLabel(L("settings.hint.host"), small: true)
        hostHint.frame = NSRect(x: 302, y: 36, width: 142, height: 18)
        hostHint.textColor = .tertiaryLabelColor

        // CORS
        corsCheck = makeCheckbox(L("settings.checkbox.cors_short"), frame: NSRect(x: 12, y: 8, width: 436, height: 20))

        for sub in [portLabel, portField!, portHint, hostLabel, hostField!, hostHint, corsCheck!] {
            netGroup.contentView?.addSubview(sub)
        }
        v.addSubview(netGroup)

        // Launch at Login + hint
        let systemGroup = makeGroup(title: L("settings.group.system"), frame: NSRect(x: 16, y: 16, width: 460, height: 56))
        launchAtLoginCheck = makeCheckbox(L("settings.checkbox.launch_at_login_short"), frame: NSRect(x: 12, y: 22, width: 436, height: 20))
        let loginHint = makeLabel(L("settings.hint.launch_at_login"), small: true)
        loginHint.frame = NSRect(x: 30, y: 6, width: 420, height: 16)
        loginHint.textColor = .tertiaryLabelColor
        systemGroup.contentView?.addSubview(launchAtLoginCheck)
        systemGroup.contentView?.addSubview(loginHint)
        v.addSubview(systemGroup)

        return v
    }

    // MARK: - Performance Tab

    private func buildPerformanceTab() -> NSView {
        let v = NSView()

        // Context & Thinking
        let ctxGroup = makeGroup(title: L("settings.group.context"), frame: NSRect(x: 16, y: 196, width: 460, height: 100))

        let ctxLabel = makeLabel(L("settings.label.ctx_short"))
        ctxLabel.frame = NSRect(x: 12, y: 56, width: 160, height: 20)
        ctxField = makeField(placeholder: "32768", frame: NSRect(x: 176, y: 54, width: 100, height: 22))
        let ctxHint = makeLabel(L("settings.hint.ctx"), small: true)
        ctxHint.frame = NSRect(x: 12, y: 36, width: 436, height: 18)
        ctxHint.textColor = .tertiaryLabelColor

        noThinkCheck = makeCheckbox(L("settings.checkbox.nothink_short"), frame: NSRect(x: 12, y: 10, width: 436, height: 20))

        for sub in [ctxLabel, ctxField!, ctxHint, noThinkCheck!] {
            ctxGroup.contentView?.addSubview(sub)
        }
        v.addSubview(ctxGroup)

        // GPU Power
        let gpuGroup = makeGroup(title: L("settings.group.gpu"), frame: NSRect(x: 16, y: 126, width: 460, height: 62))
        let powerDesc = makeLabel(L("settings.desc.power"), small: true)
        powerDesc.frame = NSRect(x: 12, y: 36, width: 436, height: 16)
        powerDesc.textColor = .tertiaryLabelColor
        powerSlider = NSSlider(frame: NSRect(x: 12, y: 12, width: 360, height: 22))
        powerSlider.minValue = 10; powerSlider.maxValue = 100
        powerSlider.target = self; powerSlider.action = #selector(powerChanged)
        powerLabel = NSTextField(labelWithString: "100%")
        powerLabel.frame = NSRect(x: 378, y: 13, width: 70, height: 20)
        powerLabel.alignment = .left
        for sub in [powerDesc, powerSlider!, powerLabel!] { gpuGroup.contentView?.addSubview(sub) }
        v.addSubview(gpuGroup)

        // SSD Streaming
        let ssdGroup = makeGroup(title: L("settings.group.ssd"), frame: NSRect(x: 16, y: 16, width: 460, height: 102))
        ssdStreamingCheck = makeCheckbox(L("settings.checkbox.ssd_short"), frame: NSRect(x: 12, y: 68, width: 436, height: 20))
        let ssdDesc = makeLabel(L("settings.desc.ssd"), small: true)
        ssdDesc.frame = NSRect(x: 30, y: 52, width: 420, height: 16)
        ssdDesc.textColor = .tertiaryLabelColor

        let cacheLabel = makeLabel(L("settings.label.ssd_cache_short"))
        cacheLabel.frame = NSRect(x: 12, y: 26, width: 160, height: 20)
        ssdCacheField = makeField(placeholder: L("settings.placeholder.ssd_cache"), frame: NSRect(x: 176, y: 24, width: 80, height: 22))
        let cacheHint = makeLabel(L("settings.hint.ssd_cache"), small: true)
        cacheHint.frame = NSRect(x: 262, y: 26, width: 190, height: 18)
        cacheHint.textColor = .tertiaryLabelColor

        let advLabel = makeLabel(L("settings.label.advanced"))
        advLabel.frame = NSRect(x: 12, y: 4, width: 160, height: 16)
        advLabel.textColor = .tertiaryLabelColor
        advLabel.font = NSFont.systemFont(ofSize: 10)
        threadsField = makeField(placeholder: "auto", frame: NSRect(x: 176, y: 2, width: 60, height: 18))
        threadsField.font = NSFont.systemFont(ofSize: 11)
        prefillChunkField = makeField(placeholder: "auto", frame: NSRect(x: 248, y: 2, width: 70, height: 18))
        prefillChunkField.font = NSFont.systemFont(ofSize: 11)
        let tLabel = makeLabel("threads", small: true); tLabel.frame = NSRect(x: 176, y: 2, width: 0, height: 0) // invisible spacer

        for sub in [ssdStreamingCheck!, ssdDesc, cacheLabel, ssdCacheField!, cacheHint, advLabel, threadsField!, prefillChunkField!] {
            ssdGroup.contentView?.addSubview(sub)
        }

        // Replace advanced row with cleaner layout
        let thr = makeLabel("Threads:", small: true); thr.frame = NSRect(x: 12, y: 3, width: 55, height: 16); thr.textColor = .secondaryLabelColor
        let pc  = makeLabel("Prefill:", small: true);  pc.frame  = NSRect(x: 154, y: 3, width: 48, height: 16); pc.textColor = .secondaryLabelColor
        threadsField.frame = NSRect(x: 70, y: 2, width: 76, height: 18)
        prefillChunkField.frame = NSRect(x: 206, y: 2, width: 76, height: 18)
        ssdGroup.contentView?.addSubview(thr)
        ssdGroup.contentView?.addSubview(pc)

        v.addSubview(ssdGroup)
        return v
    }

    // MARK: - Storage Tab

    private func buildStorageTab() -> NSView {
        let v = NSView()

        let kvGroup = makeGroup(title: L("settings.group.kv"), frame: NSRect(x: 16, y: 160, width: 460, height: 140))

        diskKVCheck = makeCheckbox(L("settings.checkbox.disk_kv_short"), frame: NSRect(x: 12, y: 106, width: 436, height: 20))
        let kvDesc = makeLabel(L("settings.desc.kv"), small: true)
        kvDesc.frame = NSRect(x: 30, y: 90, width: 420, height: 16)
        kvDesc.textColor = .tertiaryLabelColor

        let dirLabel = makeLabel(L("settings.label.kv_cache"))
        dirLabel.frame = NSRect(x: 12, y: 60, width: 110, height: 20)
        kvDirField = makeField(placeholder: L("settings.placeholder.kv_dir"), frame: NSRect(x: 126, y: 58, width: 258, height: 22))
        let kvBrowseBtn = NSButton(title: L("settings.button.browse"), target: self, action: #selector(browseKVClicked))
        kvBrowseBtn.frame = NSRect(x: 390, y: 58, width: 60, height: 22)

        let sizeLabel = makeLabel(L("settings.label.kv_size_short"))
        sizeLabel.frame = NSRect(x: 12, y: 30, width: 110, height: 20)
        kvSizeField = makeField(placeholder: "8192", frame: NSRect(x: 126, y: 28, width: 100, height: 22))
        let sizeHint = makeLabel(L("settings.hint.kv_size"), small: true)
        sizeHint.frame = NSRect(x: 232, y: 30, width: 220, height: 18)
        sizeHint.textColor = .tertiaryLabelColor

        let kvHint = makeLabel(L("settings.hint.kv_path"), small: true)
        kvHint.frame = NSRect(x: 12, y: 8, width: 436, height: 18)
        kvHint.textColor = .tertiaryLabelColor

        for sub in [diskKVCheck!, kvDesc, dirLabel, kvDirField!, kvBrowseBtn,
                    sizeLabel, kvSizeField!, sizeHint, kvHint] {
            kvGroup.contentView?.addSubview(sub)
        }
        v.addSubview(kvGroup)

        // Info box
        let infoBox = makeGroup(title: L("settings.group.info"), frame: NSRect(x: 16, y: 80, width: 460, height: 72))
        let infoText = makeLabel(L("settings.info.kv"), small: true)
        infoText.frame = NSRect(x: 12, y: 8, width: 436, height: 50)
        infoText.textColor = .secondaryLabelColor
        infoText.maximumNumberOfLines = 3
        infoBox.contentView?.addSubview(infoText)
        v.addSubview(infoBox)

        return v
    }

    // MARK: - Helpers

    private func makeGroup(title: String, frame: NSRect) -> NSBox {
        let b = NSBox(frame: frame)
        b.title = title
        b.titleFont = NSFont.systemFont(ofSize: 11, weight: .medium)
        return b
    }

    private func makeLabel(_ text: String, small: Bool = false) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = NSFont.systemFont(ofSize: small ? 11 : NSFont.systemFontSize)
        return l
    }

    private func makeField(placeholder: String, frame: NSRect) -> NSTextField {
        let f = NSTextField(frame: frame)
        f.placeholderString = placeholder
        f.bezelStyle = .roundedBezel
        f.cell?.wraps = false
        f.cell?.isScrollable = true
        f.usesSingleLineMode = true
        f.lineBreakMode = .byTruncatingMiddle
        return f
    }

    private func makeCheckbox(_ title: String, frame: NSRect) -> NSButton {
        let b = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        b.frame = frame
        b.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return b
    }

    // MARK: - Load / Save

    private func loadValues() {
        let s = Settings.shared
        modelPathField.stringValue    = s.modelPath
        portField.stringValue         = String(s.port)
        hostField.stringValue         = s.host
        corsCheck.state               = s.enableCORS ? .on : .off
        launchAtLoginCheck.state      = (SMAppService.mainApp.status == .enabled) ? .on : .off
        ctxField.stringValue          = String(s.ctxSize)
        noThinkCheck.state            = s.noThink ? .on : .off
        powerSlider.doubleValue       = Double(s.powerPercent)
        powerLabel.stringValue        = "\(s.powerPercent)%"
        ssdStreamingCheck.state       = s.enableSSDStreaming ? .on : .off
        ssdCacheField.stringValue     = s.ssdStreamingCacheGB > 0 ? String(s.ssdStreamingCacheGB) : ""
        threadsField.stringValue      = s.threads > 0 ? String(s.threads) : ""
        prefillChunkField.stringValue = s.prefillChunk > 0 ? String(s.prefillChunk) : ""
        diskKVCheck.state             = s.enableDiskKV ? .on : .off
        kvDirField.stringValue        = s.kvDiskDir
        kvSizeField.stringValue       = String(s.kvDiskSpaceMB)
    }

    private func saveValues() {
        let s = Settings.shared
        s.modelPath           = modelPathField.stringValue.trimmingCharacters(in: .whitespaces)
        s.port                = Int(portField.stringValue) ?? 8000
        s.host                = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        s.enableCORS          = corsCheck.state == .on
        s.ctxSize             = Int(ctxField.stringValue) ?? 32768
        s.noThink             = noThinkCheck.state == .on
        s.powerPercent        = Int(powerSlider.doubleValue)
        s.enableSSDStreaming   = ssdStreamingCheck.state == .on
        s.ssdStreamingCacheGB = Int(ssdCacheField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        s.threads             = Int(threadsField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        s.prefillChunk        = Int(prefillChunkField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        s.enableDiskKV        = diskKVCheck.state == .on
        s.kvDiskDir           = kvDirField.stringValue.trimmingCharacters(in: .whitespaces)
        s.kvDiskSpaceMB       = Int(kvSizeField.stringValue) ?? 8192
        LaunchAtLoginManager.shared.setEnabled(launchAtLoginCheck.state == .on)
    }

    // MARK: - Actions

    @objc private func browseModelClicked() {
        let panel = NSOpenPanel()
        panel.title = L("settings.panel.model")
        panel.canChooseFiles = true; panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        modelPathField.stringValue = url.path
    }

    @objc private func browseKVClicked() {
        let panel = NSOpenPanel()
        panel.title = L("settings.panel.kv_dir")
        panel.canChooseFiles = false; panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        kvDirField.stringValue = url.path
    }

    @objc private func powerChanged() {
        powerLabel.stringValue = "\(Int(powerSlider.doubleValue))%"
    }

    @objc private func applyClicked() {
        saveValues()
        close()
        onApply?()
    }

    @objc private func cancelClicked() { close() }

    func windowShouldClose(_ sender: NSWindow) -> Bool { true }
}
