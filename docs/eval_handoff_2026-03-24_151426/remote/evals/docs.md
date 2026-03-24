# Local Eval Layout

This directory stores long-running local evaluation runs for the OpenAI-compatible server

## Goals

- Keep each prompt isolated in its own file
- Make progress visible from both filenames and file contents
- Allow interrupted runs to be inspected or resumed later
- Separate raw generation from later scoring

## Directory Shape

Each run lives under its own folder

```text
remote/evals/<run_id>/
  manifest.json
  samples/
    0001_pending_zh_chat.json
    0001_running_zh_chat.json
    0001_completed_zh_chat.json
```

Only one status version should exist for a given sample at a time

## Filename Contract

Sample filenames follow this format

```text
<sample_index>_<status>_<language>_chat.json
```

Example

```text
0003_completed_zh_chat.json
```

This means:

- `0003`: the third selected prompt in the run
- `completed`: all requested attempts for this prompt finished successfully
- `zh`: Simplified Chinese prompt source
- `chat`: `/v1/chat/completions`

## Sample File Contract

Each sample file must include:

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
  "display": "...",
  "prompt": "...",
  "source_file": "...",
  "source_category_name": "...",
  "source_category_index": 0,
  "source_item_index": 14,
  "endpoint": "http://localhost:8080/v1/chat/completions",
  "model_request": "rwkv",
  "model_name_reported_by_server": "...",
  "max_tokens": 4000,
  "repeat_count_target": 5,
  "repeat_count_done": 2,
  "score_status": "pending",
  "started_at": "...",
  "updated_at": "...",
  "attempts": []
}
```

Each attempt entry should include:

- `attempt`
- `status`
- `started_at`
- `ended_at`
- `duration_ms`
- `response_chars`
- `response`
- `score`
- `score_note`

If generation fails, keep the attempt entry and write:

- `error_type`
- `error_message`
- `error_body` when available

## Manifest Contract

`manifest.json` is the run-level checkpoint

It records:

- run metadata
- model and endpoint
- requested sample count and repeat count
- current sample counters
- current attempt counters
- the path to the sample directory

Important counters:

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

- Prefer `4000` before `8000` for broad batch runs on local Mac hardware
- Use a fixed random seed so prompt selection is reproducible
- Write raw generation first and add scoring in a second pass
- Never rely on one giant output file for long runs

## Selection Modes

The runner supports:

- `random`: randomly sample prompts from the source file
- `sequential`: take prompts in source order from top to bottom

For long benchmark runs, prefer `sequential` so interruption and continuation are easier to reason about

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
- current progress remains visible through both `manifest.json` and sample filenames

If a run was interrupted and later samples were marked `partial` or `error`, you can reset them in place and continue from a specific sample index

Example:

```text
python3 tools/run_local_chat_eval.py \
  --resume-run-dir remote/evals/<run_id> \
  --language zh \
  --retry-from-index 24 \
  --reset-statuses partial,error
```
