import AppKit

struct VersionHistoryItem: Equatable {
    let id: String
    let title: String
    let createdAt: Date
    let preview: String
    let content: String
}

@MainActor
final class VersionHistoryWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?
    private let tableView = NSTableView()
    private var items: [VersionHistoryItem]
    private let restore: (String) -> Void
    private let copy: (String) -> Void

    init(items: [VersionHistoryItem], restore: @escaping (String) -> Void, copy: @escaping (String) -> Void) {
        self.items = items
        self.restore = restore
        self.copy = copy
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "Version History"
        window.delegate = self
        window.center()
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(items: [VersionHistoryItem]) {
        self.items = items
        tableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("VersionCell")
        let textField = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField
            ?? NSTextField(labelWithString: "")
        textField.identifier = identifier
        textField.lineBreakMode = .byTruncatingTail

        let item = items[row]
        switch tableColumn?.identifier.rawValue {
        case "title":
            textField.stringValue = item.title
        case "date":
            textField.stringValue = Self.dateFormatter.string(from: item.createdAt)
        default:
            textField.stringValue = item.preview.replacingOccurrences(of: "\n", with: " ")
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
        addColumn(id: "date", title: "Date", width: 180)
        addColumn(id: "title", title: "Document", width: 160)
        addColumn(id: "preview", title: "Preview", width: 340)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.setAccessibilityIdentifier("macpadpro.version-history.table")
        scrollView.documentView = tableView
        root.addArrangedSubview(scrollView)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.addArrangedSubview(button(title: "Restore", action: #selector(restoreAction(_:))))
        buttons.addArrangedSubview(button(title: "Copy", action: #selector(copyAction(_:))))
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
        let identifierTitle = title.lowercased().replacingOccurrences(of: " ", with: "-")
        button.setAccessibilityIdentifier("macpadpro.version-history.\(identifierTitle)")
        return button
    }

    @objc private func restoreAction(_ sender: Any?) {
        guard let item = selectedItem else { return }
        restore(item.id)
    }

    @objc private func copyAction(_ sender: Any?) {
        guard let item = selectedItem else { return }
        copy(item.id)
    }

    private var selectedItem: VersionHistoryItem? {
        let row = tableView.selectedRow
        guard items.indices.contains(row) else { return nil }
        return items[row]
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
