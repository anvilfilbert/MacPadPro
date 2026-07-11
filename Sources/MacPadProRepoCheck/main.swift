import Foundation
import NotepadMacCore

let arguments = CommandLine.arguments
let rootPath = arguments.count > 1 ? arguments[1] : FileManager.default.currentDirectoryPath
let repositoryRoot = URL(fileURLWithPath: rootPath, isDirectory: true)
let catalogURL = repositoryRoot
    .appendingPathComponent("RepositoryExtensions", isDirectory: true)
    .appendingPathComponent("catalog.json")
let infoPlistURL = repositoryRoot
    .appendingPathComponent("Resources", isDirectory: true)
    .appendingPathComponent("Info.plist")

do {
    let catalogData = try Data(contentsOf: catalogURL)
    let catalog = try JSONDecoder().decode(ExtensionCatalog.self, from: catalogData)
    let infoPlistData = try Data(contentsOf: infoPlistURL)
    let infoPlist = try PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil)
    guard let infoDictionary = infoPlist as? [String: Any],
          let currentVersion = infoDictionary["CFBundleShortVersionString"] as? String else {
        throw CocoaError(.fileReadCorruptFile)
    }
    let report = try RepositoryExtensionValidator().validate(
        repositoryRoot: repositoryRoot,
        catalog: catalog,
        builtInCatalog: .default,
        currentMacPadProVersion: currentVersion
    )

    if !report.issues.isEmpty {
        for issue in report.issues {
            FileHandle.standardError.write(Data("Repository extension validation failed: \(issue.description)\n".utf8))
        }
        exit(1)
    }

    print("Repository extension validation passed (\(report.validatedExtensionIDs.count) extensions)")
} catch {
    FileHandle.standardError.write(Data("Repository extension validation failed: \(error.localizedDescription)\n".utf8))
    exit(1)
}
