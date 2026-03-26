#!/usr/bin/env python3

"""
Run resumable local chat evaluation against the RWKV OpenAI-compatible server.

This runner writes:
- one manifest per run
- one generation summary per run
- one sample file per prompt

Each sample file is updated after every attempt so a long run can be resumed or
inspected without waiting for the entire batch to finish.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import platform
import random
import re
import subprocess
import tempfile
import time
import urllib.error
import urllib.request


ROOT = pathlib.Path("/Users/wangce/docs/repo/rwkv_app")
DEFAULT_BASE_URL = "http://localhost:8080"
DEFAULT_SOURCE_FILE = (
    ROOT / "docs" / "requirements" / "prompt" / "prebuilt-prompt-zh-hans.json"
)
DEVICE_INFO_KEYS = (
    "eval_device_label",
    "eval_device_cpu",
    "eval_device_gpu",
    "eval_device_memory_gb",
    "eval_device_vram_gb",
)


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


def run_command(command: list[str]) -> str | None:
    try:
        completed = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
    except Exception:
        return None

    stdout = completed.stdout.strip()
    if not stdout:
        return None
    return stdout


def parse_gb_value(raw: str | int | float | None) -> int | float | None:
    if raw is None:
        return None

    if isinstance(raw, (int, float)):
        value = float(raw)
    else:
        cleaned = str(raw).strip()
        if not cleaned:
            return None
        number_match = re.search(r"(\d+(?:\.\d+)?)", cleaned)
        if number_match is None:
            return None
        value = float(number_match.group(1))
        lowered = cleaned.lower()
        if "tb" in lowered:
            value *= 1024
        elif "mb" in lowered:
            value /= 1024
        elif "kb" in lowered:
            value /= 1024 * 1024
        elif "byte" in lowered or "bytes" in lowered:
            value /= 1024 * 1024 * 1024

    rounded = round(value, 1)
    if rounded.is_integer():
        return int(rounded)
    return rounded


def parse_bytes_to_gb(raw: str | int | float | None) -> int | float | None:
    if raw is None:
        return None
    try:
        value = float(raw)
    except Exception:
        return None
    if value <= 0:
        return None
    return parse_gb_value(f"{value} bytes")


def dedupe_strings(values: list[str]) -> list[str]:
    seen: set[str] = set()
    deduped: list[str] = []
    for value in values:
        cleaned = value.strip()
        if not cleaned:
            continue
        if cleaned in seen:
            continue
        seen.add(cleaned)
        deduped.append(cleaned)
    return deduped


def join_or_none(values: list[str]) -> str | None:
    deduped = dedupe_strings(values)
    if not deduped:
        return None
    return " / ".join(deduped)


def detect_macos_label_suffix(displays_payload: dict) -> str | None:
    size_map = {
        "3456 x 2234": "16-inch",
        "3024 x 1964": "14-inch",
        "2880 x 1864": "15-inch",
        "2560 x 1664": "13-inch",
        "2880 x 1800": "15-inch",
    }

    display_groups = displays_payload.get("SPDisplaysDataType", [])
    for group in display_groups:
        for display in group.get("spdisplays_ndrvs", []):
            connection_type = display.get("spdisplays_connection_type")
            if connection_type != "spdisplays_internal":
                continue
            pixels = display.get("_spdisplays_pixels")
            if pixels is None:
                continue
            suffix = size_map.get(pixels)
            if suffix is not None:
                return suffix
    return None


def detect_macos_vram_gb(displays_payload: dict) -> int | float | None:
    display_groups = displays_payload.get("SPDisplaysDataType", [])
    values: list[int | float] = []

    for group in display_groups:
        for key, raw in group.items():
            lowered = key.lower()
            if "vram" not in lowered and "memory" not in lowered:
                continue
            parsed = parse_gb_value(raw)
            if parsed is None:
                continue
            values.append(parsed)

    if not values:
        return None

    max_value = max(float(value) for value in values)
    if max_value.is_integer():
        return int(max_value)
    return round(max_value, 1)


def detect_macos_device_info() -> dict:
    hardware_stdout = run_command(["system_profiler", "SPHardwareDataType", "-json"])
    displays_stdout = run_command(["system_profiler", "SPDisplaysDataType", "-json"])

    hardware_payload = {}
    displays_payload = {}
    if hardware_stdout is not None:
        hardware_payload = json.loads(hardware_stdout)
    if displays_stdout is not None:
        displays_payload = json.loads(displays_stdout)

    hardware_items = hardware_payload.get("SPHardwareDataType", [])
    hardware = hardware_items[0] if hardware_items else {}
    label = hardware.get("machine_name")
    suffix = detect_macos_label_suffix(displays_payload)
    if label is not None and suffix is not None:
        label = f"{label} {suffix}"

    gpu_values: list[str] = []
    for group in displays_payload.get("SPDisplaysDataType", []):
        model = group.get("sppci_model")
        if model is not None:
            gpu_values.append(model)

    return {
        "eval_device_label": label,
        "eval_device_cpu": hardware.get("chip_type") or hardware.get("cpu_type"),
        "eval_device_gpu": join_or_none(gpu_values),
        "eval_device_memory_gb": parse_gb_value(hardware.get("physical_memory")),
        "eval_device_vram_gb": detect_macos_vram_gb(displays_payload),
    }


def detect_windows_device_info() -> dict:
    script = """
