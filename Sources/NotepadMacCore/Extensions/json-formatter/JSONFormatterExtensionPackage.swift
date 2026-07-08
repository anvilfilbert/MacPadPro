import Foundation

enum JSONFormatterExtensionPackage {
    static let id = "json-formatter"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "JSON Formatter",
        description: "Format JSON documents with stable indentation and sorted keys.",
        version: "1.0.0",
        kind: .formatter,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/json-formatter/json-formatter.macpadproext")!
    )

    static let formatters: [any CodeFormatter] = [
        JSONCodeFormatter()
    ]

    static let textCommands: [TextCommand] = [
        TextCommand(id: "pretty-print-json", title: "Pretty Print JSON") { text in
            try JSONCodeFormatter().format(text)
        }
    ]
}

public struct JSONCodeFormatter: CodeFormatter {
    public let id = "json"
    public let name = "JSON"
    public let supportedLanguageIDs: Set<String> = ["json"]

    public init() {}

    public func format(_ text: String) throws -> String {
        let data = Data(text.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(data: prettyData, encoding: .utf8) ?? text
    }
}
