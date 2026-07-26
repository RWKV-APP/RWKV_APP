<a id="SPEC-RWKV-WORKSPACE-OWNERSHIP"></a>

# Workspace Map

This document maps the repositories that usually move together with RWKV App

Use it to choose the right edit location before changing code

## Repositories

| Path | Role | Edit Here When |
| --- | --- | --- |
| `./` | Flutter app frontend | UI, routing, Riverpod state, model selection, local API page, release scripts |
| `../rwkv_mobile_flutter` | Flutter adapter and FFI bridge | Dart API surface to the native engine, platform bridge behavior, generated/native message contract |
| `../rwkv_mobile` | C++ inference engine | Runtime kernels, model execution, tokenizer or engine internals |
| `../rwkv_harmony` | HarmonyOS ArkUI host | DevEco build, signing, HDC device flow, Node-API bridge, and Kirin NNRT device evidence |
| `../app_website` | Download page and HTTP service | Public download page, backend admin or public web service behavior |

## Symptom To Entry

| Symptom | First Place To Inspect | Notes |
| --- | --- | --- |
| Flutter page layout issue | `lib/page`, `lib/widgets`, `lib/store/ui.dart` | Check real widget tree and provider reads before changing store logic |
| Chat send, pause, resume, batch behavior | `lib/store/chat.dart`, `lib/store/msg.dart`, `lib/store/rwkv_generation.dart` | Preserve raw model output unless product behavior explicitly requires transformation |
| Model load or release behavior | `lib/store/rwkv_model.dart`, `lib/store/rwkv.dart`, `../rwkv_mobile_flutter` | Frontend owns selection and state, adapter owns bridge contract |
| Local model file scan | `lib/store/pth.dart`, `lib/func/local_model_discovery.dart`, `lib/model/file_info.dart` | Keep isolate result types explicit |
| Remote model list or download issue | `remote/latest.json`, `lib/store/remote.dart`, `rwkv_downloader` | Check config and local path resolution separately |
| VL model exists in `latest.json` but is not displayed | `docs/architecture/vl-model-update-guide.md` | VL display also depends on `WorldType.socPairs` and `FileInfo.worldType` |
| HarmonyOS build, signing, or Kirin device issue | `../rwkv_harmony`, `../rwkv_mobile/src/backends/nnrt` | Keep host integration and engine implementation separate; verify final driver partitions from HiLog |
| OpenAI-compatible local API | `lib/store/api_server.dart`, `assets/api_server/dashboard.html` | Keep HTTP behavior testable without the app UI where possible |
| iOS or macOS build issue | `pubspec.yaml`, `ios/Podfile`, `macos/Podfile`, Xcode project files | This repo currently disables Flutter project-level SPM |
| Release or upload issue | `fastlane/Fastfile`, `fastlane/actions`, `.github/workflows`, `scripts` | Resume from the smallest successful artifact boundary |

## Coding Agent Flow

1. Run the Specification flow first when the request contains product or process truth
2. Identify whether the issue is frontend, adapter, engine, or website
3. Inspect the narrowest call chain before editing
4. Prefer repo-local checks over global machine assumptions
5. Run `dart run tools/bin/agent_check.dart --rules-only` for quick structural feedback
6. Run the focused test file for the touched feature
7. Run full `dart run tools/bin/agent_check.dart` before handing over broad changes

## Boundaries

Do not move FFI contract behavior into UI widgets

Do not hide model/runtime output in export code unless the product requirement says so

Do not add new generated files by hand under `lib/gen` or `lib/gen/intl`

Keep `albatross` and `flutter_roleplay` changes minimal unless the task targets them directly
