# Pro Themes Extension

This directory owns the Pro Themes extension.

Theme color definitions live in:

```text
RepositoryExtensions/pro-themes/themes.json
```

Each theme is a JSON object with:

```text
id
name
textColor
backgroundColor
insertionPointColor
statusTextColor
statusBackgroundColor
```

Each color uses normalized RGBA components:

```json
{ "red": 0.86, "green": 0.88, "blue": 0.90, "alpha": 1.0 }
```

Current themes:

```text
Night
Paper
Terminal
Ocean
Forest
Sunset
Lavender
High Contrast
```

The downloadable package manifest lives in:

```text
RepositoryExtensions/pro-themes/pro-themes.macpadproext
```

That manifest declares `themes.json` as a package resource with a SHA-256 checksum. Extension Manager downloads and verifies the JSON file before loading Pro Themes.

The GitHub catalog entry lives in:

```text
RepositoryExtensions/catalog.json
```

Keep `themes.json`, the manifest checksum, catalog metadata, and docs synchronized when adding or changing themes.
