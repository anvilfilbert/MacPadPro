# Security Best Practices Report

Review date: 2026-07-18

Scope: MacPad Pro Swift/AppKit desktop app, downloadable extension package flow, AI agent integration, local persistence, and release/public-repository gates.

## Executive Summary

No critical issue was found in the reviewed code. The app already has useful security controls: no arbitrary native bundles are loaded, AI tokens are stored in Keychain, AI text tasks require user action, extension resource filenames reject path traversal, package resources use SHA-256 checksums, and the public repository has a hygiene gate.

The main security risk is the extension supply chain. MacPad Pro downloads its catalog and package manifests from the GitHub `main` branch, then trusts catalog metadata that comes from the same remote source as the package URL and resource checksums. This means checksums catch accidental transfer corruption and local tampering, but they do not protect users if the repository, branch, or catalog update path is compromised. Script command packages also allow missing script checksums, and JavaScript transforms run in-process without timeout or resource limits.

Skill limitation: the selected `security-best-practices` skill has reference guidance for Python, JavaScript/TypeScript, and Go, but no Swift/AppKit desktop reference. This report uses the skill's general security workflow plus repository-specific inspection.

## Critical Findings

No critical findings.

## High Findings

### H-1. Extension update channel has no independent package or catalog signature

Impact: a compromised repository, branch, or catalog update path could publish a malicious extension manifest or script that matches its own catalog metadata and is accepted by the app.

Evidence:

- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:3` defines the catalog URL on raw GitHub `main`.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:12` downloads that catalog directly with `Data(contentsOf:)`.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:129` downloads package manifests from the catalog-provided URL.
- `Sources/NotepadMacCore/ExtensionPackageValidation.swift:51` validates that the downloaded manifest matches the catalog entry, but the catalog and manifest are both controlled by the same remote source.
- `Sources/NotepadMacCore/RepositoryExtensionValidator.swift:133` enforces the expected GitHub raw URL layout for repository packages, but does not add cryptographic publisher identity.

Recommended fix:

Add a trust anchor outside the mutable catalog. Good options are signed catalog files, signed package manifests, or releases pinned to immutable tags with a checked, signed catalog digest. Keep SHA-256 resource checks, but treat them as integrity checks, not publisher authenticity.

### H-2. Script command checksums are optional for downloaded JavaScript plugins

Impact: a script package can be accepted without an expected `sourceSHA256`, so the downloaded script content is not cryptographically tied to the reviewed manifest.

Evidence:

- `Sources/NotepadMacCore/ExtensionModels.swift:34` defines script commands.
- `Sources/NotepadMacCore/ExtensionModels.swift:39` makes `sourceSHA256` optional.
- `Sources/NotepadMacCore/ExtensionPackageValidation.swift:91` returns without validation when a script checksum is missing.
- `Sources/NotepadMacCore/ExtensionPackageValidation.swift:96` also returns without validation when the checksum is missing during download validation.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:137` downloads script files from `sourceURL`, then `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:139` passes the data to the validator.

Recommended fix:

Make `sourceSHA256` required for every script command that has a `sourceURL`. Reject script packages without a checksum during manifest validation and repository validation.

## Medium Findings

### M-1. JavaScript plugin transforms run in-process without timeout or resource limits

Risk: a faulty or hostile script can freeze the editor process with an infinite loop, excessive memory use, or expensive computation.

Evidence:

- `Sources/NotepadMacCore/ScriptTextCommand.swift:38` loads a script and transforms selected text.
- `Sources/NotepadMacCore/ScriptTextCommand.swift:43` creates a `JSContext` inside the app process.
- `Sources/NotepadMacCore/ScriptTextCommand.swift:51` evaluates the plugin script.
- `Sources/NotepadMacCore/ScriptTextCommand.swift:61` calls `transform` directly and waits for completion.

Recommended fix:

Run script commands with a timeout and bounded input/output size. Stronger option: execute plugin scripts in a helper process that can be killed and has no access to app internals beyond the selected text payload.

### M-2. Extension catalog, package, script, and resource downloads are synchronous and unbounded

Risk: a slow or oversized response can freeze the Extension Manager, consume excessive memory, or write unexpectedly large files into Application Support.

Evidence:

- `Sources/NotepadMac/ExtensionManagerWindowController.swift:117` refreshes the catalog from a button action.
- `Sources/NotepadMac/ExtensionManagerWindowController.swift:131` downloads the selected extension from a button action.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:13` loads catalog data with `Data(contentsOf:)`.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:130` loads package data with `Data(contentsOf:)`.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:139` loads script data with `Data(contentsOf:)`.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:146` loads resource data with `Data(contentsOf:)`.

Recommended fix:

Move downloads to `URLSession` with explicit timeout, expected MIME/type checks where practical, maximum byte limits per artifact type, and progress/cancel behavior in Extension Manager.

### M-3. Clipboard, snippets, session text, and backup snapshots are stored as plaintext UserDefaults data

Risk: local plaintext storage can retain sensitive document contents and clipboard contents longer than users expect.

Evidence:

