#!/usr/bin/env python3

"""
Score completed generation samples using a judge LLM via SiliconFlow API.

This scorer reads completed sample files from a generation run directory,
sends each attempt to a judge model for multi-dimension evaluation, and
writes score files into a scores/ subdirectory.

It does NOT modify the original generation files.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import random
import re
import sys
import tempfile
import time
import urllib.error
import urllib.request

DEFAULT_API_BASE = "https://api.siliconflow.cn/v1/chat/completions"
DEFAULT_MODEL = "Qwen/Qwen3.5-122B-A10B"

WEIGHTS = {
    "relevance": 0.20,
    "quality": 0.35,
    "fluency": 0.15,
    "satisfaction": 0.30,
}

SCORER_SYSTEM_PROMPT = """\
你是一个专业的 AI 回答质量评估专家。你的任务是评估一个本地小模型对用户问题的回答质量。

请从以下 4 个维度评分，每个维度满分 10 分（整数）：

1. 切题度 (relevance)：回答是否紧扣问题，不跑题、不答非所问
2. 内容质量 (quality)：回答的实质内容是否有价值——事实类看准确性，建议类看实用性，创作类看趣味性，代码类看可执行性
3. 表达流畅度 (fluency)：语言是否通顺自然、结构清晰、无明显重复/断裂/乱码
4. 用户满意度 (satisfaction)：综合印象——如果你是提出这个问题的真实用户，看到这个回答会满意吗

评分要求：
- 每个维度给出整数分（1-10）
- 给出一段 30-50 字的简评，概括回答的优缺点
- 严格按以下 JSON 格式输出，不要输出任何其他内容

