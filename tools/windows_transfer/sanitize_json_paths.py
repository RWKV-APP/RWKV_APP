#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path, PurePosixPath, PureWindowsPath
from typing import Any


MAC_PATH = re.compile(r"^/Users/[^/]+/.+")
WINDOWS_PATH = re.compile(r"^[A-Za-z]:[\\/]+Users[\\/]+[^\\/]+[\\/].+", re.IGNORECASE)


def sanitize(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: sanitize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [sanitize(item) for item in value]
    if not isinstance(value, str):
        return value
    if MAC_PATH.fullmatch(value):
        return f"<SOURCE_MACHINE_PATH>/{PurePosixPath(value).name}"
    if WINDOWS_PATH.fullmatch(value):
        return f"<SOURCE_MACHINE_PATH>/{PureWindowsPath(value).name}"
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args()

    changed = 0
    for root in args.paths:
        candidates = [root] if root.is_file() else sorted(root.rglob("*.json"))
        for path in candidates:
            data = json.loads(path.read_text(encoding="utf-8"))
            sanitized = sanitize(data)
            if sanitized == data:
                continue
            path.write_text(
                json.dumps(sanitized, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
                newline="\n",
            )
            changed += 1
    print(f"sanitized machine-local JSON paths in {changed} file(s)")


if __name__ == "__main__":
    main()
