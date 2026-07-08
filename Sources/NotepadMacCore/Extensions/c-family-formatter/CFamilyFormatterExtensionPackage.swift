import Foundation

enum CFamilyFormatterExtensionPackage {
    static let id = "c-family-formatter"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "C/PHP Formatter",
        description: "Format PHP, C, C++, Java, JavaScript, TypeScript, and CSS brace-style code.",
        version: "1.0.0",
        kind: .formatter,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/c-family-formatter/c-family-formatter.macpadproext")!
    )

    static let formatters: [any CodeFormatter] = [
        CFamilyCodeFormatter()
    ]
}

public struct CFamilyCodeFormatter: CodeFormatter {
    public let id = "c-family"
    public let name = "C / PHP / C++"
    public let supportedLanguageIDs: Set<String> = [
        "c",
        "cpp",
        "c-header",
        "cpp-header",
        "css",
        "java",
        "javascript",
        "objective-cpp",
        "php",
        "typescript",
        "tsx"
    ]

    public init() {}

    public func format(_ text: String) throws -> String {
        var lines: [String] = []
        var currentLine = ""
        var indentLevel = 0
        var stringDelimiter: Character?
        var isEscaped = false

        func appendLine(_ line: String, indent: Int) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            lines.append(String(repeating: " ", count: max(0, indent) * 2) + trimmed)
        }

        for character in text {
            if let delimiter = stringDelimiter {
                currentLine.append(character)
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == delimiter {
                    stringDelimiter = nil
                }
                continue
            }

            switch character {
            case "\"", "'":
                currentLine.append(character)
                stringDelimiter = character
            case "{":
                currentLine = currentLine.trimmingCharacters(in: .whitespaces)
                if !currentLine.isEmpty, !currentLine.hasSuffix(" ") {
                    currentLine.append(" ")
                }
                currentLine.append("{")
                appendLine(currentLine, indent: indentLevel)
                currentLine.removeAll(keepingCapacity: true)
                indentLevel += 1
            case "}":
                appendLine(currentLine, indent: indentLevel)
                currentLine.removeAll(keepingCapacity: true)
                indentLevel = max(0, indentLevel - 1)
                appendLine("}", indent: indentLevel)
            case ";":
                currentLine = currentLine.trimmingCharacters(in: .whitespaces)
                currentLine.append(";")
                appendLine(currentLine, indent: indentLevel)
                currentLine.removeAll(keepingCapacity: true)
            case "\n", "\r":
                appendLine(currentLine, indent: indentLevel)
                currentLine.removeAll(keepingCapacity: true)
            case " ", "\t":
                if !currentLine.isEmpty, !currentLine.hasSuffix(" ") {
                    currentLine.append(" ")
                }
            default:
                currentLine.append(character)
            }
        }

        appendLine(currentLine, indent: indentLevel)
        return lines.joined(separator: "\n")
    }
}
