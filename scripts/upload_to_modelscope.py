#!/usr/bin/env python3
"""Upload an RWKV App build artifact to a ModelScope dataset repository."""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
from pathlib import Path
from typing import Any, Callable
from urllib.parse import quote


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

ApiFactory = Callable[..., Any]


def _validate_repo_id(repo_id: str) -> str:
    normalized = repo_id.strip().strip("/")
    if normalized.count("/") != 1 or any(not part for part in normalized.split("/")):
        raise ValueError("ModelScope repo ID must use the owner/name format")
    return normalized


def _validate_path_in_repo(path_in_repo: str) -> str:
    normalized = path_in_repo.strip().replace("\\", "/").lstrip("/")
    if not normalized or any(part in {"", ".", ".."} for part in normalized.split("/")):
        raise ValueError("ModelScope path in repo must be a normalized relative path")
    return normalized


def build_download_url(endpoint: str, repo_id: str, revision: str, path_in_repo: str) -> str:
    encoded_path = quote(path_in_repo, safe="/")
    return (
        f"{endpoint.rstrip('/')}/datasets/{repo_id}/resolve/"
        f"{quote(revision, safe='')}/{encoded_path}"
    )


class ModelScopeUploader:
    """Small adapter around the official ``modelscope-hub`` client."""

    def __init__(
        self,
        token: str,
        endpoint: str = "https://modelscope.cn",
        api_factory: ApiFactory | None = None,
    ) -> None:
        if not token or not token.strip():
            raise ValueError("MODELSCOPE_API_TOKEN is required")

        if api_factory is None:
            try:
                from modelscope_hub import HubApi
            except ImportError as exc:
                raise RuntimeError(
                    "modelscope-hub is required; install it with: pip install modelscope-hub"
                ) from exc
            api_factory = HubApi

        self.endpoint = endpoint.rstrip("/")
        self.api = api_factory(token=token.strip(), endpoint=self.endpoint)
        self.anonymous_api = api_factory(token="", endpoint=self.endpoint)

    def upload_file(
        self,
        repo_id: str,
        local_path: str,
        path_in_repo: str,
        revision: str = "master",
        commit_message: str | None = None,
    ) -> Any:
        normalized_repo_id = _validate_repo_id(repo_id)
        normalized_path = _validate_path_in_repo(path_in_repo)
        artifact = Path(local_path).expanduser().resolve()
        if not artifact.is_file():
            raise FileNotFoundError(f"Artifact not found: {artifact}")

        message = commit_message or f"Upload {artifact.name}"
        logger.info(
            "Uploading %s (%.2f MiB) to ModelScope dataset %s/%s",
            artifact.name,
            artifact.stat().st_size / (1024 * 1024),
            normalized_repo_id,
            normalized_path,
        )
        digest = hashlib.sha256()
        with artifact.open('rb') as stream:
            for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b''):
                digest.update(chunk)
        expected = (artifact.stat().st_size, digest.hexdigest())
        existing = next((item for item in self.api.list_repo_files(normalized_repo_id, 'dataset', revision=revision)
                         if item.path == normalized_path), None)
        if existing is not None:
            if (existing.size, existing.sha256) != expected:
                raise ValueError(f'Refusing to overwrite different release bytes: {normalized_path}')
            result = {'skipped': True, 'sha256': expected[1]}
        else:
            result = self.api.upload_file(
                normalized_repo_id,
                "dataset",
                str(artifact),
                normalized_path,
                revision=revision,
                commit_message=message,
                disable_tqdm=True,
            )
        published = next((item for item in self.anonymous_api.list_repo_files(normalized_repo_id, 'dataset', revision=revision)
                          if item.path == normalized_path), None)
        if published is None or (published.size, published.sha256) != expected:
            raise RuntimeError(f'Anonymous ModelScope release checksum verification failed: {normalized_path}')
        logger.info(
            "ModelScope upload completed: %s",
            build_download_url(
                self.endpoint,
                normalized_repo_id,
                revision,
                normalized_path,
            ),
        )
        return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-id", required=True)
    parser.add_argument("--file", required=True, dest="local_path")
    parser.add_argument("--path-in-repo", required=True)
    parser.add_argument(
        "--endpoint",
        default=os.getenv("MODELSCOPE_ENDPOINT", "https://modelscope.cn"),
    )
    parser.add_argument(
        "--revision",
        default=os.getenv("MODELSCOPE_REVISION", "master"),
    )
    parser.add_argument("--commit-message")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate the artifact mapping without importing the SDK or uploading",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_id = _validate_repo_id(args.repo_id)
    path_in_repo = _validate_path_in_repo(args.path_in_repo)
    artifact = Path(args.local_path).expanduser().resolve()
    if not artifact.is_file():
        raise FileNotFoundError(f"Artifact not found: {artifact}")

    if args.dry_run:
        print(
            json.dumps(
                {
                    "repoId": repo_id,
                    "repoType": "dataset",
                    "revision": args.revision,
                    "localPath": str(artifact),
                    "pathInRepo": path_in_repo,
                    "downloadUrl": build_download_url(
                        args.endpoint,
                        repo_id,
                        args.revision,
                        path_in_repo,
                    ),
                },
                indent=2,
            )
        )
        return 0

    token = os.getenv("MODELSCOPE_API_TOKEN", "")
    uploader = ModelScopeUploader(token=token, endpoint=args.endpoint)
    uploader.upload_file(
        repo_id=repo_id,
        local_path=str(artifact),
        path_in_repo=path_in_repo,
        revision=args.revision,
        commit_message=args.commit_message,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
