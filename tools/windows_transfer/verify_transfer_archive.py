#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import stat
import tempfile
import zipfile
from pathlib import Path, PurePosixPath


MANIFEST_LINE = re.compile(r"^([0-9a-f]{64})  (.+)$")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_member(name: str) -> None:
    normalized = name.replace("\\", "/")
    path = PurePosixPath(normalized)
    if not normalized or normalized == ".":
        raise ValueError(f"empty ZIP member: {name!r}")
    if path.is_absolute() or re.match(r"^[A-Za-z]:", normalized):
        raise ValueError(f"absolute ZIP member: {name}")
    if ".." in path.parts:
        raise ValueError(f"parent traversal in ZIP member: {name}")
    if "__MACOSX" in path.parts:
        raise ValueError(f"macOS metadata in ZIP member: {name}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()

    archive = args.archive.resolve()
    if not archive.is_file():
        raise SystemExit(f"archive does not exist: {archive}")

    temp = Path(tempfile.mkdtemp(prefix="rwkv-transfer-verify-"))
    try:
        with zipfile.ZipFile(archive) as source:
            seen_members: set[str] = set()
            top_levels: set[str] = set()
            for info in source.infolist():
                validate_member(info.filename)
                normalized = info.filename.replace("\\", "/").rstrip("/")
                if normalized in seen_members:
                    raise ValueError(f"duplicate ZIP member: {info.filename}")
                seen_members.add(normalized)
                parts = PurePosixPath(normalized).parts
                if not parts:
                    raise ValueError(f"invalid ZIP member: {info.filename}")
                top_levels.add(parts[0])
                member_type = (info.external_attr >> 16) & 0o170000
                if member_type == stat.S_IFLNK:
                    raise ValueError(f"symlink ZIP member: {info.filename}")
            if len(top_levels) != 1:
                raise ValueError(
                    f"expected one top-level directory, found {sorted(top_levels)}"
                )
            source.extractall(temp)

        top_level = next(iter(top_levels))
        root = temp / top_level
        if not root.is_dir():
            raise ValueError(f"top-level ZIP member is not a directory: {top_level}")
        manifest = root / "SHA256MANIFEST.txt"
        if not manifest.is_file():
            raise ValueError("missing root SHA256MANIFEST.txt")
        manifests = list(temp.rglob("SHA256MANIFEST.txt"))
        if manifests != [manifest]:
            raise ValueError(f"expected one root manifest, found {len(manifests)}")

        expected: dict[str, str] = {}
        for line in manifest.read_text(encoding="utf-8").splitlines():
            match = MANIFEST_LINE.fullmatch(line)
            if match is None:
                raise ValueError(f"invalid manifest line: {line!r}")
            digest, relative = match.groups()
            validate_member(relative)
            if relative in expected:
                raise ValueError(f"duplicate manifest path: {relative}")
            expected[relative] = digest

        actual = {
            path.relative_to(root).as_posix()
            for path in temp.rglob("*")
            if path.is_file() and path != manifest
        }
        if actual != set(expected):
            missing = sorted(set(expected) - actual)
            extra = sorted(actual - set(expected))
            raise ValueError(f"manifest file-set mismatch; missing={missing[:5]} extra={extra[:5]}")
        for relative, digest in expected.items():
            actual_digest = sha256_file(root / relative)
            if actual_digest != digest:
                raise ValueError(f"hash mismatch: {relative}")
        print(f"archive verification passed: {archive} ({len(expected)} files)")
    finally:
        shutil.rmtree(temp)


if __name__ == "__main__":
    main()
