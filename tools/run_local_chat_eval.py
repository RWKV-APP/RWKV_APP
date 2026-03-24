#!/usr/bin/env python3

"""
Run resumable local chat evaluation against the RWKV OpenAI-compatible server.

This runner writes:
- one manifest per run
- one sample file per prompt

Each sample file is updated after every attempt so a long run can be resumed or
inspected without waiting for the entire batch to finish.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import random
import re
import tempfile
import time
import urllib.error
import urllib.request


ROOT = pathlib.Path("/Users/wangce/docs/repo/rwkv_app")
DEFAULT_BASE_URL = "http://localhost:8080"


def utc_now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def sanitize_for_name(text: str) -> str:
    lowered = text.lower()
    replaced = re.sub(r"[^a-z0-9]+", "-", lowered)
    collapsed = re.sub(r"-{2,}", "-", replaced)
    return collapsed.strip("-")


def atomic_write_json(path: pathlib.Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w",
        dir=path.parent,
        encoding="utf-8",
        delete=False,
    ) as tmp_file:
        json.dump(payload, tmp_file, ensure_ascii=False, indent=2)
        tmp_file.write("\n")
        temp_path = pathlib.Path(tmp_file.name)
    temp_path.replace(path)


def get_json(url: str, timeout_s: int) -> dict:
    request = urllib.request.Request(url, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout_s) as response:
        return json.loads(response.read().decode("utf-8"))


def post_json(url: str, payload: dict, timeout_s: int) -> dict:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=timeout_s) as response:
        return json.loads(response.read().decode("utf-8"))


def flatten_chat_items(source_path: pathlib.Path) -> list[dict]:
    payload = json.loads(source_path.read_text(encoding="utf-8"))
    flattened: list[dict] = []
    for category_index, category in enumerate(payload):
        for item_index, item in enumerate(category["items"]):
            flattened.append(
                {
                    "category_name": category["name"],
                    "category_index": category_index,
                    "item_index": item_index,
                    "display": item["display"],
                    "prompt": item["prompt"],
                }
            )
    return flattened


def build_sample_filename(sample_index: int, language: str, status: str) -> str:
    return f"{sample_index:04d}_{status}_{language}_chat.json"


def find_existing_sample_path(
    samples_dir: pathlib.Path,
    sample_index: int,
    language: str,
) -> pathlib.Path | None:
    pattern = f"{sample_index:04d}_*_{language}_chat.json"
    matches = sorted(samples_dir.glob(pattern))
    if not matches:
        return None
    return matches[0]


def finalize_sample_status(sample: dict) -> str:
    if not sample["attempts"]:
        return "pending"
    if all(attempt["status"] == "completed" for attempt in sample["attempts"]):
        return "completed"
    if any(attempt["status"] == "completed" for attempt in sample["attempts"]):
        return "partial"
    return "error"


def update_manifest(
    manifest_path: pathlib.Path,
    run_payload: dict,
    samples: list[dict],
) -> None:
    completed_samples = sum(1 for sample in samples if sample["status"] == "completed")
    running_samples = sum(1 for sample in samples if sample["status"] == "running")
    partial_samples = sum(1 for sample in samples if sample["status"] == "partial")
    error_samples = sum(1 for sample in samples if sample["status"] == "error")
    pending_samples = sum(1 for sample in samples if sample["status"] == "pending")
    done_attempts = sum(sample["repeat_count_done"] for sample in samples)
    total_attempts = sum(sample["repeat_count_target"] for sample in samples)

    run_payload["updated_at"] = utc_now_iso()
    run_payload["completed_samples"] = completed_samples
    run_payload["running_samples"] = running_samples
    run_payload["partial_samples"] = partial_samples
    run_payload["error_samples"] = error_samples
    run_payload["pending_samples"] = pending_samples
    run_payload["done_attempts"] = done_attempts
    run_payload["total_attempts"] = total_attempts

    if completed_samples == run_payload["total_samples"]:
        run_payload["status"] = "completed"
    elif running_samples > 0:
        run_payload["status"] = "running"
    elif partial_samples > 0:
        run_payload["status"] = "partial"
    elif error_samples > 0 and done_attempts == 0:
        run_payload["status"] = "error"
    else:
        run_payload["status"] = "pending"

    atomic_write_json(manifest_path, run_payload)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source-file",
        default=str(ROOT / "remote" / "chat_suggestions_zh.json"),
    )
    parser.add_argument("--language", default="zh")
    parser.add_argument("--sample-count", type=int, default=5)
    parser.add_argument("--repeat-count", type=int, default=5)
    parser.add_argument("--max-tokens", type=int, default=4000)
    parser.add_argument("--seed", type=int, default=20260324)
    parser.add_argument(
        "--selection-mode",
        choices=["random", "sequential"],
        default="random",
    )
    parser.add_argument("--timeout-seconds", type=int, default=900)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--resume-run-dir")
    parser.add_argument("--retry-from-index", type=int, default=1)
    parser.add_argument(
        "--reset-statuses",
        default="",
        help="Comma-separated sample statuses to reset when resuming, e.g. partial,error",
    )
    parser.add_argument(
        "--out-root",
        default=str(ROOT / "remote" / "evals"),
    )
    args = parser.parse_args()

    source_path = pathlib.Path(args.source_file)
    out_root = pathlib.Path(args.out_root)
    reset_statuses = {
        item.strip()
        for item in args.reset_statuses.split(",")
        if item.strip()
    }

    if args.resume_run_dir:
        run_dir = pathlib.Path(args.resume_run_dir)
        samples_dir = run_dir / "samples"
        manifest_path = run_dir / "manifest.json"
        manifest_payload = json.loads(manifest_path.read_text(encoding="utf-8"))
        samples = []
        for path in sorted(samples_dir.glob(f"*_{args.language}_chat.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            samples.append(data)
        samples.sort(key=lambda sample: sample["sample_index"])

        for sample in samples:
            if sample["sample_index"] < args.retry_from_index:
                continue
            if sample["status"] not in reset_statuses:
                continue
            sample["status"] = "pending"
            sample["repeat_count_done"] = 0
            sample["started_at"] = None
            sample["updated_at"] = utc_now_iso()
            sample["attempts"] = []
            sample["score_status"] = "pending"
            sample.pop("average_score", None)
            sample.pop("scored_at", None)
            current_path = find_existing_sample_path(
                samples_dir,
                sample["sample_index"],
                args.language,
            )
            if current_path is not None:
                pending_path = samples_dir / build_sample_filename(
                    sample["sample_index"],
                    args.language,
                    "pending",
                )
                if current_path != pending_path:
                    current_path.replace(pending_path)
                atomic_write_json(pending_path, sample)
    else:
        server_status = get_json(f"{args.base_url}/v1/server/status", timeout_s=10)
        model_name = server_status.get("models", ["unknown-model"])[0]
        model_slug = sanitize_for_name(model_name)[:48]
        timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H%M%S")
        flattened = flatten_chat_items(source_path)
        sample_count = args.sample_count
        if sample_count <= 0 or sample_count > len(flattened):
            sample_count = len(flattened)

        if args.selection_mode == "random":
            random_generator = random.Random(args.seed)
            selected = random_generator.sample(flattened, sample_count)
        else:
            selected = flattened[:sample_count]

        run_id = (
            f"{timestamp}_{model_slug}_chat_{args.language}"
            f"_n{sample_count}_r{args.repeat_count}_mt{args.max_tokens}"
        )
        run_dir = out_root / run_id
        samples_dir = run_dir / "samples"
        manifest_path = run_dir / "manifest.json"

        samples = []
        for sample_index, item in enumerate(selected, start=1):
            samples.append(
                {
                    "run_id": run_id,
                    "language": args.language,
                    "task_type": "chat",
                    "status": "pending",
                    "sample_index": sample_index,
                    "display": item["display"],
                    "prompt": item["prompt"],
                    "source_file": str(source_path),
                    "source_category_name": item["category_name"],
                    "source_category_index": item["category_index"],
                    "source_item_index": item["item_index"],
                    "base_url": args.base_url,
                    "endpoint": f"{args.base_url}/v1/chat/completions",
                    "model_request": "rwkv",
                    "model_name_reported_by_server": model_name,
                    "max_tokens": args.max_tokens,
                    "repeat_count_target": args.repeat_count,
                    "repeat_count_done": 0,
                    "score_status": "pending",
                    "started_at": None,
                    "updated_at": utc_now_iso(),
                    "attempts": [],
                }
            )

        manifest_payload = {
            "run_id": run_id,
            "status": "pending",
            "score_status": "pending",
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
            "base_url": args.base_url,
            "endpoint": f"{args.base_url}/v1/chat/completions",
            "task_type": "chat",
            "language": args.language,
            "source_file": str(source_path),
            "model_request": "rwkv",
            "model_name_reported_by_server": model_name,
            "selection_mode": args.selection_mode,
            "source_total_items": len(flattened),
            "sample_count_requested": sample_count,
            "repeat_count": args.repeat_count,
            "max_tokens": args.max_tokens,
            "seed": args.seed,
            "total_samples": len(samples),
            "completed_samples": 0,
            "running_samples": 0,
            "partial_samples": 0,
            "error_samples": 0,
            "pending_samples": len(samples),
            "done_attempts": 0,
            "total_attempts": len(samples) * args.repeat_count,
            "samples_dir": str(samples_dir),
        }

        update_manifest(manifest_path, manifest_payload, samples)

        for sample in samples:
            current_path = samples_dir / build_sample_filename(
                sample["sample_index"],
                args.language,
                sample["status"],
            )
            atomic_write_json(current_path, sample)

    for sample in samples:
        if sample["repeat_count_done"] >= sample["repeat_count_target"]:
            sample["status"] = finalize_sample_status(sample)
            update_manifest(manifest_path, manifest_payload, samples)
            continue

        current_path = find_existing_sample_path(
            samples_dir,
            sample["sample_index"],
            args.language,
        )
        if current_path is None:
            raise FileNotFoundError(
                f"Could not find sample file for index {sample['sample_index']}",
            )

        sample["status"] = "running"
        if sample["started_at"] is None:
            sample["started_at"] = utc_now_iso()
        sample["updated_at"] = utc_now_iso()
        running_path = samples_dir / build_sample_filename(
            sample["sample_index"],
            args.language,
            sample["status"],
        )
        if current_path != running_path:
            current_path.replace(running_path)
        atomic_write_json(running_path, sample)
        update_manifest(manifest_path, manifest_payload, samples)

        next_attempt_index = sample["repeat_count_done"] + 1
        for attempt_index in range(next_attempt_index, sample["repeat_count_target"] + 1):
            started_at = utc_now_iso()
            started_monotonic = time.monotonic()
            payload = {
                "model": "rwkv",
                "messages": [{"role": "user", "content": sample["prompt"]}],
                "max_tokens": args.max_tokens,
            }

            try:
                response = post_json(
                    f"{args.base_url}/v1/chat/completions",
                    payload=payload,
                    timeout_s=args.timeout_seconds,
                )
                content = response["choices"][0]["message"]["content"]
                attempt_payload = {
                    "attempt": attempt_index,
                    "status": "completed",
                    "started_at": started_at,
                    "ended_at": utc_now_iso(),
                    "duration_ms": int((time.monotonic() - started_monotonic) * 1000),
                    "response_chars": len(content),
                    "response": content,
                    "score": None,
                    "score_note": None,
                }
            except urllib.error.HTTPError as error:
                error_body = error.read().decode("utf-8", errors="replace")
                attempt_payload = {
                    "attempt": attempt_index,
                    "status": "error",
                    "started_at": started_at,
                    "ended_at": utc_now_iso(),
                    "duration_ms": int((time.monotonic() - started_monotonic) * 1000),
                    "error_type": "http_error",
                    "error_message": str(error),
                    "error_body": error_body,
                }
            except Exception as error:  # noqa: BLE001
                attempt_payload = {
                    "attempt": attempt_index,
                    "status": "error",
                    "started_at": started_at,
                    "ended_at": utc_now_iso(),
                    "duration_ms": int((time.monotonic() - started_monotonic) * 1000),
                    "error_type": type(error).__name__,
                    "error_message": str(error),
                }

            sample["attempts"].append(attempt_payload)
            sample["repeat_count_done"] = len(sample["attempts"])
            sample["updated_at"] = utc_now_iso()
            atomic_write_json(running_path, sample)
            update_manifest(manifest_path, manifest_payload, samples)

        sample["status"] = finalize_sample_status(sample)
        sample["updated_at"] = utc_now_iso()
        final_path = samples_dir / build_sample_filename(
            sample["sample_index"],
            args.language,
            sample["status"],
        )
        running_path.replace(final_path)
        atomic_write_json(final_path, sample)
        update_manifest(manifest_path, manifest_payload, samples)

    print(run_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
