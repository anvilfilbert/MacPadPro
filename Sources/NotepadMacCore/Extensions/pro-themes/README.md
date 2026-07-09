# Pro Themes Extension

This directory owns the Pro Themes extension.

Theme color definitions live in:

```text
ProThemesExtensionPackage.swift
```

Each theme is an `EditorTheme` value with:

```text
id
name
textColor
backgroundColor
insertionPointColor
statusTextColor
statusBackgroundColor
```

The downloadable package manifest lives in:

```text
RepositoryExtensions/pro-themes/pro-themes.macpadproext
```

The GitHub catalog entry lives in:

```text
RepositoryExtensions/catalog.json
```

Keep theme source, catalog metadata, package metadata, and tests synchronized when adding or changing themes.
