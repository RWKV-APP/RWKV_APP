# local_web_search

Internal Flutter package for RWKV App desktop web-search research.

This package provides a browser panel scaffold that can load Google search result pages, run extraction JavaScript inside the embedded browser, and return structured search result items for later RWKV Chat integration.

## Current scope

- macOS and Windows use a `flutter_inappwebview` adapter
- Linux uses an unsupported placeholder adapter until a CEF implementation is selected
- The `example` app is the primary debug surface
- The package is private and is not intended for pub.dev publishing

## Debug app

```bash
cd packages/local_web_search/example
flutter run -d macos
```

Use the toolbar to enter a query or URL, load the Google search page, and extract result items from the page DOM.
