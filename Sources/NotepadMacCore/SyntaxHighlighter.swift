import Foundation

public enum SyntaxHighlightKind: String, Sendable, Equatable {
    case keyword
    case stringLiteral
    case comment
    case numberLiteral
    case variable
    case directive
}

public struct SyntaxHighlightToken: Sendable, Equatable {
    public let kind: SyntaxHighlightKind
    public let range: NSRange

    public init(kind: SyntaxHighlightKind, range: NSRange) {
        self.kind = kind
        self.range = range
    }
}

public struct SyntaxHighlighter: Sendable {
    public init() {}

    public func tokens(in text: String, languageID: String) -> [SyntaxHighlightToken] {
        guard supportedLanguageIDs.contains(languageID), !text.isEmpty else { return [] }

        var tokens: [SyntaxHighlightToken] = []
        var index = text.startIndex

        while index < text.endIndex {
            if languageID == "php", text[index...].hasPrefix("<?php") {
                let end = text.index(index, offsetBy: "<?php".count, limitedBy: text.endIndex) ?? text.endIndex
                append(.directive, from: index, to: end, in: text, to: &tokens)
                index = end
                continue
            }

            if text[index...].hasPrefix("//") {
                let end = scanLineEnd(from: index, in: text)
                append(.comment, from: index, to: end, in: text, to: &tokens)
                index = end
                continue
            }

            if text[index...].hasPrefix("/*") {
                let end = scanBlockCommentEnd(from: index, in: text)
                append(.comment, from: index, to: end, in: text, to: &tokens)
                index = end
                continue
            }

            if languageID == "php", text[index] == "#" {
                let end = scanLineEnd(from: index, in: text)
                append(.comment, from: index, to: end, in: text, to: &tokens)
                index = end
                continue
            }

            if text[index] == "\"" || text[index] == "'" {
                let end = scanStringEnd(from: index, quote: text[index], in: text)
                append(.stringLiteral, from: index, to: end, in: text, to: &tokens)
                index = end
                continue
            }

            if languageID == "php",
               text[index] == "$",
               let next = text.index(index, offsetBy: 1, limitedBy: text.endIndex),
               next < text.endIndex,
               isIdentifierStart(text[next]) {
                let end = scanIdentifierEnd(from: next, in: text)
                append(.variable, from: index, to: end, in: text, to: &tokens)
                index = end
                continue
            }

            if isDigit(text[index]) {
                let end = scanNumberEnd(from: index, in: text)
                append(.numberLiteral, from: index, to: end, in: text, to: &tokens)
                index = end
                continue
            }

            if isIdentifierStart(text[index]) {
                let end = scanIdentifierEnd(from: index, in: text)
                let word = String(text[index..<end])
                if keywords.contains(word) {
                    append(.keyword, from: index, to: end, in: text, to: &tokens)
                }
                index = end
                continue
            }

            index = text.index(after: index)
        }

        return tokens
    }

    private let supportedLanguageIDs: Set<String> = [
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

    private let keywords: Set<String> = [
        "array",
        "bool",
        "break",
        "case",
        "catch",
        "class",
        "const",
        "continue",
        "default",
        "do",
        "double",
        "echo",
        "else",
        "extends",
        "false",
        "float",
        "for",
        "foreach",
        "function",
        "if",
        "implements",
        "include",
        "int",
        "let",
        "namespace",
        "new",
        "null",
        "private",
        "protected",
        "public",
        "require",
        "return",
        "static",
        "string",
        "struct",
        "switch",
        "throw",
        "true",
        "try",
        "type",
        "var",
        "void",
        "while"
    ]

    private func append(
        _ kind: SyntaxHighlightKind,
        from start: String.Index,
        to end: String.Index,
        in text: String,
        to tokens: inout [SyntaxHighlightToken]
    ) {
        tokens.append(SyntaxHighlightToken(kind: kind, range: NSRange(start..<end, in: text)))
    }

    private func scanLineEnd(from start: String.Index, in text: String) -> String.Index {
        var index = start
        while index < text.endIndex, text[index] != "\n" {
            index = text.index(after: index)
        }
        return index
    }

    private func scanBlockCommentEnd(from start: String.Index, in text: String) -> String.Index {
        var index = text.index(start, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
        while index < text.endIndex {
            if text[index...].hasPrefix("*/") {
                return text.index(index, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
            }
            index = text.index(after: index)
        }
        return text.endIndex
    }

    private func scanStringEnd(from start: String.Index, quote: Character, in text: String) -> String.Index {
        var escaped = false
        var index = text.index(after: start)

        while index < text.endIndex {
            let character = text[index]
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == quote {
                return text.index(after: index)
            }
            index = text.index(after: index)
        }

        return text.endIndex
    }

    private func scanIdentifierEnd(from start: String.Index, in text: String) -> String.Index {
        var index = start
        while index < text.endIndex, isIdentifierPart(text[index]) {
            index = text.index(after: index)
        }
        return index
    }

    private func scanNumberEnd(from start: String.Index, in text: String) -> String.Index {
        var index = start
        while index < text.endIndex, isNumberPart(text[index]) {
            index = text.index(after: index)
        }
        return index
    }

    private func isIdentifierStart(_ character: Character) -> Bool {
        isASCIILetter(character) || character == "_"
    }

    private func isIdentifierPart(_ character: Character) -> Bool {
        isIdentifierStart(character) || isDigit(character)
    }

    private func isNumberPart(_ character: Character) -> Bool {
        isDigit(character) || character == "." || character == "_"
    }

    private func isASCIILetter(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 else { return false }
        return (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
    }

    private func isDigit(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 else { return false }
        return (48...57).contains(Int(scalar.value))
    }
}
