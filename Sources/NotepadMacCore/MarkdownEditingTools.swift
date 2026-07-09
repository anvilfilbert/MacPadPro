import Foundation

public enum MarkdownEditingError: LocalizedError, Equatable {
    case emptyText

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Markdown command needs text to edit."
        }
    }
}

public enum MarkdownEditingTools {
    public static func toggleCheckbox(_ text: String) throws -> String {
        guard !text.isEmpty else { throw MarkdownEditingError.emptyText }

        if text.contains("- [ ]") {
            return text.replacingOccurrences(of: "- [ ]", with: "- [x]")
        }
        if text.contains("- [x]") {
            return text.replacingOccurrences(of: "- [x]", with: "- [ ]")
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in "- [ ] \(line.trimmingCharacters(in: .whitespaces))" }
            .joined(separator: "\n")
    }

    public static func insertTable() -> String {
        """
        | Column 1 | Column 2 |
        | --- | --- |
        |  |  |
        """
    }

    public static func formatUnorderedList(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("- ") {
                    return trimmed
                }
                return "- \(trimmed)"
            }
            .joined(separator: "\n")
    }

    public static func renumberOrderedList(_ text: String) -> String {
        var index = 1
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                let textLine = String(line)
                guard let match = orderedListMatch(in: textLine) else { return textLine }
                defer { index += 1 }
                return "\(index). \(match)"
            }
            .joined(separator: "\n")
    }

    private static func orderedListMatch(in line: String) -> String? {
        let pattern = #"^\s*\d+\.\s+(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let contentRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        return String(line[contentRange])
    }
}
