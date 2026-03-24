# Eval Handoff Bundle

## Purpose

This folder is a handoff bundle for a new thread about the local evaluation workflow and any follow-up `APP_website` feature work based on the evaluation results

It includes:

- the current evaluation runner script
- helper API test script
- the prompt sources used for the evaluation
- the small earlier sample runs
- the current large sequential Chinese run snapshot
- notes and documentation about the workflow and scoring
- a status snapshot captured when this bundle was assembled

## Important Caveat

The large Chinese run was still active when this bundle was copied

That means:

- the copied run folder is a snapshot
- the live run outside this bundle may already have advanced further
- `STATUS_SNAPSHOT.json` reflects the state at copy time

## Main Entry Points

- `STATUS_SNAPSHOT.json`
- `docs/EVAL_NOTES.zh-hans.md`
- `remote/evals/docs.md`
- `remote/evals/2026-03-24_121809_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip_chat_zh_n240_r5_mt8000/manifest.json`

## Folder Layout

- `docs/`
  - eval notes and summary for product or frontend discussion
- `tools/`
  - evaluation runner and API test script
- `remote/prompts/`
  - prompt source files
- `remote/evals/`
  - evaluation run snapshots and eval docs

## Files Included

### Docs

- `docs/EVAL_NOTES.zh-hans.md`

### Tools

- `tools/run_local_chat_eval.py`
- `tools/test_openai_api.py`

### Prompt Sources

- `remote/prompts/chat_suggestions_zh.json`
- `remote/prompts/chat_suggestions_en.json`
- `remote/prompts/suggestions.json`

### Eval Docs

- `remote/evals/docs.md`

### Sample Eval Outputs

- `remote/chat_eval_sample_zh.json`
- `remote/chat_eval_sample_en.json`
- `remote/evals/2026-03-24_115734_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip_chat_zh_n5_r5_mt4000/`

### Main Large Run Snapshot

- `remote/evals/2026-03-24_121809_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip_chat_zh_n240_r5_mt8000/`

## Recommended Reading Order

1. Read `STATUS_SNAPSHOT.json`
2. Read `docs/EVAL_NOTES.zh-hans.md`
3. Open the large run `manifest.json`
4. Inspect `samples/` inside the large run folder
5. Read `tools/run_local_chat_eval.py` if continuation or repair logic matters

## Why This Bundle Exists

The goal is to let another thread discuss:

- what the evaluation is doing
- how the output files are structured
- what the first scored results suggest
- what `APP_website` should build on top of these results
