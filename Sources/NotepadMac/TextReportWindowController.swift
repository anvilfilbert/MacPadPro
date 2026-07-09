import AppKit

@MainActor
final class TextReportWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?
    private let textView = NSTextView()

    init(title: String, text: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = title
        window.delegate = self
        window.center()
        setupUI(text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, text: String) {
        window?.title = title
        textView.string = text
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func setupUI(text: String) {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.frame = window?.contentView?.bounds ?? .zero

        textView.string = text
        textView.isEditable = false
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width, .height]

        scrollView.documentView = textView
        window?.contentView = scrollView
    }
}
