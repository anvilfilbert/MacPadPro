import XCTest
@testable import NotepadMacCore

final class ExtensionContributionTests: XCTestCase {
    func testContributionFoldsActiveRuntimePayloadsThroughOneInterface() {
        let contribution = ExtensionContribution(
            catalogEntry: DownloadableExtension(
                id: "sample-command",
                title: "Sample Command",
                description: "Sample command.",
                version: "1.0.0",
                kind: .textCommand,
                downloadURL: URL(string: "https://example.com/sample-command.macpadproext")!
            ),
            textCommands: [TextCommand(id: "sample-command", title: "Sample Command") { text in text.uppercased() }]
        )
        let registry = ExtensionRegistry.loaded(
            installedExtensions: InstalledExtensions(installedIDs: ["sample-command"]),
            contributions: [contribution]
        )

        XCTAssertEqual(registry.textCommands.map(\.id), ["trim-trailing-whitespace", "sort-lines", "uppercase", "lowercase", "sample-command"])
        XCTAssertEqual(try registry.textCommands.last?.transform("MacPad Pro"), "MACPAD PRO")
    }

    func testContributionDoesNotFoldInactiveRuntimePayloads() {
        let contribution = ExtensionContribution(
            catalogEntry: DownloadableExtension(
                id: "sample-command",
                title: "Sample Command",
                description: "Sample command.",
                version: "1.0.0",
                kind: .textCommand,
                downloadURL: URL(string: "https://example.com/sample-command.macpadproext")!
            ),
            textCommands: [TextCommand(id: "sample-command", title: "Sample Command") { text in text }]
        )
        let registry = ExtensionRegistry.loaded(
            installedExtensions: InstalledExtensions(installedIDs: []),
            contributions: [contribution]
        )

        XCTAssertFalse(registry.textCommands.contains { $0.id == "sample-command" })
    }

    func testDefaultCatalogComesFromBuiltInContributions() {
        XCTAssertEqual(
            ExtensionCatalog.default.extensions.map(\.id),
            ExtensionContribution.builtIn.map(\.catalogEntry.id)
        )
    }
}
