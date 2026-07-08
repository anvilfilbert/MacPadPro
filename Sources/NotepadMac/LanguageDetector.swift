import Foundation

enum LanguageDetector {
    static func language(for fileURL: URL?, text: String) -> String {
        if let fileURL {
            let ext = fileURL.pathExtension.lowercased()
            if let language = languageByExtension[ext] {
                return language
            }
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#!/") {
            return languageFromShebang(trimmed) ?? "Script"
        }
        if looksLikeJSON(trimmed) {
            return "JSON"
        }
        if trimmed.hasPrefix("<!doctype html") || trimmed.hasPrefix("<html") {
            return "HTML"
        }
        return "Plain Text"
    }

    private static func languageFromShebang(_ text: String) -> String? {
        guard let firstLine = text.split(separator: "\n", maxSplits: 1).first else { return nil }
        let line = firstLine.lowercased()
        if line.contains("python") { return "Python" }
        if line.contains("node") || line.contains("javascript") { return "JavaScript" }
        if line.contains("ruby") { return "Ruby" }
        if line.contains("bash") || line.contains("sh") || line.contains("zsh") { return "Shell" }
        return nil
    }

    private static func looksLikeJSON(_ text: String) -> Bool {
        guard let first = text.first, let last = text.last else { return false }
        return (first == "{" && last == "}") || (first == "[" && last == "]")
    }

    private static let languageByExtension: [String: String] = [
        "bash": "Shell",
        "c": "C",
        "cc": "C++",
        "cpp": "C++",
        "css": "CSS",
        "go": "Go",
        "h": "C/C++ Header",
        "hpp": "C++ Header",
        "html": "HTML",
        "java": "Java",
        "js": "JavaScript",
        "json": "JSON",
        "kt": "Kotlin",
        "md": "Markdown",
        "mjs": "JavaScript",
        "mm": "Objective-C++",
        "php": "PHP",
        "plist": "Property List",
        "py": "Python",
        "rb": "Ruby",
        "rs": "Rust",
        "sh": "Shell",
        "swift": "Swift",
        "ts": "TypeScript",
        "tsx": "TSX",
        "txt": "Plain Text",
        "xml": "XML",
        "yaml": "YAML",
        "yml": "YAML",
        "zsh": "Shell"
    ]
}
