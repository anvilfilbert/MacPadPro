import AppKit
import NotepadMacCore

final class ExtensionManagerWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?

    private enum Column {
        static let extensionName = NSUserInterfaceItemIdentifier("extension")
        static let kind = NSUserInterfaceItemIdentifier("kind")
        static let version = NSUserInterfaceItemIdentifier("version")
        static let status = NSUserInterfaceItemIdentifier("status")
    }

    private let catalog: ExtensionCatalog
    private let installedProvider: () -> InstalledExtensions
    private let loadExtension: (String) -> Void
    private let deleteExtension: (String) -> Void
    private let tableView = NSTableView()
    private let loadButton = NSButton(title: "Load", target: nil, action: nil)
    private let deleteButton = NSButton(title: "Delete", target: nil, action: nil)

    init(
        catalog: ExtensionCatalog,
        installedProvider: @escaping () -> InstalledExtensions,
        loadExtension: @escaping (String) -> Void,
        deleteExtension: @escaping (String) -> Void
    ) {
        self.catalog = catalog
        self.installedProvider = installedProvider
        self.loadExtension = loadExtension
        self.deleteExtension = deleteExtension

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Manage Extensions"
        window.minSize = NSSize(width: 460, height: 260)
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self
        setupUI()
        refresh()
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh() {
        tableView.reloadData()
        updateButtons()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        catalog.extensions.count
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard catalog.extensions.indices.contains(row),
              let tableColumn else {
            return nil
        }

        let item = catalog.extensions[row]
        let textField = NSTextField(labelWithString: text(for: tableColumn.identifier, item: item))
        textField.lineBreakMode = .byTruncatingMiddle
        return textField
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    @objc private func loadSelectedExtension(_ sender: Any?) {
        guard let selectedExtension else { return }
        loadExtension(selectedExtension.id)
        refresh()
    }

    @objc private func deleteSelectedExtension(_ sender: Any?) {
        guard let selectedExtension else { return }
        deleteExtension(selectedExtension.id)
        refresh()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .bezelBorder

        tableView.addTableColumn(makeColumn(identifier: Column.extensionName, title: "Extension", width: 220))
        tableView.addTableColumn(makeColumn(identifier: Column.kind, title: "Type", width: 120))
        tableView.addTableColumn(makeColumn(identifier: Column.version, title: "Version", width: 80))
        tableView.addTableColumn(makeColumn(identifier: Column.status, title: "Status", width: 100))
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnResizing = true
        tableView.delegate = self
        tableView.dataSource = self
        scrollView.documentView = tableView
        stack.addArrangedSubview(scrollView)

        let controls = NSStackView()
        controls.orientation = .horizontal
        controls.spacing = 8
        controls.alignment = .centerY
        controls.setContentHuggingPriority(.required, for: .vertical)

        loadButton.target = self
        loadButton.action = #selector(loadSelectedExtension(_:))
        deleteButton.target = self
        deleteButton.action = #selector(deleteSelectedExtension(_:))

        controls.addArrangedSubview(loadButton)
        controls.addArrangedSubview(deleteButton)
        controls.addArrangedSubview(NSView())
        stack.addArrangedSubview(controls)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func makeColumn(identifier: NSUserInterfaceItemIdentifier, title: String, width: CGFloat) -> NSTableColumn {
        let column = NSTableColumn(identifier: identifier)
        column.title = title
        column.width = width
        column.minWidth = 70
        return column
    }

    private var selectedExtension: DownloadableExtension? {
        let row = tableView.selectedRow
        guard catalog.extensions.indices.contains(row) else { return nil }
        return catalog.extensions[row]
    }

    private func updateButtons() {
        guard let selectedExtension else {
            loadButton.isEnabled = false
            deleteButton.isEnabled = false
            return
        }

        let isInstalled = installedProvider().isInstalled(selectedExtension.id)
        loadButton.isEnabled = !isInstalled
        deleteButton.isEnabled = isInstalled
    }

    private func text(for column: NSUserInterfaceItemIdentifier, item: DownloadableExtension) -> String {
        switch column {
        case Column.extensionName:
            item.title
        case Column.kind:
            item.kind.rawValue
        case Column.version:
            item.version
        case Column.status:
            installedProvider().isInstalled(item.id) ? "Loaded" : "Not Loaded"
        default:
            ""
        }
    }
}
