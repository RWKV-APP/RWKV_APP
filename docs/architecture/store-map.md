# Store Map

This document is a working map for `lib/store`

It helps developers and coding agents find the right `P.*` entry before editing code

## Store Shape

`lib/store/p.dart` is the only import hub in `lib/store`

All other store files use `part of 'p.dart';`

The public state surface is exposed through the static `P` class

| Entry | Primary Responsibility | Common Callers |
| --- | --- | --- |
| `P.app` | App shell state, theme, platform flags, app directories, update info, haptics | `main.dart`, pages, widgets |
| `P.preference` | Persistent user preferences backed by `SharedPreferences` | app boot, settings, model paths |
| `P.msg` | In-memory message pool, ordered ids, message tree, message UI state | chat runtime, conversation, message widgets |
| `P.chat` | Chat orchestration, sending, receiving, batch UI state, pause and resume, response style | chat page, input widgets, RWKV stream events |
| `P.conversation` | Conversation list, current conversation id, DB sync, export helpers | conversation page, chat runtime |
| `P.rwkvBridge` | Isolate and bridge messages to `rwkv_mobile_flutter` | model load, generation, runtime callbacks |
| `P.rwkvModel` | Model loading and release by demo type, active model mapping | model selector, chat, see, talk, benchmark |
| `P.rwkvGeneration` | Generation status, stop, token counting, speed metrics | chat, benchmark, API server |
| `P.rwkvParams` | Sampler params, thinking mode, max length, batch params | chat controls, model loading |
| `P.remote` | Remote model config, local file discovery, model paths, downloads | model selector, weight manager |
| `P.apiServer` | Local OpenAI-compatible HTTP server and translation cache | API server page, external local tools |
| `P.translator` | Local translation task state and browser-tab queue metadata | translator page, API server |
| `P.askQuestion` | Generated question panel state and question generation flow | ask-question panel |
| `P.multiQuestion` | Multi-question batch send state and helpers | multi-question panel, ask-question panel |
| `P.ui` | Shared UI measurements, scroll controllers, transient panel state | pages and widgets |
| `P.talk` | TTS speaker, source audio, instruction state | talk page and TTS widgets |
| `P.see` | Vision input, waiting message, image/audio handoff state | see page and input bar |
| `P.pth` | Local folder scanning for model files | weight manager |
| `P.telemetry` | Opt-in telemetry fields and benchmark device info | benchmark, app boot |

## Edit Routing

Use `P.chat` for chat behavior and generation lifecycle

Use `P.msg` for message storage shape, selection state, and tree operations

Use `P.conversation` for DB-backed conversation list behavior and exports

Use `P.rwkvModel`, `P.rwkvGeneration`, `P.rwkvParams`, or `P.rwkvBridge` for inference runtime behavior

Use `P.remote` for remote JSON model config, local model path resolution, and downloads

Use `P.apiServer` for local HTTP routes and OpenAI-compatible behavior

Use `P.ui` only for shared layout state, not business decisions

## Initialization Notes

`P.init()` initializes `preference` first, then `app`, then starts most other store init tasks concurrently

Any new init dependency should be documented near `P.init()` before adding another implicit ordering assumption

Store init work should be fast, cancellable where possible, and safe to run without a ready UI context

## Verification Pointers

For store-only changes, start with:

```bash
dart analyze lib/store/<file>.dart
```

For chat/message changes, also consider:

```bash
flutter test test/chat_history_test.dart test/get_batch_info_test.dart test/msg_node_test.dart
```

For DB or export changes, also consider:

```bash
flutter test test/data_export_test.dart test/drift/conversations/migration_test.dart
```
