<a id="SPEC-RWKV-ALBATROSS-API"></a>

# Albatross HTTP API Requirements for RWKV Chat

本文档描述 RWKV Chat 前端与 Albatross 后端进程之间的 HTTP 通讯协议需求

目标是让 Albatross binary 可以作为 RWKV Chat 在 Windows / Linux NVIDIA x86_64 环境下的本地推理后端，并尽量复用 RWKV Chat 已有的 OpenAI-compatible / SSE 流式接入逻辑

## 1. Scope

### 1.1 本版需要覆盖

- Chat 对话流式生成
- 文本续写流式生成
- batch 续写
- 当前模型和服务状态探测
- 停止当前生成
- token count 和生成速度指标

### 1.2 本版暂不覆盖

- TTS
- Sudoku / Othello / World
- Vision / OCR / 多模态
- ARM / AMD 后端
- int4 / int8 量化格式定义
- App 直接管理模型下载源

### 1.3 命名约定

- 本文档统一使用 `Albatross`
- 微信文件名里的 `Abatross` 按拼写错误处理
- `RWKV Chat` 指当前 Flutter 前端 App
- `Albatross` 指本地 HTTP 推理服务进程

## 2. Design Principles

- 前端每次请求发送完整可见历史，后端可以自行做 prefix / state cache
- 前端历史可能被编辑，也可能存在分支对话，后端不能只依赖隐式 session 顺序
- P0 接口先保证可用的流式 UI 体验
- P1 接口用于把体验追平现有本地引擎
- P2 接口属于后续性能和状态复用增强
- API 返回结构尽量兼容 OpenAI-style `chat.completions` 和 SSE chunk

## 3. Priority Overview

| Priority | Capability | Required |
| --- | --- | --- |
| P0 | service status | yes |
| P0 | model list | yes |
| P0 | chat streaming | yes |
| P0 | batch completion streaming | yes |
| P1 | stop active request | yes after P0 |
| P1 | token count | yes after P0 |
| P1 | prefill / decode metrics | yes after P0 |
| P2 | session id optimization | optional |
| P2 | precise pause / resume | optional |
| P2 | state save / load | optional |
| P2 | model load / unload from App | optional |

## 4. P0 API

### 4.1 `GET /v1/server/status`

Used by RWKV Chat to detect whether the local Albatross backend is running and which features it supports

#### Response

```json
{
  "status": "running",
  "api_version": "1.0",
  "engine_version": "albatross-1.0.0",
  "model": {
    "id": "rwkv7-7.2b",
    "name": "RWKV-7 7.2B",
    "path": "/path/to/model.pth"
  },
  "capabilities": {
    "chat_messages": true,
    "completion": true,
    "batch_completion": true,
    "stream": true,
    "stop": true,
    "token_count": false,
    "metrics": true,
    "session_cache": false
  },
  "active_request": null
}
```

#### Field requirements

- `status`: `running` / `loading` / `error`
- `api_version`: HTTP API contract version
- `engine_version`: Albatross binary or backend version
- `model`: current loaded model, or `null` if no model is ready
- `capabilities`: feature flags used by RWKV Chat
- `active_request`: current active generation metadata, or `null`

### 4.2 `GET /v1/models`

OpenAI-compatible model list

#### Response

```json
{
  "object": "list",
  "data": [
    {
      "id": "rwkv7-7.2b",
      "object": "model",
      "created": 1760000000,
      "owned_by": "rwkv"
    }
  ]
}
```

### 4.3 `POST /v1/chat/completions`

Primary chat endpoint

RWKV Chat prefers this endpoint for normal conversation because it preserves structured roles and avoids frontend-specific prompt templates

#### Request

```json
{
  "model": "rwkv7-7.2b",
  "messages": [
    {
      "role": "system",
      "content": "You are RWKV Chat."
    },
    {
      "role": "user",
      "content": "你好"
    }
  ],
  "stream": true,
  "max_tokens": 1024,
  "temperature": 1.0,
  "top_k": 5,
  "top_p": 0.3,
  "alpha_presence": 0.2,
  "alpha_frequency": 0.2,
  "alpha_decay": 0.99,
  "stop_tokens": [0, 261, 24281],
  "chunk_size": 1,
  "password": "optional"
}
```

#### Required behavior

- `messages` must be accepted as structured chat history
- `stream: true` must return SSE
- `choices[].delta.content` must be incremental text
- Response must finish with `data: [DONE]\n\n`
- Non-streaming mode may be implemented later, but streaming is required for RWKV Chat UI
- If `system` is unsupported internally, backend should convert it into its own prompt prefix

#### Streaming response

```text
data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1760000000,"model":"rwkv7-7.2b","choices":[{"index":0,"delta":{"content":"你"},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1760000000,"model":"rwkv7-7.2b","choices":[{"index":0,"delta":{"content":"好"},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","created":1760000000,"model":"rwkv7-7.2b","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}

data: [DONE]
```

