import AppKit
import NotepadMacCore

final class DocumentBrowserWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?

    private enum Column {
        static let document = NSUserInterfaceItemIdentifier("document")
        static let location = NSUserInterfaceItemIdentifier("location")
    }

    private let documentsProvider: () -> [DocumentBrowserItem]
    private let openDocument: (DocumentBrowserItem) -> Void
    private let tableView = NSTableView()
    private var documents: [DocumentBrowserItem] = []

    init(
        title: String,
        documentsProvider: @escaping () -> [DocumentBrowserItem],
        openDocument: @escaping (DocumentBrowserItem) -> Void
    ) {
        self.documentsProvider = documentsProvider
        self.openDocument = openDocument

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.minSize = NSSize(width: 320, height: 220)
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
        documents = documentsProvider()
        tableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        documents.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard documents.indices.contains(row),
              let tableColumn else {
            return nil
        }

        let textField = NSTextField(labelWithString: text(for: tableColumn.identifier, item: documents[row]))
        textField.lineBreakMode = .byTruncatingMiddle
        return textField
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    @objc private func openSelectedDocument(_ sender: Any?) {
        let row = tableView.selectedRow
        guard documents.indices.contains(row) else { return }
        openDocument(documents[row])
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        tableView.addTableColumn(makeColumn(identifier: Column.document, title: "Document", width: 180))
        tableView.addTableColumn(makeColumn(identifier: Column.location, title: "Location", width: 300))
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnResizing = true
        tableView.setAccessibilityIdentifier("macpadpro.document-browser.table")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(openSelectedDocument(_:))

        scrollView.documentView = tableView
        contentView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func makeColumn(identifier: NSUserInterfaceItemIdentifier, title: String, width: CGFloat) -> NSTableColumn {
        let column = NSTableColumn(identifier: identifier)
        column.title = title
        column.width = width
        column.minWidth = 120
        return column
    }

    private func text(for column: NSUserInterfaceItemIdentifier, item: DocumentBrowserItem) -> String {
        switch column {
        case Column.document:
            item.title
        case Column.location:
            item.location
        default:
            ""
        }
    }
}
