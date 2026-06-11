# tools AGENTS.md

## Scope

- Applies to helper scripts and the nested Dart tool package under `tools`
- Put engineering helper code here instead of `lib`
- Keep generated or temporary outputs under ignored paths such as `tools/output`

## Script Rules

- Scripts should be runnable from the repository root when practical
- Prefer explicit inputs, readable output, and non-zero exit codes for real failures
- Do not require network access unless the script name and README entry make that clear
- Keep destructive operations opt-in and visibly named

## Dart Style

- Follow the repository Dart style unless a generated file requires otherwise
- Prefer explicit types plus `final`
- Use `await` instead of `.then`
- Use `for` loops instead of `forEach`

## Verification

```bash
dart run tools/bin/agent_check.dart --rules-only
```

```bash
cd tools && dart test
```
