import AppKit

// MARK: - LogWindowController
// Singleton: displays real-time log output from ds4-server

final class LogWindowController: NSWindowController {

    static let shared = LogWindowController()

    private var textView: NSTextView!
    private let maxLogBytes = 2 * 1024 * 1024  // 2 MB cap

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 460),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L("log.window.title")
        window.center()

        super.init(window: window)

        let scroll = NSScrollView(frame: window.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true

        let tv = NSTextView(frame: scroll.bounds)
        tv.isEditable = false
        tv.isSelectable = true
        tv.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.backgroundColor = NSColor(white: 0.08, alpha: 1)
        tv.textColor = NSColor(white: 0.9, alpha: 1)
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = CGSize(
            width: scroll.bounds.width, height: .greatestFiniteMagnitude)

        scroll.documentView = tv
        window.contentView?.addSubview(scroll)
        textView = tv
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    func append(_ text: String) {
        guard let tv = textView else { return }
        let attr = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor(white: 0.9, alpha: 1)
        ])
        let storage = tv.textStorage!
        storage.append(attr)
        if storage.length > maxLogBytes {
            storage.deleteCharacters(in: NSRange(location: 0, length: storage.length / 2))
        }
        tv.scrollToEndOfDocument(nil)
    }

    func clear() {
        textView?.textStorage?.setAttributedString(NSAttributedString())
    }
}
