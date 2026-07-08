import AppKit
import NotepadMacCore

final class ExtensionManagerWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    var onClose: (() -> Void)?

    private enum Column {
        static let extensionName = NSUserInterfaceItemIdentifier("extension")
        static let description = NSUserInterfaceItemIdentifier("description")
        static let kind = NSUserInterfaceItemIdentifier("kind")
        static let version = NSUserInterfaceItemIdentifier("version")
        static let status = NSUserInterfaceItemIdentifier("status")
    }

    private var catalog: ExtensionCatalog
    private var visibleExtensions: [DownloadableExtension]
    private let installedProvider: () -> InstalledExtensions
    private let hasLocalPackage: (DownloadableExtension) -> Bool
    private let refreshCatalogFromRepository: () throws -> ExtensionCatalog
    private let downloadExtension: (DownloadableExtension) throws -> Void
    private let loadExtension: (DownloadableExtension) throws -> Void
    private let activateExtension: (String) -> Void
    private let deactivateExtension: (String) -> Void
    private let deleteExtension: (String) -> Void
    private let searchField = NSSearchField()
    private let tableView = NSTableView()
    private let refreshCatalogButton = NSButton(title: "Refresh Catalog", target: nil, action: nil)
    private let downloadButton = NSButton(title: "Download", target: nil, action: nil)
    private let loadButton = NSButton(title: "Load", target: nil, action: nil)
    private let activateButton = NSButton(title: "Activate", target: nil, action: nil)
    private let deactivateButton = NSButton(title: "Deactivate", target: nil, action: nil)
    private let deleteButton = NSButton(title: "Delete", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "Catalog: bundled")

    init(
        catalog: ExtensionCatalog,
        installedProvider: @escaping () -> InstalledExtensions,
        hasLocalPackage: @escaping (DownloadableExtension) -> Bool,
        refreshCatalogFromRepository: @escaping () throws -> ExtensionCatalog,
        downloadExtension: @escaping (DownloadableExtension) throws -> Void,
        loadExtension: @escaping (DownloadableExtension) throws -> Void,
        activateExtension: @escaping (String) -> Void,
        deactivateExtension: @escaping (String) -> Void,
        deleteExtension: @escaping (String) -> Void
    ) {
        self.catalog = catalog
        self.visibleExtensions = catalog.extensions
        self.installedProvider = installedProvider
        self.hasLocalPackage = hasLocalPackage
        self.refreshCatalogFromRepository = refreshCatalogFromRepository
        self.downloadExtension = downloadExtension
        self.loadExtension = loadExtension
        self.activateExtension = activateExtension
        self.deactivateExtension = deactivateExtension
        self.deleteExtension = deleteExtension

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Manage Extensions"
        window.minSize = NSSize(width: 620, height: 300)
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
        applySearchPreservingSelection()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        visibleExtensions.count
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSSearchField, field === searchField else { return }
        applySearchPreservingSelection()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard visibleExtensions.indices.contains(row),
              let tableColumn else {
            return nil
        }

        let item = visibleExtensions[row]
        let textField = NSTextField(labelWithString: text(for: tableColumn.identifier, item: item))
        textField.lineBreakMode = .byTruncatingMiddle
        return textField
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    @objc private func refreshCatalog(_ sender: Any?) {
        do {
            catalog = try refreshCatalogFromRepository()
            statusLabel.stringValue = "Catalog: MacPadPro GitHub repo"
            applySearchPreservingSelection()
        } catch {
            showError(title: "Could Not Refresh Catalog", message: error.localizedDescription)
        }
    }

    @objc private func searchCatalog(_ sender: Any?) {
        applySearchPreservingSelection()
    }

    @objc private func downloadSelectedExtension(_ sender: Any?) {
        guard let selectedExtension else { return }
        do {
            try downloadExtension(selectedExtension)
            statusLabel.stringValue = "Downloaded: \(selectedExtension.title)"
            refresh()
        } catch {
            showError(title: "Could Not Download Extension", message: error.localizedDescription)
        }
    }

    @objc private func loadSelectedExtension(_ sender: Any?) {
        guard let selectedExtension else { return }
        do {
            try loadExtension(selectedExtension)
            statusLabel.stringValue = "Loaded: \(selectedExtension.title)"
            refresh()
        } catch {
            showError(title: "Could Not Load Extension", message: error.localizedDescription)
        }
    }

    @objc private func activateSelectedExtension(_ sender: Any?) {
        guard let selectedExtension else { return }
        activateExtension(selectedExtension.id)
        refresh()
    }

    @objc private func deactivateSelectedExtension(_ sender: Any?) {
        guard let selectedExtension else { return }
        deactivateExtension(selectedExtension.id)
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

        let topControls = NSStackView()
        topControls.orientation = .horizontal
        topControls.spacing = 8
        topControls.alignment = .centerY
        topControls.setContentHuggingPriority(.required, for: .vertical)

        searchField.placeholderString = "Search MacPadPro GitHub extensions"
        searchField.target = self
        searchField.action = #selector(searchCatalog(_:))
        searchField.delegate = self

        refreshCatalogButton.target = self
        refreshCatalogButton.action = #selector(refreshCatalog(_:))

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingMiddle

        topControls.addArrangedSubview(searchField)
        topControls.addArrangedSubview(refreshCatalogButton)
        topControls.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(topControls)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .bezelBorder

        tableView.addTableColumn(makeColumn(identifier: Column.extensionName, title: "Extension", width: 220))
        tableView.addTableColumn(makeColumn(identifier: Column.description, title: "Description", width: 300))
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

        downloadButton.target = self
        downloadButton.action = #selector(downloadSelectedExtension(_:))
        loadButton.target = self
        loadButton.action = #selector(loadSelectedExtension(_:))
        activateButton.target = self
        activateButton.action = #selector(activateSelectedExtension(_:))
        deactivateButton.target = self
        deactivateButton.action = #selector(deactivateSelectedExtension(_:))
        deleteButton.target = self
        deleteButton.action = #selector(deleteSelectedExtension(_:))

        controls.addArrangedSubview(downloadButton)
        controls.addArrangedSubview(loadButton)
        controls.addArrangedSubview(activateButton)
        controls.addArrangedSubview(deactivateButton)
        controls.addArrangedSubview(deleteButton)
        controls.addArrangedSubview(NSView())
        stack.addArrangedSubview(controls)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchField.widthAnchor.constraint(greaterThanOrEqualToConstant: 240)
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
        guard visibleExtensions.indices.contains(row) else { return nil }
        return visibleExtensions[row]
    }

    private func updateButtons() {
        guard let selectedExtension else {
            downloadButton.isEnabled = false
            loadButton.isEnabled = false
            activateButton.isEnabled = false
            deactivateButton.isEnabled = false
            deleteButton.isEnabled = false
            return
        }

        let installed = installedProvider()
        let isInstalled = installed.isInstalled(selectedExtension.id)
        let isActive = installed.isActive(selectedExtension.id)
        downloadButton.isEnabled = !isInstalled
        loadButton.isEnabled = !isInstalled && hasLocalPackage(selectedExtension)
        activateButton.isEnabled = isInstalled && !isActive
        deactivateButton.isEnabled = isInstalled && isActive
        deleteButton.isEnabled = isInstalled
    }

    private func text(for column: NSUserInterfaceItemIdentifier, item: DownloadableExtension) -> String {
        switch column {
        case Column.extensionName:
            item.title
        case Column.description:
            item.description
        case Column.kind:
            item.kind.rawValue
        case Column.version:
            item.version
        case Column.status:
            statusText(for: item)
        default:
            ""
        }
    }

    private func statusText(for item: DownloadableExtension) -> String {
        let installed = installedProvider()
        if !installed.isInstalled(item.id) {
            return "Not Loaded"
        }
        return installed.isActive(item.id) ? "Active" : "Inactive"
    }

    private func applySearchPreservingSelection() {
        let selectedID = selectedExtension?.id
        visibleExtensions = catalog.search(matching: searchField.stringValue)
        tableView.reloadData()

        if let selectedID,
           let selectedIndex = visibleExtensions.firstIndex(where: { $0.id == selectedID }) {
            tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
        }

        updateButtons()
    }

    private func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message

        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
