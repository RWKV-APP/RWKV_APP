#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from pathlib import Path


FORBIDDEN_NAMES = {
    ".env",
    ".netrc",
    ".npmrc",
    ".pypirc",
    "credentials.json",
    "google-services.json",
    "id_ed25519",
    "id_rsa",
    "key.properties",
    "local.properties",
    "sentry.properties",
}
FORBIDDEN_SUFFIXES = {
    ".jks",
    ".key",
    ".keystore",
    ".mobileprovision",
    ".p12",
    ".p7b",
    ".pem",
    ".pfx",
}
WINDOWS_RESERVED = {
    "aux",
    "clock$",
    "com1",
    "com2",
    "com3",
    "com4",
    "com5",
    "com6",
    "com7",
    "com8",
    "com9",
    "con",
    "lpt1",
    "lpt2",
    "lpt3",
    "lpt4",
    "lpt5",
    "lpt6",
    "lpt7",
    "lpt8",
    "lpt9",
    "nul",
    "prn",
}
SECRET_PATTERNS = (
    re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(rb"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(rb"\bAIza[0-9A-Za-z_-]{30,}\b"),
    re.compile(rb"\b(?:gh[pousr]|hf)_[A-Za-z0-9]{20,}\b"),
    re.compile(rb"\bsk-[A-Za-z0-9_-]{20,}\b"),
    re.compile(rb"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    re.compile(rb"X-Amz-Signature=[A-Za-z0-9]{20,}", re.IGNORECASE),
    re.compile(rb"Authorization:\s*Bearer\s+[A-Za-z0-9._-]{20,}", re.IGNORECASE),
)
MACHINE_PATH_ALLOWLIST = {
    "sources/app_website/docs/ai/rwkv-chat-handoff.md",
    "sources/app_website/docs/deploy.md",
    "sources/app_website/tools/migrate-release-notes.ts",
    "sources/rwkv_app/tools/local_web_search_query_eval.dart",
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--machine-home", type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    if not root.is_dir():
        raise SystemExit(f"root is not a directory: {root}")

    machine_path_patterns = [
        re.compile(re.escape(b"/private" + b"/var/folders/")),
    ]
    if args.machine_home is not None:
        machine_home = str(args.machine_home.resolve()).encode()
        machine_path_patterns.append(re.compile(re.escape(machine_home + b"/")))

    issues: list[str] = []
    folded: dict[str, str] = {}
    file_count = 0
    for path in sorted(root.rglob("*"), key=lambda item: item.as_posix()):
        relative = path.relative_to(root).as_posix()
        if path.is_symlink():
            issues.append(f"symlink: {relative}")
            continue
        for component in path.relative_to(root).parts:
            stem = component.split(".", 1)[0].casefold()
            if stem in WINDOWS_RESERVED:
                issues.append(f"Windows reserved name: {relative}")
            if component.endswith((" ", ".")):
                issues.append(f"trailing space or dot: {relative}")
            if any(char in component for char in '<>:"|?*'):
                issues.append(f"Windows-invalid character: {relative}")
        folded_path = relative.casefold()
        existing = folded.get(folded_path)
        if existing is not None and existing != relative:
            issues.append(f"case collision: {existing} / {relative}")
        folded[folded_path] = relative
        if len(relative) > 240:
            issues.append(f"path longer than 240 characters: {relative}")
        if path.is_dir():
            continue

        file_count += 1
        lower_name = path.name.casefold()
        if lower_name in FORBIDDEN_NAMES:
            issues.append(f"forbidden local configuration: {relative}")
        if lower_name.startswith(".env.") and not lower_name.endswith(".example"):
            issues.append(f"forbidden local environment variant: {relative}")
        if lower_name.startswith("service-account") and lower_name.endswith(".json"):
            issues.append(f"forbidden service-account file: {relative}")
        if path.suffix.casefold() in FORBIDDEN_SUFFIXES:
            issues.append(f"forbidden signing material: {relative}")
        if path.stat().st_size > 16 * 1024 * 1024:
            continue
        data = path.read_bytes()
        if b"\0" in data[:8192]:
            continue
        for pattern in SECRET_PATTERNS:
            if pattern.search(data):
                issues.append(f"high-confidence secret pattern: {relative}")
                break
        if relative not in MACHINE_PATH_ALLOWLIST:
            for pattern in machine_path_patterns:
                if pattern.search(data):
                    issues.append(f"machine-local absolute path: {relative}")
                    break

    if issues:
        print("\n".join(issues))
        raise SystemExit(f"transfer audit failed with {len(issues)} issue(s)")
    print(
        "transfer audit passed: "
        f"{file_count} files; "
        f"{len(MACHINE_PATH_ALLOWLIST)} approved tracked path-example files"
    )


if __name__ == "__main__":
    main()
