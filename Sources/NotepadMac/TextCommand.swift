import AppKit
import Foundation

enum TextCommand: String, CaseIterable {
    case trimTrailingWhitespace
    case sortLines
    case uppercase
    case lowercase
    case prettyPrintJSON

    var title: String {
        switch self {
        case .trimTrailingWhitespace: "Trim Trailing Whitespace"
        case .sortLines: "Sort Lines"
        case .uppercase: "Uppercase"
        case .lowercase: "Lowercase"
        case .prettyPrintJSON: "Pretty Print JSON"
        }
    }

    func transform(_ text: String) throws -> String {
        switch self {
        case .trimTrailingWhitespace:
            text
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: "\n")
        case .sortLines:
            text
                .split(separator: "\n", omittingEmptySubsequences: false)
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                .joined(separator: "\n")
        case .uppercase:
            text.uppercased()
        case .lowercase:
            text.lowercased()
        case .prettyPrintJSON:
            try prettyPrintedJSON(text)
        }
    }

    private func prettyPrintedJSON(_ text: String) throws -> String {
        let data = Data(text.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(data: prettyData, encoding: .utf8) ?? text
    }
}
