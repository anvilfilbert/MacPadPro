import AppKit
import NotepadMacCore

@MainActor
final class ClipboardSnippetsWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?
    private let tableView = NSTableView()
    private var rows: [ClipboardSnippetRow] = []
    private let captureClipboard: () -> ClipboardSnippetStore
    private let pinSnippet: (String, String) -> ClipboardSnippetStore
    private let renameSnippet: (String, String) -> ClipboardSnippetStore
    private let deleteSnippet: (String) -> ClipboardSnippetStore
    private let insertSnippet: (String) -> Void

    init(
        store: ClipboardSnippetStore,
        captureClipboard: @escaping () -> ClipboardSnippetStore,
        pinSnippet: @escaping (String, String) -> ClipboardSnippetStore,
        renameSnippet: @escaping (String, String) -> ClipboardSnippetStore,
        deleteSnippet: @escaping (String) -> ClipboardSnippetStore,
        insertSnippet: @escaping (String) -> Void
    ) {
        self.captureClipboard = captureClipboard
        self.pinSnippet = pinSnippet
        self.renameSnippet = renameSnippet
        self.deleteSnippet = deleteSnippet
        self.insertSnippet = insertSnippet
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "Clipboard & Snippets"
        window.delegate = self
        window.center()
        setupUI()
        update(store: store)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(store: ClipboardSnippetStore) {
        rows = store.pinned.map { ClipboardSnippetRow(kind: "Pinned", snippet: $0) }
            + store.recent.map { ClipboardSnippetRow(kind: "Recent", snippet: $0) }
        tableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("SnippetCell")
        let textField = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField
            ?? NSTextField(labelWithString: "")
        textField.identifier = identifier
        textField.lineBreakMode = .byTruncatingTail

        let item = rows[row]
        switch tableColumn?.identifier.rawValue {
        case "kind":
            textField.stringValue = item.kind
        case "name":
            textField.stringValue = item.snippet.name
        default:
            textField.stringValue = item.snippet.content.replacingOccurrences(of: "\n", with: " ")
        }
        return textField
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func setupUI() {
        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        window?.contentView = root

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addColumn(id: "kind", title: "Type", width: 80)
        addColumn(id: "name", title: "Name", width: 160)
        addColumn(id: "content", title: "Content", width: 400)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAlternatingRowBackgroundColors = true
        scrollView.documentView = tableView
        root.addArrangedSubview(scrollView)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.alignment = .centerY
        buttons.addArrangedSubview(button(title: "Capture Clipboard", action: #selector(captureClipboardAction(_:))))
        buttons.addArrangedSubview(button(title: "Pin", action: #selector(pinAction(_:))))
        buttons.addArrangedSubview(button(title: "Rename", action: #selector(renameAction(_:))))
        buttons.addArrangedSubview(button(title: "Insert", action: #selector(insertAction(_:))))
        buttons.addArrangedSubview(button(title: "Delete Pin", action: #selector(deleteAction(_:))))
        root.addArrangedSubview(buttons)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: root.superview!.leadingAnchor, constant: 12),
            root.trailingAnchor.constraint(equalTo: root.superview!.trailingAnchor, constant: -12),
            root.topAnchor.constraint(equalTo: root.superview!.topAnchor, constant: 12),
            root.bottomAnchor.constraint(equalTo: root.superview!.bottomAnchor, constant: -12),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320)
        ])
    }

    private func addColumn(id: String, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
        column.title = title
        column.width = width
        tableView.addTableColumn(column)
    }

    private func button(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        return button
    }

    @objc private func captureClipboardAction(_ sender: Any?) {
        update(store: captureClipboard())
    }

    @objc private func pinAction(_ sender: Any?) {
        guard let row = selectedRow, row.kind == "Recent",
              let name = requestName(title: "Pin Snippet", value: row.snippet.name) else { return }
        update(store: pinSnippet(row.snippet.id, name))
    }

    @objc private func renameAction(_ sender: Any?) {
        guard let row = selectedRow, row.kind == "Pinned",
              let name = requestName(title: "Rename Snippet", value: row.snippet.name) else { return }
        update(store: renameSnippet(row.snippet.id, name))
    }

    @objc private func insertAction(_ sender: Any?) {
        guard let row = selectedRow else { return }
        insertSnippet(row.snippet.content)
    }

    @objc private func deleteAction(_ sender: Any?) {
        guard let row = selectedRow, row.kind == "Pinned" else { return }
        update(store: deleteSnippet(row.snippet.id))
    }

    private var selectedRow: ClipboardSnippetRow? {
        let row = tableView.selectedRow
        guard rows.indices.contains(row) else { return nil }
        return rows[row]
    }

    private func requestName(title: String, value: String) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        input.stringValue = value
        alert.accessoryView = input
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }
}

private struct ClipboardSnippetRow {
    let kind: String
    let snippet: ClipboardSnippet
}
