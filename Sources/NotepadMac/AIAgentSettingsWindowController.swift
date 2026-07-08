import AppKit
import NotepadMacCore

@MainActor
final class AIAgentSettingsWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let endpointField = NSTextField()
    private let modelField = NSTextField()
    private let tokenField = NSSecureTextField()
    private let responseModePopup = NSPopUpButton()
    private let saveSettings: (AIAgentConfiguration?) -> Void

    init(configuration: AIAgentConfiguration?, saveSettings: @escaping (AIAgentConfiguration?) -> Void) {
        self.saveSettings = saveSettings
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "AI Agent Settings"
        window.delegate = self
        window.center()
        setupUI(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func setupUI(configuration: AIAgentConfiguration?) {
        guard let contentView = window?.contentView else { return }

        let grid = NSGridView()
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 10
        grid.columnSpacing = 12
        contentView.addSubview(grid)

        endpointField.placeholderString = "http://localhost:11434/v1/chat/completions"
        endpointField.stringValue = configuration?.endpointURL.absoluteString ?? ""
        modelField.placeholderString = "model"
        modelField.stringValue = configuration?.modelName ?? ""
        tokenField.placeholderString = "Optional"
        tokenField.stringValue = configuration?.apiToken ?? ""
        responseModePopup.addItem(withTitle: "OpenAI-compatible JSON")

        addRow("Endpoint URL", endpointField, to: grid)
        addRow("Model", modelField, to: grid)
        addRow("API Token", tokenField, to: grid)
        addRow("Response Mode", responseModePopup, to: grid)

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save(_:)))
        let clearButton = NSButton(title: "Clear", target: self, action: #selector(clear(_:)))
        let buttons = NSStackView(views: [clearButton, saveButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.alignment = .trailing
        buttons.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttons)

        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            grid.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            buttons.trailingAnchor.constraint(equalTo: grid.trailingAnchor),
            buttons.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 18)
        ])
    }

    private func addRow(_ label: String, _ control: NSView, to grid: NSGridView) {
        let labelView = NSTextField(labelWithString: label)
        labelView.alignment = .right
        control.translatesAutoresizingMaskIntoConstraints = false
        grid.addRow(with: [labelView, control])
        control.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
    }

    @objc private func save(_ sender: Any?) {
        let endpointText = endpointField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelName = modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = tokenField.stringValue.isEmpty ? nil : tokenField.stringValue

        guard let url = URL(string: endpointText), !modelName.isEmpty else {
            NSSound.beep()
            return
        }

        saveSettings(AIAgentConfiguration(
            endpointURL: url,
            modelName: modelName,
            apiToken: token,
            responseMode: .openAICompatibleJSON
        ))
        close()
    }

    @objc private func clear(_ sender: Any?) {
        saveSettings(nil)
        close()
    }
}
