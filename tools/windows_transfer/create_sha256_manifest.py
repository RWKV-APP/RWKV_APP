#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument(
        "--output",
        default="SHA256MANIFEST.txt",
        help="Manifest path relative to root",
    )
    args = parser.parse_args()

    root = args.root.resolve()
    output = (root / args.output).resolve()
    if not root.is_dir():
        raise SystemExit(f"root is not a directory: {root}")
    if output.parent != root:
        raise SystemExit("manifest must be written at the package root")

    entries: list[str] = []
    for path in sorted(root.rglob("*"), key=lambda item: item.as_posix()):
        if path == output or path.is_dir():
            continue
        if path.is_symlink():
            raise SystemExit(f"symlink is not portable in this package: {path}")
        relative = path.relative_to(root).as_posix()
        if "\n" in relative or "\r" in relative:
            raise SystemExit(f"newline in package path: {relative!r}")
        entries.append(f"{sha256_file(path)}  {relative}")

    output.write_text("\n".join(entries) + "\n", encoding="utf-8", newline="\n")
    print(f"wrote {len(entries)} hashes to {output}")


if __name__ == "__main__":
    main()