### 4.4 `POST /v1/batch/completions`

Batch text continuation endpoint

Alic already provided a working example for this endpoint. RWKV Chat can use it for batch completion and parallel candidate generation

#### Request

```json
{
  "contents": [
    "English: Protecting the Fragile Environment of Antarctica\n\nChinese:",
    "English: Antarctica is the southernmost continent on Earth.\n\nChinese:"
  ],
  "stream": true,
  "max_tokens": 1024,
  "temperature": 1.0,
  "top_k": 5,
  "top_p": 0.3,
  "alpha_presence": 0.2,
  "alpha_frequency": 0.2,
  "alpha_decay": 0.99,
  "stop_tokens": [0, 261, 24281],
  "chunk_size": 1,
  "password": "optional"
}
```

#### Required behavior

- `contents.length` is the batch size
- Each `contents[index]` is one independent continuation slot
- SSE must use `choices[].index` to identify which slot receives the delta
- `choices[].delta.content` must be incremental text
- A slot can finish earlier than other slots
- Stream must finish with one final `data: [DONE]\n\n`

#### Streaming response

```text
data: {"choices":[{"index":0,"delta":{"content":"保"}}],"object":"chat.completion.chunk"}

data: {"choices":[{"index":1,"delta":{"content":"南"}}],"object":"chat.completion.chunk"}

data: {"choices":[{"index":0,"delta":{},"finish_reason":"stop"},{"index":1,"delta":{},"finish_reason":"stop"}],"object":"chat.completion.chunk"}

data: [DONE]
```

## 5. Common Request Parameters

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `stream` | boolean | yes for RWKV Chat | `true` returns SSE |
| `max_tokens` | integer | yes | max generated tokens |
| `temperature` | number | yes | sampling temperature |
| `top_k` | integer | yes | top-k sampling |
| `top_p` | number | yes | nucleus sampling |
| `alpha_presence` | number | yes | presence penalty |
| `alpha_frequency` | number | yes | frequency penalty |
| `alpha_decay` | number | yes | penalty decay |
| `stop_tokens` | integer array | yes | EOS / stop token IDs |
| `chunk_size` | integer | yes | number of tokens per SSE chunk |
| `password` | string | optional | keep compatible with current Albatross example |

Parameter names should stay stable. If backend has different internal names, please map them inside Albatross

## 6. Context Rules

### 6.1 Chat history

RWKV Chat sends only the current visible branch of conversation

Example:

```json
{
  "messages": [
    {"role": "system", "content": "You are RWKV Chat."},
    {"role": "user", "content": "第一轮问题"},
    {"role": "assistant", "content": "第一轮回答"},
    {"role": "user", "content": "第二轮问题"}
  ]
}
```

### 6.2 Edited messages and branches

RWKV Chat supports editing previous messages and branching from an older message

Therefore:

- backend must treat each request as complete input truth
- backend may cache prefix states internally
- backend must not require the frontend to preserve a single linear session
- backend must not append hidden historical content that is absent from the current request

### 6.3 Thinking content

RWKV Chat does not send prior internal thinking content back into the next request

If a previous assistant message contains:

```text
<think>internal reasoning</think>
final answer
```

The next request should only include:

```text
final answer
```

### 6.4 Fallback prompt template

If Alic wants to expose only a continuation endpoint, he needs to provide an exact stable prompt template

The template must define:

- how to render `system`
- how to render `user`
- how to render `assistant`
- whether to add a generation prompt suffix
- how to trim blank lines
- how to handle multilingual content
- how to handle thinking tags

RWKV Chat prefers structured `messages`, because prompt template drift is easy to miss in UI testing

## 7. P1 API

### 7.1 `POST /v1/server/stop`

Stop the currently active generation

#### Response

```json
{
  "ok": true,
  "stopped": true,
  "active_request": null
}
```

#### Required behavior

- If no request is active, return `ok: true` and `stopped: false`
- After stop, the next generation request must work normally
- Streaming clients should still receive a final stop chunk and `[DONE]` when possible

### 7.2 `POST /v1/tokens/count`

Count tokens for text or messages

#### Raw text request

```json
{
  "text": "你好，RWKV"
}
```

#### Messages request

```json
{
  "messages": [
    {"role": "user", "content": "你好"}
  ]
}
```

#### Response

```json
{
  "tokens": 5
}
```

### 7.3 Metrics

Backend should expose generation metrics through either status response or stream chunks

Preferred fields:

```json
{
  "prefill_speed": 1200.5,
  "decode_speed": 62.4,
  "prefill_progress": 0.85
}
```

Units:

- `prefill_speed`: tokens per second
- `decode_speed`: tokens per second
- `prefill_progress`: `0.0` to `1.0`

## 8. P2 API

P2 is optional for the first integration

