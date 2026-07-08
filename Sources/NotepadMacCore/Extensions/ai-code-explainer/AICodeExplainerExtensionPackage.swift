import Foundation

enum AICodeExplainerExtensionPackage {
    static let id = "ai-code-explainer"

    static let catalogEntry = DownloadableExtension(
        id: id,
        title: "AI Code Explainer",
        description: "Explain selected code through a configured agent using filename and language context.",
        version: "1.0.0",
        kind: .aiTextTask,
        downloadURL: URL(string: "https://raw.githubusercontent.com/anvilfilbert/MacPadPro/main/RepositoryExtensions/ai-code-explainer/ai-code-explainer.macpadproext")!
    )

    static let textTasks: [AITextTask] = [.codeExplainer]
}
