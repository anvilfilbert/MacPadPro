import AppKit
import NotepadMacCore

@MainActor
final class FileOutlineWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?
    private let tableView = NSTableView()
    private var items: [FileOutlineItem]
    private let openLine: (Int) -> Void

    init(items: [FileOutlineItem], openLine: @escaping (Int) -> Void) {
        self.items = items
        self.openLine = openLine
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "File Outline"
        window.delegate = self
        window.center()
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(items: [FileOutlineItem]) {
        self.items = items
        tableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("OutlineCell")
        let textField = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField
            ?? NSTextField(labelWithString: "")
        textField.identifier = identifier
        textField.lineBreakMode = .byTruncatingTail

        let item = items[row]
        if tableColumn?.identifier.rawValue == "line" {
            textField.stringValue = "\(item.line)"
        } else {
            textField.stringValue = item.title
        }
        return textField
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        guard items.indices.contains(selectedRow) else { return }
        openLine(items[selectedRow].line)
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func setupUI() {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.frame = window?.contentView?.bounds ?? .zero

        let lineColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("line"))
        lineColumn.title = "Line"
        lineColumn.width = 56
        tableView.addTableColumn(lineColumn)

        let titleColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        titleColumn.title = "Symbol"
        titleColumn.width = 260
        tableView.addTableColumn(titleColumn)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = true

        scrollView.documentView = tableView
        window?.contentView = scrollView
    }
}