```json
{
  "relevance": 分数,
  "quality": 分数,
  "fluency": 分数,
  "satisfaction": 分数,
  "brief_note": "30-50字简评"
}
```"""


def build_user_message(question: str, response: str) -> str:
    return f"【用户问题】\n{question}\n\n【模型回答】\n{response}"


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


def call_judge_api(
    question: str,
    response: str,
    api_base: str,
    model: str,
    api_key: str,
) -> dict:
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": SCORER_SYSTEM_PROMPT},
            {"role": "user", "content": build_user_message(question, response)},
        ],
        "temperature": 0.1,
        "max_tokens": 1024,
    }

    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        api_base,
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )

    max_retries = 3
    for attempt_num in range(max_retries):
        try:
            with urllib.request.urlopen(request, timeout=120) as resp:
                result = json.loads(resp.read().decode("utf-8"))
            content = result["choices"][0]["message"]["content"]
            return parse_score_json(content)
        except urllib.error.HTTPError as e:
            error_body = ""
            try:
                error_body = e.read().decode("utf-8")
            except Exception:
                pass
            if e.code == 429 or e.code >= 500:
                wait = (attempt_num + 1) * 5
                print(f"    HTTP {e.code}, retrying in {wait}s... {error_body[:200]}")
                time.sleep(wait)
                continue
            raise RuntimeError(
                f"Judge API error HTTP {e.code}: {error_body[:500]}"
            ) from e
        except urllib.error.URLError as e:
            if attempt_num < max_retries - 1:
                wait = (attempt_num + 1) * 5
                print(f"    Connection error, retrying in {wait}s... {e}")
                time.sleep(wait)
                continue
            raise

    raise RuntimeError("Judge API failed after all retries")


def parse_score_json(raw: str) -> dict:
    json_match = re.search(r"\{[^{}]*\}", raw, re.DOTALL)
    if json_match is None:
        raise ValueError(f"No JSON found in judge response: {raw[:300]}")

    parsed = json.loads(json_match.group())

    scores = {}
    for key in ("relevance", "quality", "fluency", "satisfaction"):
        value = parsed.get(key)
        if value is None:
            raise ValueError(f"Missing key '{key}' in judge response")
        scores[key] = int(value)

    brief_note = parsed.get("brief_note", "")

    weighted_score = round(
        sum(scores[k] * WEIGHTS[k] for k in WEIGHTS),
        2,
    )

    return {
        "scores": scores,
        "weighted_score": weighted_score,
        "brief_note": brief_note,
    }


def find_completed_samples(run_dir: pathlib.Path) -> list[pathlib.Path]:
    samples_dir = run_dir / "samples"
    if not samples_dir.is_dir():
        print(f"Error: samples directory not found: {samples_dir}")
        sys.exit(1)

    paths = sorted(samples_dir.glob("*_completed_*.json"))
    return paths


def load_existing_score(score_path: pathlib.Path) -> dict | None:
    if not score_path.exists():
        return None
    with open(score_path, encoding="utf-8") as f:
        return json.load(f)


def score_sample(
    sample_path: pathlib.Path,
    scores_dir: pathlib.Path,
    api_base: str,
    model: str,
    api_key: str,
) -> None:
    with open(sample_path, encoding="utf-8") as f:
        sample = json.load(f)

    sample_index = sample["sample_index"]
    rendering_name = sample["rendering_name"]
    prompt = sample["prompt"]
    source_category = sample["source_category"]
    attempts = sample.get("attempts", [])

    score_filename = f"{sample_index:04d}_score.json"
    score_path = scores_dir / score_filename

    existing = load_existing_score(score_path)
    existing_evals = {}
    if existing is not None:
        for ev in existing.get("attempt_evals", []):
            existing_evals[ev["attempt"]] = ev

    attempt_evals = []
    for att in attempts:
        att_num = att["attempt"]
        if att["status"] != "completed":
            continue

        if att_num in existing_evals:
            attempt_evals.append(existing_evals[att_num])
            continue

        response_text = att.get("response", "")
        if not response_text:
            continue

        print(f"  Scoring attempt {att_num}...")
        try:
            result = call_judge_api(prompt, response_text, api_base, model, api_key)
            eval_entry = {"attempt": att_num, **result}
            attempt_evals.append(eval_entry)
        except Exception as e:
            print(f"    Error scoring attempt {att_num}: {e}")
            continue

        time.sleep(0.5)

    attempt_evals.sort(key=lambda x: x["attempt"])

    score_data = {
        "sample_index": sample_index,
        "rendering_name": rendering_name,
        "prompt": prompt,
        "source_category": source_category,
        "attempt_evals": attempt_evals,
    }

    atomic_write_json(score_path, score_data)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Score completed generation samples using a judge LLM"
    )
    parser.add_argument(
        "--run-dir",
        required=True,
        help="Path to the generation run directory",
    )
    parser.add_argument(
        "--sample-count",
        type=int,
        default=0,
        help="Number of samples to score (0 = all)",
    )
    parser.add_argument(
        "--random",
        action="store_true",
        help="Randomly select samples instead of sequential",
    )
    parser.add_argument(
        "--api-base",
        default=DEFAULT_API_BASE,
        help=f"Judge API endpoint (default: {DEFAULT_API_BASE})",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Judge model name (default: {DEFAULT_MODEL})",
    )

    args = parser.parse_args()

    api_key = os.environ.get("SILICONFLOW_API_KEY", "")
    if not api_key:
        print("Error: SILICONFLOW_API_KEY environment variable is not set")
        sys.exit(1)

    run_dir = pathlib.Path(args.run_dir)
    if not run_dir.is_dir():
        print(f"Error: run directory not found: {run_dir}")
        sys.exit(1)

    scores_dir = run_dir / "scores"
    scores_dir.mkdir(exist_ok=True)

    all_samples = find_completed_samples(run_dir)
    print(f"Found {len(all_samples)} completed samples")

    if args.sample_count > 0:
        if args.random:
            selected = random.sample(
                all_samples, min(args.sample_count, len(all_samples))
            )
        else:
            selected = all_samples[: args.sample_count]
    else:
        selected = all_samples

    print(f"Will score {len(selected)} samples using {args.model}")
    print(f"Scores will be written to: {scores_dir}")
    print()

    scored = 0
    errors = 0
    for i, sample_path in enumerate(selected, 1):
        sample_name = sample_path.stem
        print(f"[{i}/{len(selected)}] {sample_name}")

        try:
            score_sample(sample_path, scores_dir, args.api_base, args.model, api_key)
            scored += 1
        except Exception as e:
            print(f"  Failed: {e}")
            errors += 1

    print()
    print(f"Done. Scored: {scored}, Errors: {errors}")
    print(f"Score files: {scores_dir}")


if __name__ == "__main__":
    main()
