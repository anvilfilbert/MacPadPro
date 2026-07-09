import Foundation

public enum LineEndingConverter {
    public static func convert(_ text: String, to lineEnding: LineEnding) -> String {
        TextMetrics.textForSave(text, lineEnding: lineEnding)
    }
}

public struct DelimitedTextTable: Sendable, Equatable {
    public let headers: [String]
    public let rows: [[String]]

    public init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }
}

public enum DelimitedTextTableError: LocalizedError, Equatable {
    case emptyInput
    case missingRows

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Table preview needs CSV or TSV text."
        case .missingRows:
            return "Table preview needs a header row and at least one data row."
        }
    }
}

public enum DelimitedTextTableParser {
    public static func parse(_ text: String, delimiter: Character) throws -> DelimitedTextTable {
        let lines = text
            .split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
            .map(String.init)
        guard let headerLine = lines.first else { throw DelimitedTextTableError.emptyInput }
        guard lines.count > 1 else { throw DelimitedTextTableError.missingRows }

        let headers = split(headerLine, delimiter: delimiter)
        let rows = lines.dropFirst().map { split($0, delimiter: delimiter) }
        return DelimitedTextTable(headers: headers, rows: rows)
    }

    private static func split(_ line: String, delimiter: Character) -> [String] {
        line
            .split(separator: delimiter, omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
    }
}

public enum MarkdownPreviewRenderer {
    public static func html(for markdown: String) -> String {
        let body = markdown
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { renderLine(String($0)) }
            .joined(separator: "\n")
        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        body { font: -apple-system-body; margin: 24px; line-height: 1.5; color: #1f2328; background: #ffffff; }
        code { font-family: ui-monospace, Menlo, monospace; background: #f6f8fa; padding: 2px 4px; border-radius: 4px; }
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    private static func renderLine(_ line: String) -> String {
        if line.hasPrefix("### ") {
            return "<h3>\(escape(String(line.dropFirst(4))))</h3>"
        }
        if line.hasPrefix("## ") {
            return "<h2>\(escape(String(line.dropFirst(3))))</h2>"
        }
        if line.hasPrefix("# ") {
            return "<h1>\(escape(String(line.dropFirst(2))))</h1>"
        }
        if line.hasPrefix("- ") {
            return "<li>\(escape(String(line.dropFirst(2))))</li>"
        }
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ""
        }
        return "<p>\(escape(line))</p>"
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

public struct FileOutlineItem: Sendable, Equatable {
    public let title: String
    public let line: Int

    public init(title: String, line: Int) {
        self.title = title
        self.line = line
    }
}

public enum FileOutlineParser {
    public static func items(for text: String, languageID: String) -> [FileOutlineItem] {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .compactMap { index, line in
                item(for: String(line), lineNumber: index + 1, languageID: languageID)
            }
    }

    private static func item(for line: String, lineNumber: Int, languageID: String) -> FileOutlineItem? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") {
            let title = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
            return title.isEmpty ? nil : FileOutlineItem(title: title, line: lineNumber)
        }
        if let className = firstCapture(in: trimmed, pattern: #"^class\s+([A-Za-z_][A-Za-z0-9_]*)"#) {
            return FileOutlineItem(title: className, line: lineNumber)
        }
        if let functionName = firstCapture(in: trimmed, pattern: #"^func\s+([A-Za-z_][A-Za-z0-9_]*\(\))"#) {
            return FileOutlineItem(title: functionName, line: lineNumber)
        }
        if languageID == "php",
           let phpFunctionName = firstCapture(in: trimmed, pattern: #"^public\s+function\s+([A-Za-z_][A-Za-z0-9_]*\(\))"#) {
            return FileOutlineItem(title: phpFunctionName, line: lineNumber)
        }
        return nil
    }

    private static func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }
}
