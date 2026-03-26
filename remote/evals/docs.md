# Local Eval Layout

This directory stores long-running local generation runs for the RWKV OpenAI-compatible server

## Goals

- Use the current prebuilt prompt asset as the single evaluation input
- Keep each prompt isolated in its own file
- Make progress visible from both filenames and JSON summaries
- Allow interrupted runs to be resumed later
- Separate raw generation from later scoring and ranking

## Input Source

The runner now reads:

`docs/requirements/prompt/prebuilt-prompt-zh-hans.json`

This file is the current Simplified Chinese prebuilt prompt asset for RWKV Chat

The runner flattens it in source order:

1. top-level category order
2. item order inside each category

## Directory Shape

Each run lives under its own folder

```text
remote/evals/<run_id>/
  manifest.json
  generation_summary.json
  samples/
    0001_pending_zh_chat.json
    0001_running_zh_chat.json
    0001_completed_zh_chat.json
```

Only one status version should exist for a given sample at a time

## Run ID

Run directories now use:

```text
<timestamp>_<model_slug>
```

Example:

```text
2026-03-25_143000_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip
```

This keeps the run human-readable while still unique enough for local use

## Filename Contract

Sample filenames follow this format:

```text
<sample_index>_<status>_<language>_chat.json
```

Example:

```text
0003_completed_zh_chat.json
```

This means:

- `0003`: the third selected prompt in the run
- `completed`: all requested attempts for this prompt finished successfully
- `zh`: Simplified Chinese prompt source
- `chat`: `/v1/chat/completions`

## Sample File Contract

Each sample file includes:

- run identity
- source prompt identity
- current progress state
- generation settings
- all finished attempts so far

Core fields:

```json
{
  "run_id": "...",
  "language": "zh",
  "task_type": "chat",
  "status": "running",
  "sample_index": 1,
  "rendering_name": "...",
  "prompt": "...",
  "source_file": "...",
  "source_category": "life",
  "source_category_display_name": "日常生活",
  "source_category_index": 0,
  "source_item_index": 14,
  "base_url": "http://localhost:8080",
  "endpoint": "http://localhost:8080/v1/chat/completions",
  "model_request": "rwkv",
  "model_name_reported_by_server": "...",
  "eval_device_label": "MacBook Pro 16-inch",
  "eval_device_cpu": "Apple M4 Pro",
  "eval_device_gpu": "Apple M4 Pro",
  "eval_device_memory_gb": 48,
  "eval_device_vram_gb": null,
  "max_tokens": 4000,
  "repeat_count_target": 5,
  "repeat_count_done": 2,
  "started_at": "...",
  "updated_at": "...",
  "attempts": []
}
```

Device fields:

- `eval_device_label`: human-readable device label
- `eval_device_cpu`: human-readable CPU or SoC name
- `eval_device_gpu`: human-readable GPU name
- `eval_device_memory_gb`: system memory in GB
- `eval_device_vram_gb`: VRAM in GB, or `null` when unavailable

Each attempt entry includes:

- `attempt`
- `status`
- `started_at`
- `ended_at`
- `duration_ms`
- `response_chars`
- `response`

If generation fails, the attempt keeps:

- `error_type`
- `error_message`
- `error_body` when available

This runner no longer writes scoring fields into attempts

## Manifest Contract

`manifest.json` is the run-level checkpoint

It records:

- run metadata
- source file and model info
- device information
- requested sample count and repeat count
- current sample counters
- current attempt counters
- the path to the sample directory
- the path to `generation_summary.json`

Important counters:

- `completed_samples`
- `running_samples`
- `partial_samples`
- `error_samples`
- `pending_samples`
- `done_attempts`
- `total_attempts`

`manifest.json` is now generation-only and no longer contains scoring progress

## Generation Summary Contract

`generation_summary.json` is the machine-readable run summary for generation progress

It includes:

- run identity
- source file and model info
- device information
- total category count
- total sample count
- attempt totals
- current run status
- `latest_completed_sample_index`
- `latest_completed_category`
- `category_stats`

Each category stat includes:

- `category`
- `display_name`
- `total_samples`
- `completed_samples`
- `running_samples`
- `partial_samples`
- `error_samples`
- `pending_samples`
- `done_attempts`
- `total_attempts`

## Status Semantics

- `pending`: file created but attempts have not started
- `running`: at least one attempt is in progress for this sample
- `completed`: all attempts finished successfully
- `partial`: some attempts succeeded and some failed
- `error`: all attempts failed

## Operational Notes

- The current runner is generation-only
- GPT scoring, weighted aggregation, and final ranking should be added in a later pass
- Prefer `4000` before `8000` for broad local batch runs unless the prompt type clearly needs more output
- For large benchmark runs, prefer `sequential`
- Never rely on one giant output file for long runs

## Selection Modes

The runner supports:

- `sequential`: take prompts in source order from top to bottom
- `random`: randomly sample prompts from the source file

The default is now `sequential`

## Resume Mode

The runner can continue an unfinished run by pointing to the existing run directory

Example:

```text
python3 tools/run_local_chat_eval.py \
  --resume-run-dir remote/evals/<run_id> \
  --language zh
```

Resume behavior:

- completed samples are skipped
- unfinished samples continue from the next missing attempt
- current progress remains visible through `manifest.json`, `generation_summary.json`, and sample filenames

If a run was interrupted and later samples were marked `running`, `partial`, or `error`, you can reset them in place and continue from a specific sample index

Example:

```text
python3 tools/run_local_chat_eval.py \
  --resume-run-dir remote/evals/<run_id> \
  --language zh \
  --retry-from-index 24 \
  --reset-statuses running,partial,error
```