- `Sources/NotepadMac/AppDelegate.swift:766` loads backup snapshots from `UserDefaults`.
- `Sources/NotepadMac/AppDelegate.swift:774` saves backup snapshots to `UserDefaults`.
- `Sources/NotepadMac/AppDelegate.swift:804` saves editor session state, including text from `Sources/NotepadMac/EditorWindowController.swift:75`.
- `Sources/NotepadMac/AppDelegate.swift:919` loads clipboard slots from `UserDefaults`.
- `Sources/NotepadMac/AppDelegate.swift:927` saves clipboard slots to `UserDefaults`.
- `Sources/NotepadMac/AppDelegate.swift:933` loads clipboard snippets from `UserDefaults`.
- `Sources/NotepadMac/AppDelegate.swift:941` saves clipboard snippets to `UserDefaults`.
- `Sources/NotepadMacCore/ClipboardSnippetStore.swift:24` captures recent clipboard content.
- `Sources/NotepadMacCore/ClipboardSlotStore.swift:33` stores clipboard slot content.

Recommended fix:

Keep the local-only behavior, but add clear user controls and documentation for retained text. Consider moving sensitive extension data to files under Application Support with explicit deletion, optional encryption, and user-visible retention limits.

### M-4. AI Smart Search sends snippets from all open documents to the configured endpoint

Risk: users may expect selected-text-only AI behavior, but Smart Search sends snippets from every open document to the configured local or remote AI endpoint.

Evidence:

- `Sources/NotepadMac/EditorWindowController.swift:98` exposes the first 2,000 characters of each open document as an AI search snippet.
- `Sources/NotepadMac/AppDelegate.swift:1057` builds Smart Search requests.
- `Sources/NotepadMacCore/AI/AIAgent.swift:251` builds a prompt that includes open document snippets.
- `Sources/NotepadMacCore/AI/AIAgent.swift:284` sends the prompt to the configured endpoint.

Recommended fix:

Add a clear one-time Smart Search disclosure or per-request confirmation for remote endpoints. Consider showing how many documents/snippets will be sent, and warn when the endpoint host is not localhost.

## Low Findings

### L-1. Keychain token storage ignores Security framework status codes and lacks an explicit accessibility class

Risk: token persistence can fail silently, and the Keychain item uses default accessibility behavior instead of an intentional app policy.

Evidence:

- `Sources/NotepadMac/AppDelegate.swift:1077` reads the AI agent token from Keychain.
- `Sources/NotepadMac/AppDelegate.swift:1093` saves the token.
- `Sources/NotepadMac/AppDelegate.swift:1099` deletes any existing token without checking the returned status.
- `Sources/NotepadMac/AppDelegate.swift:1104` adds the token without checking the returned status.

Recommended fix:

Check `SecItemDelete` and `SecItemAdd` results. Set an explicit accessibility class such as `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` or a stricter value if the expected UX allows it.

### L-2. Release packaging uses ad-hoc signing only

Risk: local builds are signed enough for local execution, but public users do not get Developer ID identity or notarization assurance from the release artifact.

Evidence:

- `scripts/build-app.sh:34` signs the app with `codesign --sign -`.
- `scripts/verify-release.sh:21` verifies the ad-hoc signature.
- `scripts/package-release.sh:20` writes a SHA-256 file for the release zip.

Recommended fix:

Keep ad-hoc signing for local development builds. For public releases, add an optional Developer ID signing and notarization path, then document which artifacts are local-only and which are public release artifacts.

## Positive Controls Observed

- `SECURITY.md:15` states AI extensions must not ship built-in credentials.
- `SECURITY.md:19` forbids automatic document uploads.
- `SECURITY.md:21` requires clipboard, snippets, backups, and version history to stay local.
- `Sources/NotepadMac/AppDelegate.swift:953` stores AI endpoint/model in preferences but reads the token separately from Keychain.
- `Sources/NotepadMac/AppDelegate.swift:1077` reads the AI token from Keychain.
- `Sources/NotepadMacCore/ExtensionPackageValidation.swift:144` rejects extension package file paths containing separators, dot paths, hidden files, or `..`.
- `Sources/NotepadMacCore/ExtensionPackageValidation.swift:75` validates resource SHA-256.
- `Sources/NotepadMacCore/ExtensionCatalogTransport.swift:117` validates installed package resources before loading package themes.
- `Sources/NotepadMacCore/RepositoryExtensionValidator.swift:48` validates repository package/catalog consistency.
- `scripts/verify-public-repo.sh:12` blocks tracked public test files, build artifacts, user state, and secret-like values.
- `scripts/verify-public-repo.sh:29` runs the repository extension checker.

## Recommended Fix Order

1. Add signed catalog/package provenance for extension downloads.
2. Require script checksums for every downloaded script command.
3. Add timeout, size, and execution isolation controls for script commands.
4. Replace synchronous unbounded extension downloads with cancellable bounded `URLSession` downloads.
5. Add user-facing retention and clear controls for local plaintext clipboard, snippet, backup, and session data.
6. Add Smart Search disclosure for remote endpoints.
7. Harden Keychain status handling and accessibility attributes.
8. Add Developer ID signing/notarization path for public release artifacts.
