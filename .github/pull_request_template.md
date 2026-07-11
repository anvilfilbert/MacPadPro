## Summary

- 

## Testing

- [ ] `swift test --quiet` when a sanitized public `Tests/` target exists
- [ ] `./scripts/verify-public-repo.sh`
- [ ] `./scripts/verify-release.sh`
- [ ] `./scripts/build-app.sh`
- [ ] `./scripts/install-app.sh` when app bundle behavior changed
- [ ] `./scripts/package-release.sh` when release packaging changed

## Extension Checklist

- [ ] Source directory added under `Sources/NotepadMacCore/Extensions/<extension-id>/`
- [ ] Package manifest added under `RepositoryExtensions/<extension-id>/`
- [ ] Package-owned resource files declare SHA-256 checksums
- [ ] `RepositoryExtensions/catalog.json` updated
- [ ] `ExtensionCatalog.default` updated
- [ ] Extension is inactive by default
- [ ] Extension can be loaded, deactivated, reactivated, and deleted independently
- [ ] Local/private data handling documented
