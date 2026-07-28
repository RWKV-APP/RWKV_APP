<a id="SPEC-RWKV-AGENTIC-EVAL"></a>

# Agentic Evaluation Specification v0.1

Scoring schema version: 2

## Scope

This specification evaluates whether a model can select tools, produce valid arguments, use tool results, obey task constraints, verify changes, and report truthful final outcomes in the RWKV App Agent runtime

It does not evaluate unrestricted computer use, Terminal operation, external network research, long-running workflow recovery, or production API integrations

## Unit of evaluation

One case run consists of:

1. An exact system prompt and user prompt
2. A declared deterministic tool schema
3. An isolated initial environment
4. Zero or more model generations and tool exchanges
5. A deterministic case scorer

The maximum turn count is case-specific. A run ends as completed, submitted, cancelled, maximum-turns reached, model-failed, or infrastructure-failed

## Reproducibility contract

Every report must include:

- Schema version
- Benchmark ID, version, case count, and SHA-256
- Run ID, start time, completion time, mode, selected case names, planned run count, and repetition count
- App version, build number, build mode, and source revision
- Device and operating-system metadata
- Model name, file name, size, quantization or precision, backend, source revision when available, and model-hash verification status
- Seed and sampler values
- Raw and effective output for every model generation
- Stop reason and generation duration
- Tool calls, arguments, tool results, and errors
- Host interventions
- Per-case strict result, assisted result, validity, failure codes, and duration

Reports are append-safe at case granularity. A crash may lose the active case, but must retain every previously completed case

App runs use seed 42, temperature 0.2, top-k 500, top-p 0, zero presence and frequency penalties, and penalty decay 0.99. The App validates this deterministic sampler before starting native generation and restores the previous sampler and seed after each case

## Model identity

Agentic Evaluation must never read a model file to calculate or validate its SHA-256. This applies to App runs, reference runs, comparisons, and delivery gates

An already available catalog or operator supplied hash may be copied into a report without reading the model file only when the same model record marks `sha256Verified` as `false`. When no hash was supplied, the report records `not_provided`. A model hash is metadata only and must not be required to start a run, determine validity, compare scores, or qualify a delivery

## Strict protocol

A strict tool call:

- Contains an opening and closing `tool_call` tag
- Contains exactly one valid JSON object
- Contains only `name` and `arguments` at the top level
- Uses a non-empty string name
- Uses an object for arguments
- Uses string argument keys
- Conforms to the advertised tool schema without host coercion or dropped fields

Tool-call transport continuation may request the remaining text after an opening tag. The combined model output must still satisfy the strict protocol

## Host intervention taxonomy

Score-changing interventions:

- JSON repair
- JSON container completion
- Fenced-JSON extraction
- Trailing-text extraction
- Envelope normalization
- Argument type coercion
- Dropped arguments
- Repeated-thought truncation
- Repeated-text truncation
- Generation-budget stop
- Forced tool call

Audited non-score-changing interventions:

- Tool-call transport continuation
- Schema guidance returned as a tool error

Strict success requires task success, a valid infrastructure run, and zero score-changing interventions. Assisted success requires task success and a valid infrastructure run

## Infrastructure validity

The host must bind generation control to the active chat model ID. It must confirm idle state before generation and after stop or completion. Stop and status timeouts are infrastructure failures

The App must subscribe before starting native generation. Response-buffer content is eligible only when it belongs to the active chat model and an Agent-owned polling request. Content retained from an earlier generation must not count as fresh model output

If no fresh model output arrives within 20 seconds after generation starts, the App must stop the active model, report a `first_token_timeout` infrastructure failure, and keep the run out of model scoring

Cancelled, infrastructure-failed, and incomplete persisted runs cannot be used as model scores. A comparison must report their count separately

Invalid runs retain the reason they became invalid but do not receive task-specific capability failures from incomplete work. They count only under invalid runs and are excluded from pass and failure totals

## Aggregate reporting

Required aggregates:

- Strict passes and strict pass rate
- Assisted passes and assisted pass rate
- Failures
- Invalid runs
- Per-case outcome
- Failure-code counts
- Intervention counts

When repetitions are greater than one, retain each attempt independently. Do not average away invalid attempts or replace failed attempts with later successes

## Comparison rules

Only compare reports when benchmark ID, benchmark version, benchmark SHA-256, scoring schema version, prompts, and tool implementation are identical

Quantization comparisons should use the same declared model revision and operational identity fields. An unverified supplied hash may be shown as metadata but cannot establish equivalence. BF16 or FP16 is the reference point; device quantization results are deployment measurements

Any change to cases, parser strictness, tool behavior, or scoring creates a new benchmark or schema version
