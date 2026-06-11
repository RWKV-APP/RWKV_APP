# lib/widgets/chat AGENTS.md

## Scope

- Applies to `lib/widgets/chat/**/*.dart`
- Chat widgets own rendering, layout, controls, and provider binding
- Business decisions should live in `lib/store`

## UI Rules

- Keep build methods focused on layout and provider binding
- Use `ref.watch` for state that should refresh the UI
- Use store methods for click handlers with complex branching or async work
- Do not use `Divider`, `ListTile`, or `FutureBuilder`
- Use `Container(height: 0.5, color: ...)` for separators

## Shared Surfaces

- Use `InputBarWidthLimit` when a floating chat surface should align with the input bar
- Keep batch card layout changes local to `batch_message_content.dart`
- Keep ask-question panel state changes in `P.askQuestion` or `P.multiQuestion`
- Preserve raw assistant content unless the product requirement says to transform it

## Verification

```bash
dart analyze lib/widgets/chat/<file>.dart
```

```bash
flutter test test/get_batch_info_test.dart test/message_thinking_preview_test.dart
```