$computer = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpus = Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM
[PSCustomObject]@{
  label = if ($computer.Model) { $computer.Model } else { $null }
  cpu = if ($cpu.Name) { $cpu.Name } else { $null }
  memory_bytes = $computer.TotalPhysicalMemory
  gpus = $gpus
} | ConvertTo-Json -Depth 4 -Compress
"""
    stdout = run_command(["powershell", "-NoProfile", "-Command", script])
    if stdout is None:
        return {
            key: None for key in DEVICE_INFO_KEYS
        }

    payload = json.loads(stdout)
    gpus = payload.get("gpus") or []
    if isinstance(gpus, dict):
        gpus = [gpus]

    gpu_names: list[str] = []
    gpu_vrams: list[int | float] = []
    for gpu in gpus:
        name = gpu.get("Name")
        if name is not None:
            gpu_names.append(name)
        parsed_vram = parse_bytes_to_gb(gpu.get("AdapterRAM"))
        if parsed_vram is not None:
            gpu_vrams.append(parsed_vram)

    vram = None
    if gpu_vrams:
        max_value = max(float(value) for value in gpu_vrams)
        if max_value.is_integer():
            vram = int(max_value)
        else:
            vram = round(max_value, 1)

    return {
        "eval_device_label": payload.get("label"),
        "eval_device_cpu": payload.get("cpu"),
        "eval_device_gpu": join_or_none(gpu_names),
        "eval_device_memory_gb": parse_bytes_to_gb(payload.get("memory_bytes")),
        "eval_device_vram_gb": vram,
    }


def detect_linux_device_info() -> dict:
    label = None
    cpu = None
    gpu = None
    memory_gb = None
    vram_gb = None

    model_path = pathlib.Path("/sys/devices/virtual/dmi/id/product_name")
    if model_path.exists():
        content = model_path.read_text(encoding="utf-8").strip()
        if content:
            label = content

    lscpu_stdout = run_command(["lscpu"])
    if lscpu_stdout is not None:
        for line in lscpu_stdout.splitlines():
            if not line.startswith("Model name:"):
                continue
            cpu = line.split(":", 1)[1].strip()
            break

    lspci_stdout = run_command(["lspci"])
    if lspci_stdout is not None:
        gpu_lines = []
        for line in lspci_stdout.splitlines():
            lowered = line.lower()
            if "vga compatible controller" in lowered or "3d controller" in lowered:
                gpu_lines.append(line.split(": ", 1)[-1].strip())
        gpu = join_or_none(gpu_lines)

    meminfo_path = pathlib.Path("/proc/meminfo")
    if meminfo_path.exists():
        for line in meminfo_path.read_text(encoding="utf-8").splitlines():
            if not line.startswith("MemTotal:"):
                continue
            memory_gb = parse_gb_value(line.split(":", 1)[1].strip().replace("kB", " KB"))
            break

    nvidia_smi_stdout = run_command(
        [
            "nvidia-smi",
            "--query-gpu=memory.total",
            "--format=csv,noheader,nounits",
        ]
    )
    if nvidia_smi_stdout is not None:
        values = []
        for line in nvidia_smi_stdout.splitlines():
            parsed = parse_gb_value(f"{line.strip()} MB")
            if parsed is not None:
                values.append(parsed)
        if values:
            max_value = max(float(value) for value in values)
            if max_value.is_integer():
                vram_gb = int(max_value)
            else:
                vram_gb = round(max_value, 1)

    return {
        "eval_device_label": label,
        "eval_device_cpu": cpu,
        "eval_device_gpu": gpu,
        "eval_device_memory_gb": memory_gb,
        "eval_device_vram_gb": vram_gb,
    }


def detect_device_info_auto() -> dict:
    system_name = platform.system()
    if system_name == "Darwin":
        return detect_macos_device_info()
    if system_name == "Windows":
        return detect_windows_device_info()
    if system_name == "Linux":
        return detect_linux_device_info()
    return {key: None for key in DEVICE_INFO_KEYS}


def pick_device_value(
    cli_value: str | int | float | None,
    existing_value: str | int | float | None,
    detected_value: str | int | float | None,
) -> str | int | float | None:
    if cli_value is not None:
        return cli_value
    if existing_value is not None:
        return existing_value
    return detected_value


def resolve_device_info(args: argparse.Namespace, existing_payload: dict | None) -> dict:
    detected = detect_device_info_auto()

    existing = {}
    if existing_payload is not None:
        for key in DEVICE_INFO_KEYS:
            existing[key] = existing_payload.get(key)

    return {
        "eval_device_label": pick_device_value(
            args.eval_device_label,
            existing.get("eval_device_label"),
            detected.get("eval_device_label"),
        ),
        "eval_device_cpu": pick_device_value(
            args.eval_device_cpu,
            existing.get("eval_device_cpu"),
            detected.get("eval_device_cpu"),
        ),
        "eval_device_gpu": pick_device_value(
            args.eval_device_gpu,
            existing.get("eval_device_gpu"),
            detected.get("eval_device_gpu"),
        ),
        "eval_device_memory_gb": pick_device_value(
            parse_gb_value(args.eval_device_memory_gb),
            existing.get("eval_device_memory_gb"),
            detected.get("eval_device_memory_gb"),
        ),
        "eval_device_vram_gb": pick_device_value(
            parse_gb_value(args.eval_device_vram_gb),
            existing.get("eval_device_vram_gb"),
            detected.get("eval_device_vram_gb"),
        ),
    }


def apply_device_info(target: dict, device_info: dict) -> None:
    for key in DEVICE_INFO_KEYS:
        target[key] = device_info.get(key)


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


def flatten_prebuilt_items(source_path: pathlib.Path) -> list[dict]:
    payload = json.loads(source_path.read_text(encoding="utf-8"))
    flattened: list[dict] = []

    for category_index, category in enumerate(payload):
        category_key = category["category"]
        category_display_name = category["display_name"]
        for item_index, item in enumerate(category["items"]):
            flattened.append(
                {
                    "category": category_key,
                    "category_display_name": category_display_name,
                    "category_index": category_index,
                    "item_index": item_index,
                    "rendering_name": item["rendering_name"],
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


def build_category_stats(samples: list[dict]) -> list[dict]:
    category_map: dict[str, dict] = {}

    for sample in samples:
        category = sample["source_category"]
        existing = category_map.get(category)
        if existing is None:
            existing = {
                "category": category,
                "display_name": sample["source_category_display_name"],
                "total_samples": 0,
                "completed_samples": 0,
                "running_samples": 0,
                "partial_samples": 0,
                "error_samples": 0,
                "pending_samples": 0,
                "done_attempts": 0,
                "total_attempts": 0,
            }
            category_map[category] = existing

        existing["total_samples"] += 1
        existing["done_attempts"] += sample["repeat_count_done"]
        existing["total_attempts"] += sample["repeat_count_target"]

        status = sample["status"]
        if status == "completed":
            existing["completed_samples"] += 1
            continue
        if status == "running":
            existing["running_samples"] += 1
            continue
        if status == "partial":
            existing["partial_samples"] += 1
            continue
        if status == "error":
            existing["error_samples"] += 1
            continue
        existing["pending_samples"] += 1

    return list(category_map.values())


def build_generation_summary(run_payload: dict, samples: list[dict]) -> dict:
    category_stats = build_category_stats(samples)
    completed_samples = sum(1 for sample in samples if sample["status"] == "completed")
    running_samples = sum(1 for sample in samples if sample["status"] == "running")
    partial_samples = sum(1 for sample in samples if sample["status"] == "partial")
    error_samples = sum(1 for sample in samples if sample["status"] == "error")
    pending_samples = sum(1 for sample in samples if sample["status"] == "pending")
    completed_attempts = 0
    error_attempts = 0

    for sample in samples:
        for attempt in sample["attempts"]:
            if attempt["status"] == "completed":
                completed_attempts += 1
                continue
            if attempt["status"] == "error":
                error_attempts += 1

    latest_completed_samples = [
        sample for sample in samples if sample["status"] == "completed"
    ]
    latest_completed_sample_index = None
    latest_completed_category = None
    if latest_completed_samples:
        latest_completed_sample = latest_completed_samples[-1]
        latest_completed_sample_index = latest_completed_sample["sample_index"]
        latest_completed_category = latest_completed_sample["source_category"]

    return {
        "run_id": run_payload["run_id"],
        "status": run_payload["status"],
        "created_at": run_payload["created_at"],
        "updated_at": utc_now_iso(),
        "base_url": run_payload["base_url"],
        "endpoint": run_payload["endpoint"],
        "task_type": run_payload["task_type"],
        "language": run_payload["language"],
        "source_file": run_payload["source_file"],
        "model_request": run_payload["model_request"],
        "model_name_reported_by_server": run_payload["model_name_reported_by_server"],
        "eval_device_label": run_payload["eval_device_label"],
        "eval_device_cpu": run_payload["eval_device_cpu"],
        "eval_device_gpu": run_payload["eval_device_gpu"],
        "eval_device_memory_gb": run_payload["eval_device_memory_gb"],
        "eval_device_vram_gb": run_payload["eval_device_vram_gb"],
        "selection_mode": run_payload["selection_mode"],
        "source_total_items": run_payload["source_total_items"],
        "sample_count_requested": run_payload["sample_count_requested"],
        "repeat_count": run_payload["repeat_count"],
        "max_tokens": run_payload["max_tokens"],
        "total_categories": len(category_stats),
        "total_samples": run_payload["total_samples"],
        "completed_samples": completed_samples,
        "running_samples": running_samples,
        "partial_samples": partial_samples,
        "error_samples": error_samples,
        "pending_samples": pending_samples,
        "done_attempts": run_payload["done_attempts"],
        "total_attempts": run_payload["total_attempts"],
        "attempt_stats": {
            "completed_attempts": completed_attempts,
            "error_attempts": error_attempts,
        },
        "latest_completed_sample_index": latest_completed_sample_index,
        "latest_completed_category": latest_completed_category,
        "category_stats": category_stats,
    }


def update_run_state(
    manifest_path: pathlib.Path,
    generation_summary_path: pathlib.Path,
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
    generation_summary = build_generation_summary(run_payload, samples)
    atomic_write_json(generation_summary_path, generation_summary)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source-file",
        default=str(DEFAULT_SOURCE_FILE),
    )
    parser.add_argument("--language", default="zh")
    parser.add_argument("--sample-count", type=int, default=0)
    parser.add_argument("--repeat-count", type=int, default=5)
    parser.add_argument("--max-tokens", type=int, default=4000)
    parser.add_argument("--seed", type=int, default=20260324)
    parser.add_argument(
        "--selection-mode",
        choices=["random", "sequential"],
        default="sequential",
    )
    parser.add_argument("--timeout-seconds", type=int, default=900)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--eval-device-label")
    parser.add_argument("--eval-device-cpu")
    parser.add_argument("--eval-device-gpu")
    parser.add_argument("--eval-device-memory-gb")
    parser.add_argument("--eval-device-vram-gb")
    parser.add_argument("--resume-run-dir")
    parser.add_argument("--retry-from-index", type=int, default=1)
    parser.add_argument(
        "--reset-statuses",
        default="",
        help="Comma-separated sample statuses to reset when resuming, e.g. running,partial,error",
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
        generation_summary_path = run_dir / "generation_summary.json"
        manifest_payload = json.loads(manifest_path.read_text(encoding="utf-8"))
        device_info = resolve_device_info(args, manifest_payload)
        apply_device_info(manifest_payload, device_info)
        samples = []

        for path in sorted(samples_dir.glob(f"*_{args.language}_chat.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            apply_device_info(data, device_info)
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
            current_path = find_existing_sample_path(
                samples_dir,
                sample["sample_index"],
                args.language,
            )
            if current_path is None:
                continue

            pending_path = samples_dir / build_sample_filename(
                sample["sample_index"],
                args.language,
                "pending",
            )
            if current_path != pending_path:
                current_path.replace(pending_path)
            atomic_write_json(pending_path, sample)

        for sample in samples:
            current_path = find_existing_sample_path(
                samples_dir,
                sample["sample_index"],
                args.language,
            )
            if current_path is None:
                continue
            atomic_write_json(current_path, sample)
    else:
        server_status = get_json(f"{args.base_url}/v1/server/status", timeout_s=10)
        model_name = server_status.get("models", ["unknown-model"])[0]
        model_slug = sanitize_for_name(model_name)[:80]
        timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H%M%S")
        device_info = resolve_device_info(args, None)
        flattened = flatten_prebuilt_items(source_path)
        sample_count = args.sample_count
        if sample_count <= 0 or sample_count > len(flattened):
            sample_count = len(flattened)

        if args.selection_mode == "random":
            random_generator = random.Random(args.seed)
            selected = random_generator.sample(flattened, sample_count)
        else:
            selected = flattened[:sample_count]

        run_id = f"{timestamp}_{model_slug}"
        run_dir = out_root / run_id
        samples_dir = run_dir / "samples"
        manifest_path = run_dir / "manifest.json"
        generation_summary_path = run_dir / "generation_summary.json"

        samples = []
        for sample_index, item in enumerate(selected, start=1):
            samples.append(
                {
                    "run_id": run_id,
                    "language": args.language,
                    "task_type": "chat",
                    "status": "pending",
                    "sample_index": sample_index,
                    "rendering_name": item["rendering_name"],
                    "prompt": item["prompt"],
                    "source_file": str(source_path),
                    "source_category": item["category"],
                    "source_category_display_name": item["category_display_name"],
                    "source_category_index": item["category_index"],
                    "source_item_index": item["item_index"],
                    "base_url": args.base_url,
                    "endpoint": f"{args.base_url}/v1/chat/completions",
                    "model_request": "rwkv",
                    "model_name_reported_by_server": model_name,
                    "eval_device_label": device_info["eval_device_label"],
                    "eval_device_cpu": device_info["eval_device_cpu"],
                    "eval_device_gpu": device_info["eval_device_gpu"],
                    "eval_device_memory_gb": device_info["eval_device_memory_gb"],
                    "eval_device_vram_gb": device_info["eval_device_vram_gb"],
                    "max_tokens": args.max_tokens,
                    "repeat_count_target": args.repeat_count,
                    "repeat_count_done": 0,
                    "started_at": None,
                    "updated_at": utc_now_iso(),
                    "attempts": [],
                }
            )

        manifest_payload = {
            "run_id": run_id,
            "status": "pending",
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
            "base_url": args.base_url,
            "endpoint": f"{args.base_url}/v1/chat/completions",
            "task_type": "chat",
            "language": args.language,
            "source_file": str(source_path),
            "model_request": "rwkv",
            "model_name_reported_by_server": model_name,
            "eval_device_label": device_info["eval_device_label"],
            "eval_device_cpu": device_info["eval_device_cpu"],
            "eval_device_gpu": device_info["eval_device_gpu"],
            "eval_device_memory_gb": device_info["eval_device_memory_gb"],
            "eval_device_vram_gb": device_info["eval_device_vram_gb"],
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
            "generation_summary_path": str(generation_summary_path),
        }

        update_run_state(
            manifest_path=manifest_path,
            generation_summary_path=generation_summary_path,
            run_payload=manifest_payload,
            samples=samples,
        )

        for sample in samples:
            current_path = samples_dir / build_sample_filename(
                sample["sample_index"],
                args.language,
                sample["status"],
            )
            atomic_write_json(current_path, sample)

    if args.resume_run_dir:
        manifest_payload["updated_at"] = utc_now_iso()
        generation_summary_path = run_dir / "generation_summary.json"
        update_run_state(
            manifest_path=manifest_path,
            generation_summary_path=generation_summary_path,
            run_payload=manifest_payload,
            samples=samples,
        )

    for sample in samples:
        if sample["repeat_count_done"] >= sample["repeat_count_target"]:
            sample["status"] = finalize_sample_status(sample)
            update_run_state(
                manifest_path=manifest_path,
                generation_summary_path=generation_summary_path,
                run_payload=manifest_payload,
                samples=samples,
            )
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
        update_run_state(
            manifest_path=manifest_path,
            generation_summary_path=generation_summary_path,
            run_payload=manifest_payload,
            samples=samples,
        )

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
            update_run_state(
                manifest_path=manifest_path,
                generation_summary_path=generation_summary_path,
                run_payload=manifest_payload,
                samples=samples,
            )

        sample["status"] = finalize_sample_status(sample)
        sample["updated_at"] = utc_now_iso()
        final_path = samples_dir / build_sample_filename(
            sample["sample_index"],
            args.language,
            sample["status"],
        )
        running_path.replace(final_path)
        atomic_write_json(final_path, sample)
        update_run_state(
            manifest_path=manifest_path,
            generation_summary_path=generation_summary_path,
            run_payload=manifest_payload,
            samples=samples,
        )

    print(run_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
