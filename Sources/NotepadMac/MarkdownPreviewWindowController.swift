import AppKit
import WebKit

@MainActor
final class MarkdownPreviewWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?
    private let webView = WKWebView()

    init(html: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "Markdown Preview"
        window.delegate = self
        window.center()
        webView.autoresizingMask = [.width, .height]
        webView.frame = window.contentView?.bounds ?? .zero
        window.contentView = webView
        update(html: html)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(html: String) {
        webView.loadHTMLString(html, baseURL: nil)
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
