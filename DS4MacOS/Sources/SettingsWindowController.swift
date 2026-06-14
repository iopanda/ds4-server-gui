import AppKit

// MARK: - SettingsWindowController

final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    var onApply: (() -> Void)?

    private var modelPathField: NSTextField!
    private var portField: NSTextField!
    private var hostField: NSTextField!
    private var ctxField: NSTextField!
    private var diskKVCheck: NSButton!
    private var kvDirField: NSTextField!
    private var kvSizeField: NSTextField!
    private var corsCheck: NSButton!
    private var noThinkCheck: NSButton!
    private var powerSlider: NSSlider!
    private var powerLabel: NSTextField!

    private let W: CGFloat = 480
    private let H: CGFloat = 460
    private let pad: CGFloat  = 20
    private let labelW: CGFloat = 140
    private let gap: CGFloat  = 8
    private let btnW: CGFloat = 56
    private let btnGap: CGFloat = 6
    private let rowH: CGFloat = 32

    private var fx: CGFloat { pad + labelW + gap }
    private var fieldWBtn: CGFloat { W - fx - pad - btnGap - btnW }
    private var fieldWFull: CGFloat { W - fx - pad }

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: W, height: H),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L("settings.window.title")
        window.center()
        super.init(window: window)
        window.delegate = self
        buildUI()
        loadValues()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Construction

    private func buildUI() {
        guard let cv = window?.contentView else { return }
        var y = H - 28

        @discardableResult
        func label(_ text: String, at yy: CGFloat) -> NSTextField {
            let l = NSTextField(labelWithString: text)
            l.frame = NSRect(x: pad, y: yy + 1, width: labelW, height: 20)
            l.alignment = .right
            l.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            cv.addSubview(l)
            return l
        }

        func field(at yy: CGFloat, width w: CGFloat) -> NSTextField {
            let f = NSTextField(frame: NSRect(x: fx, y: yy, width: w, height: 22))
            f.bezelStyle = .roundedBezel
            f.cell?.wraps = false
            f.cell?.isScrollable = true
            f.usesSingleLineMode = true
            f.lineBreakMode = .byTruncatingMiddle
            cv.addSubview(f)
            return f
        }

        func browseBtn(at yy: CGFloat, tag t: Int) {
            let bx = fx + fieldWBtn + btnGap
            let b = NSButton(title: L("settings.button.browse"), target: self,
                             action: #selector(browseClicked(_:)))
            b.frame = NSRect(x: bx, y: yy, width: btnW, height: 22)
            b.tag = t
            cv.addSubview(b)
        }

        func checkbox(_ text: String, at yy: CGFloat) -> NSButton {
            let b = NSButton(checkboxWithTitle: text, target: nil, action: nil)
            b.frame = NSRect(x: fx, y: yy, width: fieldWFull, height: 20)
            b.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            cv.addSubview(b)
            return b
        }

        label(L("settings.label.model_path"), at: y)
        modelPathField = field(at: y, width: fieldWBtn)
        browseBtn(at: y, tag: 1)
        y -= rowH

        label(L("settings.label.port"), at: y)
        portField = field(at: y, width: 80)
        y -= rowH

        label(L("settings.label.host"), at: y)
        hostField = field(at: y, width: 160)
        y -= rowH

        label(L("settings.label.ctx"), at: y)
        ctxField = field(at: y, width: 110)
        y -= rowH

        let sep = NSBox(frame: NSRect(x: pad, y: y + 8, width: W - pad * 2, height: 1))
        sep.boxType = .separator
        cv.addSubview(sep)
        y -= 16

        diskKVCheck = checkbox(L("settings.checkbox.disk_kv"), at: y)
        y -= 28

        label(L("settings.label.kv_cache"), at: y)
        kvDirField = field(at: y, width: fieldWBtn)
        browseBtn(at: y, tag: 3)
        y -= rowH

        label(L("settings.label.kv_size"), at: y)
        kvSizeField = field(at: y, width: 90)
        y -= rowH

        let sep2 = NSBox(frame: NSRect(x: pad, y: y + 8, width: W - pad * 2, height: 1))
        sep2.boxType = .separator
        cv.addSubview(sep2)
        y -= 16

        corsCheck = checkbox(L("settings.checkbox.cors"), at: y)
        y -= 28

        noThinkCheck = checkbox(L("settings.checkbox.nothink"), at: y)
        y -= 34

        label(L("settings.label.gpu_power"), at: y)
        let sliderW = fieldWFull - 46
        powerSlider = NSSlider(frame: NSRect(x: fx, y: y, width: sliderW, height: 22))
        powerSlider.minValue = 10
        powerSlider.maxValue = 100
        powerSlider.target = self
        powerSlider.action = #selector(powerChanged)
        cv.addSubview(powerSlider)
        powerLabel = NSTextField(labelWithString: "100%")
        powerLabel.frame = NSRect(x: fx + sliderW + 6, y: y + 1, width: 40, height: 20)
        powerLabel.alignment = .left
        cv.addSubview(powerLabel)
        y -= 44

        let applyBtn = NSButton(title: L("settings.button.apply"),
                                target: self, action: #selector(applyClicked))
        applyBtn.bezelStyle = .rounded
        applyBtn.keyEquivalent = "\r"
        let applyW: CGFloat = 100
        applyBtn.frame = NSRect(x: W - pad - applyW, y: y, width: applyW, height: 26)
        cv.addSubview(applyBtn)

        let cancelBtn = NSButton(title: L("settings.button.cancel"),
                                 target: self, action: #selector(cancelClicked))
        cancelBtn.frame = NSRect(x: W - pad - applyW - 8 - 72, y: y, width: 72, height: 26)
        cv.addSubview(cancelBtn)
    }

    // MARK: - Load / Save

    private func loadValues() {
        let s = Settings.shared
        modelPathField.stringValue  = s.modelPath
        portField.stringValue       = String(s.port)
        hostField.stringValue       = s.host
        ctxField.stringValue        = String(s.ctxSize)
        diskKVCheck.state           = s.enableDiskKV ? .on : .off
        kvDirField.stringValue      = s.kvDiskDir
        kvSizeField.stringValue     = String(s.kvDiskSpaceMB)
        corsCheck.state             = s.enableCORS ? .on : .off
        noThinkCheck.state          = s.noThink ? .on : .off
        powerSlider.doubleValue     = Double(s.powerPercent)
        powerLabel.stringValue      = "\(s.powerPercent)%"
    }

    private func saveValues() {
        let s = Settings.shared
        s.modelPath     = modelPathField.stringValue.trimmingCharacters(in: .whitespaces)
        s.port          = Int(portField.stringValue) ?? 8000
        s.host          = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        s.ctxSize       = Int(ctxField.stringValue) ?? 100000
        s.enableDiskKV  = diskKVCheck.state == .on
        s.kvDiskDir     = kvDirField.stringValue.trimmingCharacters(in: .whitespaces)
        s.kvDiskSpaceMB = Int(kvSizeField.stringValue) ?? 8192
        s.enableCORS    = corsCheck.state == .on
        s.noThink       = noThinkCheck.state == .on
        s.powerPercent  = Int(powerSlider.doubleValue)
    }

    // MARK: - Actions

    @objc private func browseClicked(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseFiles       = sender.tag != 3
        panel.canChooseDirectories = sender.tag == 3
        panel.canCreateDirectories = sender.tag == 3
        panel.allowsMultipleSelection = false
        panel.title = sender.tag == 1 ? L("settings.panel.model") : L("settings.panel.kv_dir")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        switch sender.tag {
        case 1: modelPathField.stringValue = url.path
        case 3: kvDirField.stringValue     = url.path
        default: break
        }
    }

    @objc private func powerChanged() {
        powerLabel.stringValue = "\(Int(powerSlider.doubleValue))%"
    }

    @objc private func applyClicked() {
        saveValues()
        close()
        onApply?()
    }

    @objc private func cancelClicked() {
        close()
    }
}
