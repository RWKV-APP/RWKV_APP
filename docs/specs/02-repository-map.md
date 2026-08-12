# Specification Repository Map

Process version: v1.8
Last reviewed: 2026-08-10

Repository-qualified references use `alias:path`. The path is relative to the registered repository root. Optional sibling repositories are validated when present and remain syntactically checkable in CI when absent.

| Alias | Root | Required | Description |
| --- | --- | --- | --- |
| rwkv_app | `.` | yes | Flutter application and this Specification system |
| rwkv_mobile_flutter | `../rwkv_mobile_flutter` | no | Flutter adapter and FFI bridge |
| rwkv_mobile | `../rwkv-mobile` | no | Native inference engine workspace |
| app_website | `../app_website` | no | Public download website and HTTP service |
| rwkv_org_profile | `../.github` | no | Public RWKV-APP organization profile repository |

Do not use absolute developer-machine paths as durable Specification references. A cross-repository requirement should name the integration assertion in this repository and list the external implementation through an alias.

Reference paths cannot contain traversal segments and must remain inside the registered root after symlink resolution. DEC, OBS, CF, and ACC records are regular repository files, not symlinks. Opaque PI source IDs are owned by the private Root Harness and do not resolve to files in this repository.
