# Windows WebView source

Source: https://pub.dev/api/archives/flutter_inappwebview_windows-0.6.0.tar.gz

Version: 0.6.0. Archive SHA-256: `8b4d3a46078a2cdc636c4a3d10d10f2a16882f6be607962dbfff8874d1642055`. The included LICENSE is Apache-2.0. Only the package metadata, library and Windows sources are retained.

Local fixes:

- Keep the four shared WinRT resource holders alive until process termination to avoid COM teardown during DLL unloading (upstream issue [2733](https://github.com/pichillilorenzo/flutter_inappwebview/issues/2733)). Individual WebViews still dispose normally.
- Ignore asynchronous widget callbacks after disposal, including native view creation, size, position, cursor and delayed focus updates.

Regression check from the application root: `flutter test test/windows_webview_lifecycle_test.dart`. Replace this local package when a compatible upstream stable release includes both lifecycle fixes.
