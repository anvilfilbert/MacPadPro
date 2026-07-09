import XCTest
@testable import NotepadMacCore

final class RepositoryExtensionValidatorTests: XCTestCase {
    func testValidatorAcceptsCurrentRepositoryCatalogAndPackages() throws {
        let root = try repoRoot()
        let catalog = try repositoryExtensionCatalog(root: root)

        let report = try RepositoryExtensionValidator().validate(
            repositoryRoot: root,
            catalog: catalog,
            builtInCatalog: .default
        )

        XCTAssertTrue(report.issues.isEmpty, report.issues.map(\.description).joined(separator: "\n"))
        XCTAssertEqual(report.validatedExtensionIDs.count, ExtensionCatalog.default.extensions.count)
    }

    func testValidatorReportsMissingPackageDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let extensionItem = DownloadableExtension(
            id: "missing-package",
            title: "Missing Package",
            description: "Missing package.",
            version: "1.0.0",
            kind: .textCommand,
            downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/missing-package/missing-package.macpadproext")!
        )

        let report = try RepositoryExtensionValidator().validate(
            repositoryRoot: root,
            catalog: ExtensionCatalog(extensions: [extensionItem]),
            builtInCatalog: ExtensionCatalog(extensions: [extensionItem])
        )

        XCTAssertEqual(report.issues, [.missingPackageDirectory(extensionID: "missing-package")])
    }

    private func repositoryExtensionCatalog(root: URL) throws -> ExtensionCatalog {
        let catalogURL = root
            .appendingPathComponent("RepositoryExtensions")
            .appendingPathComponent("catalog.json")
        let data = try Data(contentsOf: catalogURL)
        return try JSONDecoder().decode(ExtensionCatalog.self, from: data)
    }

    private func repoRoot() throws -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        return testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
