# lib/store AGENTS.md

## Scope

- Applies to `lib/store/**/*.dart`
- Store files own state, side effects, business flow, persistence calls, and runtime bridge calls
- UI files should bind to store methods rather than contain long business flows

## Import And Part Rules

- Only `lib/store/p.dart` may contain imports for store code
- Every other store file must use `part of 'p.dart';`
- Do not add relative imports
- Do not use `show` in imports or exports

## State Rules

- Use existing `qs`, `qp`, `qsf`, and `qsff` helpers
- Use `.q` for logic, callbacks, one-time reads, and internal store writes
- Keep provider reads in UI reactive with `ref.watch`
- Avoid introducing new global mutable state outside the matching store class

## Edit Guidance

- Put chat runtime behavior in `chat.dart`, message storage in `msg.dart`, and conversation DB sync in `conversation.dart`
- Put model load and release behavior in `rwkv_model.dart`
- Put runtime bridge message handling in `rwkv.dart` or `rwkv_generation.dart`
- Put local and remote model file discovery in `remote.dart`, `pth.dart`, or `lib/func/local_model_discovery.dart`
- Add tests for pure helpers before expanding a store method further

## Verification

```bash
dart analyze lib/store/<file>.dart
```

```bash
flutter test test/chat_history_test.dart test/get_batch_info_test.dart test/msg_node_test.dart
```
