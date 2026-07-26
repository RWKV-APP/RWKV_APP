#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
from pathlib import Path


def git(repository: Path, *arguments: str) -> bytes:
    return subprocess.check_output(
        ["git", "-C", str(repository), *arguments],
        stderr=subprocess.STDOUT,
    )


def update_field(digest: hashlib._Hash, label: bytes, value: bytes) -> None:
    digest.update(len(label).to_bytes(8, "big"))
    digest.update(label)
    digest.update(len(value).to_bytes(8, "big"))
    digest.update(value)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("repository", type=Path)
    args = parser.parse_args()

    repository = args.repository.resolve()
    if not repository.is_dir():
        raise SystemExit(f"repository is not a directory: {repository}")

    digest = hashlib.sha256()
    update_field(digest, b"head", git(repository, "rev-parse", "HEAD"))
    update_field(
        digest,
        b"staged",
        git(
            repository,
            "diff",
            "--cached",
            "--binary",
            "--full-index",
            "--no-ext-diff",
        ),
    )
    update_field(
        digest,
        b"unstaged",
        git(
            repository,
            "diff",
            "--binary",
            "--full-index",
            "--no-ext-diff",
        ),
    )

    untracked = git(
        repository,
        "ls-files",
        "--others",
        "--exclude-standard",
        "-z",
    ).split(b"\0")
    for encoded_relative in sorted(path for path in untracked if path):
        relative = os.fsdecode(encoded_relative)
        path = repository / relative
        update_field(digest, b"untracked-path", encoded_relative)
        update_field(
            digest,
            b"untracked-mode",
            (path.lstat().st_mode & 0o7777).to_bytes(8, "big"),
        )
        if path.is_symlink():
            update_field(
                digest,
                b"untracked-symlink",
                os.fsencode(os.readlink(path)),
            )
            continue
        if not path.is_file():
            raise SystemExit(f"untracked path is not a regular file: {relative}")
        with path.open("rb") as source:
            while chunk := source.read(8 * 1024 * 1024):
                update_field(digest, b"untracked-content", chunk)

    print(digest.hexdigest())


if __name__ == "__main__":
    main()
