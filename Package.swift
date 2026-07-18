// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacPadPro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacPadPro", targets: ["NotepadMac"]),
        .executable(name: "MacPadProScriptRunner", targets: ["MacPadProScriptRunner"])
    ],
    targets: [
        .target(
            name: "NotepadMacCore",
            path: "Sources/NotepadMacCore",
            exclude: ["Extensions/pro-themes/README.md"]
        ),
        .executableTarget(
            name: "NotepadMac",
            dependencies: ["NotepadMacCore"],
            path: "Sources/NotepadMac"
        ),
        .executableTarget(
            name: "MacPadProRepoCheck",
            dependencies: ["NotepadMacCore"],
            path: "Sources/MacPadProRepoCheck"
        ),
        .executableTarget(
            name: "MacPadProScriptRunner",
            path: "Sources/MacPadProScriptRunner"
        )
    ]
)