### 8.1 `session_id` optimization

Backend may return a `session_id` for optimized state reuse

RWKV Chat can use it only if the backend also supports:

- branch reset
- edited history invalidation
- explicit session disposal
- fallback to full-history request

Full-history request remains the compatibility baseline

### 8.2 Precise pause / resume

Precise pause / resume can be added later if backend can preserve:

- latest generated text
- latest token count
- state after stop
- resume request identity

Until then, RWKV Chat can use stop plus full-history retry

### 8.3 State save / load

Optional future endpoints:

- `POST /v1/state/save`
- `POST /v1/state/load`
- `POST /v1/state/delete`

These are not required for the first usable integration

### 8.4 App-managed model lifecycle

Optional future endpoints:

- `POST /v1/models/load`
- `POST /v1/models/unload`
- `POST /v1/models/switch`

The first version may keep model loading fully inside the Albatross binary startup flow

## 9. Error Format

All non-2xx responses should be JSON

```json
{
  "error": {
    "message": "No model loaded",
    "type": "model_not_found",
    "code": "model_not_loaded"
  }
}
```

Recommended HTTP status codes:

| Status | Meaning |
| --- | --- |
| 400 | invalid request body or unsupported parameter |
| 401 | password required or invalid |
| 404 | endpoint not found |
| 409 | another generation is active and queueing is disabled |
| 500 | internal backend error |
| 503 | model not loaded or service not ready |

## 10. Acceptance Tests

### 10.1 Status

```bash
curl http://127.0.0.1:9527/v1/server/status
```

Expected:

- HTTP 200
- JSON body
- `status` is `running`
- `capabilities.stream` is `true`

### 10.2 Models

```bash
curl http://127.0.0.1:9527/v1/models
```

Expected:

- HTTP 200
- `object` is `list`
- at least one model exists after backend startup

### 10.3 Chat streaming

```bash
curl -N http://127.0.0.1:9527/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "rwkv7-7.2b",
    "messages": [
      {"role": "user", "content": "请用一句话介绍 RWKV"}
    ],
    "stream": true,
    "max_tokens": 128,
    "temperature": 1.0,
    "top_k": 5,
    "top_p": 0.3,
    "alpha_presence": 0.2,
    "alpha_frequency": 0.2,
    "alpha_decay": 0.99,
    "stop_tokens": [0, 261, 24281],
    "chunk_size": 1
  }'
```

Expected:

- response starts quickly after prefill
- chunks are SSE
- each delta is incremental
- stream ends with `[DONE]`

### 10.4 Batch completion streaming

```bash
curl -N http://127.0.0.1:9527/v1/batch/completions \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [
      "English: Hello\n\nChinese:",
      "English: Good morning\n\nChinese:",
      "English: Thank you\n\nChinese:",
      "English: See you tomorrow\n\nChinese:"
    ],
    "stream": true,
    "max_tokens": 64,
    "temperature": 1.0,
    "top_k": 5,
    "top_p": 0.3,
    "alpha_presence": 0.2,
    "alpha_frequency": 0.2,
    "alpha_decay": 0.99,
    "stop_tokens": [0, 261, 24281],
    "chunk_size": 1
  }'
```

Expected:

- `choices[].index` is always within `0..contents.length-1`
- all active slots receive final stop information
- response ends with `[DONE]`

### 10.5 Stop

1. Start a long streaming request
2. Call `POST /v1/server/stop`
3. Start a new streaming request

Expected:

- first request stops
- frontend state does not hang
- second request works normally

### 10.6 Edited history

1. Send a two-turn conversation
2. Edit the first user message
3. Send the full edited history again

Expected:

- backend answers according to the edited history
- backend does not reuse removed branch content

### 10.7 Error cases

Verify:

- no model loaded returns 503 with JSON error
- invalid JSON returns 400 with JSON error
- wrong password returns 401 with JSON error
- unsupported endpoint returns 404 with JSON error

## 11. Current Alic Example

Alic's current example proves the basic batch continuation shape

```bash
curl -X POST 'http://127.0.0.1:9527/v1/batch/completions' \
  --header 'Content-Type: application/json' \
  --data '{
    "contents": [
      "English: Protecting the Fragile Environment of Antarctica\n\nChinese:",
      "English: Antarctica, the southernmost continent on Earth, stands as one of the last remaining regions where large-scale human settlement has not taken root.\n\nChinese:"
    ],
    "max_tokens": 1024,
    "temperature": 1.0,
    "top_k": 5,
    "top_p": 0.3,
    "alpha_presence": 0.2,
    "alpha_frequency": 0.2,
    "alpha_decay": 0.99,
    "stop_tokens": [0, 261, 24281],
    "stream": true,
    "chunk_size": 1,
    "password": "rwkv7_7.2b"
  }'
```

This example should stay compatible, but the final integration should use the P0 / P1 API contract above as the source of truth
