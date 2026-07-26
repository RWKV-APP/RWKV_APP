# Specification Repository Map

Process version: v1.7
Last reviewed: 2026-07-25

Repository-qualified references use `alias:path`. The path is relative to the registered repository root. Optional sibling repositories are validated when present and remain syntactically checkable in CI when absent.

| Alias | Root | Required | Description |
| --- | --- | --- | --- |
| rwkv_app | `.` | yes | Flutter application and this Specification system |
| rwkv_mobile_flutter | `../rwkv_mobile_flutter` | no | Flutter adapter and FFI bridge |
| rwkv_mobile | `../rwkv_mobile` | no | Native inference engine |
| rwkv_harmony | `../rwkv_harmony` | no | HarmonyOS ArkUI host and Kirin NNRT integration workspace |
| app_website | `../app_website` | no | Public download website and HTTP service |

Do not use absolute developer-machine paths as durable Specification references. A cross-repository requirement should name the integration assertion in this repository and list the external implementation through an alias.

Reference paths cannot contain traversal segments and must remain inside the registered root after symlink resolution. Strict PI, DEC, OBS, CF, and ACC records are regular repository files, not symlinks.
