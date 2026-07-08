import AppKit
import NotepadMacCore

@MainActor
final class AISmartSearchWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?

    private let searchField = NSSearchField()
    private let tableView = NSTableView()
    private let statusLabel = NSTextField(labelWithString: "")
    private var results: [AISearchResult] = []
    private let runSearch: (String) async throws -> [AISearchResult]
    private let openDocument: (String) -> Void

    init(runSearch: @escaping (String) async throws -> [AISearchResult], openDocument: @escaping (String) -> Void) {
        self.runSearch = runSearch
        self.openDocument = openDocument
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 420),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "AI Smart Search"
        window.delegate = self
        window.center()
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        results.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard results.indices.contains(row), let identifier = tableColumn?.identifier else { return nil }
        let result = results[row]
        let value = identifier.rawValue == "title" ? result.title : result.reason
        let cell = NSTextField(labelWithString: value)
        cell.lineBreakMode = .byTruncatingTail
        return cell
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let searchButton = NSButton(title: "Search", target: self, action: #selector(search(_:)))
        searchField.target = self
        searchField.action = #selector(search(_:))
        let searchRow = NSStackView(views: [searchField, searchButton])
        searchRow.orientation = .horizontal
        searchRow.spacing = 8
        stack.addArrangedSubview(searchRow)

        let titleColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        titleColumn.title = "Document"
        titleColumn.width = 190
        tableView.addTableColumn(titleColumn)

        let reasonColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("reason"))
        reasonColumn.title = "Reason"
        reasonColumn.width = 360
        tableView.addTableColumn(reasonColumn)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(openSelectedResult(_:))

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        stack.addArrangedSubview(scrollView)
        stack.addArrangedSubview(statusLabel)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
    }

    @objc private func search(_ sender: Any?) {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            NSSound.beep()
            return
        }

        statusLabel.stringValue = "Searching..."
        Task {
            do {
                results = try await runSearch(query)
                tableView.reloadData()
                statusLabel.stringValue = "\(results.count) result(s)"
            } catch {
                statusLabel.stringValue = error.localizedDescription
                NSSound.beep()
            }
        }
    }

    @objc private func openSelectedResult(_ sender: Any?) {
        guard results.indices.contains(tableView.selectedRow) else { return }
        openDocument(results[tableView.selectedRow].documentID)
    }
}
