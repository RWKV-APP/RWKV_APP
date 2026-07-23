# Third Party Notices

## Halo-derived internal code

This project includes small internal implementations based on the following MIT-licensed packages:

- `halo` 1.0.0
- `halo_alert` 1.0.0
- `halo_state` 1.0.0

Original copyright: Copyright (c) 2024-2025 WangCe

The implementations are adapted for this app in `lib/store/state.dart`, `lib/widgets/alert.dart`, and `lib/func/shortcuts.dart`

## lua_dardo_co

The Agent evaluation sandbox uses `lua_dardo_co` 0.0.10

- Project: <https://github.com/shanlihou/LuaDardo.git>
- License: Apache License 2.0
- Use in this project: restricted Lua evaluation inside a killable Dart isolate

The dependency declares `sprintf: ^6.0.0`. The app currently resolves `sprintf` 7.0.0 through its existing dependency override, and the Agent sandbox test suite covers the Lua functionality used by the evaluation
