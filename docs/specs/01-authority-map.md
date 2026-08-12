# Specification Authority Map

Process version: v1.8
Effective date: 2026-08-10
Last reviewed: 2026-08-10

This map assigns one canonical owner and one lifecycle to each topic. Stable `SPEC-*` IDs remain valid when a heading is renamed. Other files in the row are required drift or delivery surfaces and cannot silently override the owner.

## SPEC-SYNC-AUTHORITY-MAP — Topic Owners

| Topic | Assertion IDs | Lifecycle | Canonical owner | Required drift surfaces |
| --- | --- | --- | --- | --- |
| Specification classification, private intake and Root request-record boundaries, authority, historical state, conflict, acceptance, and anti-overfitting mechanics | `SPEC-SYNC-CLASSIFICATION`, `SPEC-SYNC-PRIVATE-INTAKE-BOUNDARY`, `SPEC-SYNC-ROOT-INTAKE-BOUNDARY`, `SPEC-SYNC-AUTHORITY`, `SPEC-SYNC-STATE-MODEL`, `SPEC-SYNC-CONFLICTS`, `SPEC-SYNC-ACCEPTANCE`, `SPEC-SYNC-ACCEPTANCE-GUARDRAILS` | active | `docs/spec-process/rules.md` | `SPEC-LOOP.md`, `docs/specification.md`, `docs/spec-process/templates.md`, `docs/spec-process/changelog.md`, `docs/spec-process/eval-cases.md`, `docs/spec-process/acceptance-records/README.md`, `.agents/skills/spec-sync/SKILL.md`, `AGENTS.md`, `tools/lib/specification/specification_checker.dart`, `tools/bin/check_specification.dart`, `tools/bin/agent_check.dart`, `tools/README.md`, `.github/workflows/unit-tests.yml` |
| Specification topic ownership and stable assertion registry | `SPEC-SYNC-AUTHORITY-MAP` | active | `docs/specs/01-authority-map.md` | `docs/specs/00-inventory.md`, `docs/specs/02-repository-map.md` |
| Specification-aware execution plans | `SPEC-SYNC-EXECUTION-PLANS` | active | `docs/plans/PLANS.md` | `docs/specification.md`, `docs/spec-process/acceptance-records/README.md` |
| Product users, purpose, and design principles, excluding narrower inference and data-flow semantics | `SPEC-RWKV-PRODUCT-USERS`, `SPEC-RWKV-PRODUCT-PURPOSE`, `SPEC-RWKV-DESIGN-PRINCIPLES` | active | `PRODUCT.md` | `docs/specification.md`, `README.md`, `docs/README.zh-hans.md`, `docs/README.zh-hant.md`, `docs/README.ja.md`, `docs/README.ko.md`, `docs/README.ru.md`, `rwkv_org_profile:profile/README.md`, `rwkv_org_profile:profile/assets/hero.svg`, `rwkv_org_profile:profile/assets/hero-mobile.svg` |
| Repository-wide product scope, repository boundaries, inference boundary, and verification | `SPEC-RWKV-PRODUCT-SCOPE`, `SPEC-RWKV-REPOSITORY-BOUNDARIES`, `SPEC-RWKV-INFERENCE-BOUNDARY`, `SPEC-RWKV-VERIFICATION-BOUNDARY` | active | `docs/specification.md` | `AGENTS.md`, `docs/architecture/workspace-map.md`, `lib/store/p.dart`, `README.md`, `docs/README.zh-hans.md`, `docs/README.zh-hant.md`, `docs/README.ja.md`, `docs/README.ko.md`, `docs/README.ru.md`, `rwkv_mobile_flutter:.`, `rwkv_mobile:.`, `app_website:.` |
| App-level RWKV Chat acceptance identity and persistence boundary | `SPEC-RWKV-CHAT-SAME-APP-ACCEPTANCE` | active | `docs/specification.md` | `AGENTS.md`, `.agents/skills/spec-sync/SKILL.md`, `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/debug/AndroidManifest.xml`, `ios/Runner.xcodeproj/project.pbxproj`, `macos/Runner/Configs/AppInfo.xcconfig`, `windows/runner/Runner.rc`, `linux/CMakeLists.txt`, `test/same_app_acceptance_identity_test.dart` |
| Visible user-facing UI end-to-end acceptance for App, device, model download, runtime, and performance work | `SPEC-RWKV-CHAT-VISIBLE-UI-E2E-ACCEPTANCE` | active | `docs/specification.md` | `AGENTS.md`, `.agents/skills/spec-sync/SKILL.md`, `lib/main.dart`, `lib/page/home.dart`, `lib/widgets/chat_app_bar.dart`, `lib/widgets/model_selector.dart`, `test/same_app_acceptance_identity_test.dart` |
| Telemetry privacy, collection, and transmission contract | `SPEC-RWKV-TELEMETRY-PRIVACY-CONTRACT` | active | `docs/specification.md` | `docs/privacy_policy.html`, `PRODUCT.md`, `README.md`, `docs/README.zh-hans.md`, `docs/README.zh-hant.md`, `docs/README.ja.md`, `docs/README.ko.md`, `docs/README.ru.md`, `docs/architecture/store-map.md`, `lib/store/telemetry.dart`, `lib/store/chat_generation_completion.dart`, `lib/store/benchmark.dart` |
| Cloud Web Demo prompt-transmission and disclosure contract | `SPEC-RWKV-WEB-DEMO-DATA-FLOW` | conflicted | `docs/specification.md` | `docs/privacy_policy.html`, `PRODUCT.md`, `README.md`, `docs/README.zh-hans.md`, `docs/README.zh-hant.md`, `docs/README.ja.md`, `docs/README.ko.md`, `docs/README.ru.md`, `AGENTS.md`, `lib/store/web_demo.dart` |
| Public privacy-policy revision provenance proposal | `SPEC-RWKV-PRIVACY-POLICY-METADATA` | proposal | `docs/specification.md` | `docs/privacy_policy.html`, `docs/spec-process/observations/OBS-20260723-PRIVACY-POLICY-DATE.md` |
| Flutter and Dart toolchain baseline | `SPEC-RWKV-FLUTTER-BASELINE` | active | `pubspec.yaml` | `AGENTS.md`, `README.md`, `docs/README.zh-hans.md`, `docs/README.zh-hant.md`, `docs/README.ja.md`, `docs/README.ko.md`, `docs/README.ru.md`, `.github/workflows/unit-tests.yml` |
| Repository and symptom-to-entry ownership | `SPEC-RWKV-WORKSPACE-OWNERSHIP` | active | `docs/architecture/workspace-map.md` | `AGENTS.md`, `docs/specs/02-repository-map.md` |
| Riverpod store ownership | `SPEC-RWKV-STORE-OWNERSHIP` | active | `docs/architecture/store-map.md` | `lib/store/p.dart`, `lib/store/AGENTS.md` |
| RWKV App quantization catalog control and artifact acceptance | `SPEC-RWKV-QUANTIZATION-CATALOG-CONTROL`, `SPEC-RWKV-QUANTIZATION-DELIVERY` | active | `docs/contracts/model_quantization_catalog.md` | `docs/specification.md`, `docs/architecture/workspace-map.md`, `remote/latest.json`, `lib/model/file_info.dart`, `lib/store/remote.dart`, `lib/store/app.dart`, `tools/update_model_filesize.py`, `tools/deploy_latest_json.py` |
| App binary publication and public direct-download provider parity | `SPEC-RWKV-APP-BINARY-DISTRIBUTION` | active | `docs/contracts/app_distribution.md` | `.github/workflows`, `scripts/upload_to_hf.py`, `scripts/upload_to_modelscope.py`, `fastlane/Fastfile`, `fastlane/README.md`, `fastlane/actions/huggingface.rb`, `fastlane/actions/modelscope.rb`, `app_website:.` |
| Agentic Evaluation protocol | `SPEC-RWKV-AGENTIC-EVAL` | active | `docs/agentic-evaluation/eval-spec-v0.1.md` | `docs/agentic-evaluation/README.md`, `assets/agent_cases/primitive_bench_manifest.json`, `lib/store/agent.dart` |
| User-authorized Windows local Agent file actions in ordinary chat | `SPEC-RWKV-LOCAL-AGENT-FILE-ACTIONS` | active | `docs/contracts/local_agent_file_actions.md` | `docs/specification.md`, `docs/agentic-evaluation/eval-spec-v0.1.md`, `docs/architecture/workspace-map.md`, `lib/func/agent_local_file_host.dart`, `lib/func/agent_local_file_intent.dart`, `lib/store/agent.dart`, `lib/store/chat_input_send.dart`, `lib/store/chat_local_agent.dart`, `lib/store/chat_pause.dart`, `lib/page/chat.dart`, `lib/widgets/chat/agent_local_file_approval_card.dart`, `lib/widgets/sending_interaction.dart`, `test/agent_local_file_host_test.dart`, `test/agent_local_file_intent_test.dart` |
| Desktop UI redesign authorization | `SPEC-RWKV-DESKTOP-UI-REDESIGN-AUTHORIZATION` | active | `docs/contracts/desktop_ui_redesign.md` | `docs/specification.md`, `PRODUCT.md` |
| Multi-question parallel inference behavior | `SPEC-RWKV-MULTI-QUESTION-PARALLEL` | active | `docs/contracts/multi_question_parallel.md` | `lib/store/multi_question.dart`, `lib/store/chat.dart` |
| VL model update and display mapping | `SPEC-RWKV-VL-MODEL-UPDATE` | active | `docs/architecture/vl-model-update-guide.md` | `remote/latest.json`, `lib/model/file_info.dart`, `lib/store/remote.dart` |

## Truth Resolution

1. Find the topic and stable assertion ID in this table
2. Check `docs/spec-process/conflicts/current/` for an applicable blocking scope
3. Read the exact assertion in the canonical owner
4. Use private Root records and historical target decisions for provenance and explicit supersession
5. Compare required drift surfaces with the canonical assertion
6. Synchronize unambiguous drift; record a semantic conflict when traceable competing rulings leave intent genuinely ambiguous

Lifecycle meanings:

- `active`: current implementation contract
- `proposal`: approved or recorded plan that is not delivered behavior
- `historical`: retained context that does not govern new implementation
- `deferred`: intentionally out of active delivery scope
- `conflicted`: no business side may be selected until the linked current conflict is resolved
