# Contributing: Theme Quick Start

This guide is for external contributors who want to open a PR mainly to customize the app color theme.

## 1. Add your theme in `lib/model/app_theme.dart`

1. Copy an existing theme (usually `.dim` or `.lightsOut`) and rename it, for example `.myTheme`.
2. Fill all required color fields (`primary`, `themePrimary`, `qb*`, `g*`, input/message colors, etc.).
3. Set `isLight` correctly (`true` for light themes, `false` for dark themes).
4. Add the new case in `displayName`.
5. Update `fromString` and `toString` for backward-compatible persistence values.

## 2. Expose the theme in `lib/widgets/theme_selector.dart`

1. Add a new `FormItem` in the `items` list.
2. Add a handler similar to `_onDimPressed` / `_onLightsOutPressed`:
   - update `P.preference.preferredDarkCustomTheme.q`
   - persist `halo_state.preferredDarkCustomTheme`
3. Reuse selected-state UI logic: `preferredDarkCustomTheme == .yourTheme`.

Note: Current structure is "one light theme + multiple dark themes". If you add extra light themes, also update sync logic in `lib/store/app.dart`.

## 3. What `Args.debuggingThemes` does

- Launch arg: `--dart-define=debuggingThemes=true`
- Behavior in debug mode: app toggles every second between `.light` and current dark preference (`preferredDarkCustomTheme`).
- Purpose: quickly verify contrast/readability and theme coverage on the same screen.

## 4. Launch desktop + mobile UI together in `.vscode/launch.json`

1. Keep per-platform launch configs (for example macOS, Android, iOS).
2. Group them in a `compounds` entry (for example `all (Halo)`).
3. Run the compound config to start multi-platform UI side by side.

Optional: add `--dart-define=debuggingThemes=true` in the related launch configs for auto light/dark preview.

