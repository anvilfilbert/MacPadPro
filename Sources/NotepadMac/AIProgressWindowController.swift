import AppKit

final class AIProgressWindowController: NSWindowController, NSWindowDelegate {
    var onCancel: (() -> Void)?
    var onClose: (() -> Void)?

    private let messageLabel = NSTextField(labelWithString: "Waiting for AI agent...")
    private let progressIndicator = NSProgressIndicator()

    init(title: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 130),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self
        setupUI()
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        progressIndicator.startAnimation(nil)
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    @objc private func cancel(_ sender: Any?) {
        onCancel?()
        close()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        messageLabel.alignment = .center
        messageLabel.textColor = .secondaryLabelColor
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .regular

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.addArrangedSubview(NSView())
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        buttonRow.addArrangedSubview(cancelButton)

        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(progressIndicator)
        stack.addArrangedSubview(buttonRow)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
