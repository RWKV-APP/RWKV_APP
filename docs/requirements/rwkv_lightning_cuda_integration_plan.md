# RWKV Lightning CUDA integration plan

## Purpose

目标是在 Windows 桌面版 Flutter application 中接入已经验证可用的 `rwkv_lighting_cuda.exe` 推理引擎，让 RakChat 可以通过本机 OpenAI-compatible HTTP API 使用这个 CUDA backend

核心结果

- Flutter application 能找到 Lightning CUDA runtime bundle
- Flutter application 能选择或复用用户指定的 `.pth` 权重文件
- Flutter application 能用正确 tokenizer 启动 `rwkv_lighting_cuda.exe`
- Flutter application 能维护 backend 进程状态、日志、端口和停止动作
- RakChat 能连接 `http://127.0.0.1:<port>/v1` 并调用 `/v1/chat/completions`
- 普通用户不需要手动设置 `PATH`

## Current verified facts

已验证机器

- OS: Windows 10 Pro 22H2, build 19045
- GPU: NVIDIA GeForce RTX 3080
- Driver: 576.57
- CUDA runtime used by bundle: 12.9
- Build arch: `sm_86`

已验证 backend bundle

```text
D:\repo\rwkv_lightning_cuda\build_win10_sm86\bundle\rwkv_lighting_cuda
```

bundle root contents

```text
rwkv_lighting_cuda
|-- lib
|-- rwkv_launcher.exe
|-- rwkv_lighting_cuda.exe
`-- rwkv_vocab_v20230424.txt
```

important sizes

```text
rwkv_lighting_cuda.exe: 2.80 MiB
rwkv_launcher.exe: 8.09 MiB
whole runtime bundle: 758.02 MiB
```

large DLLs in `lib`

```text
cublas64_12.dll
cublasLt64_12.dll
cudart64_12.dll
```

verified PTH

```text
E:\rwkv7-g1g-2.9b-20260526-ctx8192.pth
```

verified tokenizer in backend bundle

```text
D:\repo\rwkv_lightning_cuda\build_win10_sm86\bundle\rwkv_lighting_cuda\rwkv_vocab_v20230424.txt
```

same tokenizer already exists in the Flutter app assets

```text
D:\repo\rwkv_app\assets\config\chat\rwkv_vocab_v20230424.txt
```

verified direct start command

```powershell
cd D:\repo\rwkv_lightning_cuda\build_win10_sm86\bundle\rwkv_lighting_cuda
$env:PATH = "$PWD\lib;$env:PATH"
.\rwkv_lighting_cuda.exe --model-path E:\rwkv7-g1g-2.9b-20260526-ctx8192.pth --vocab-path .\rwkv_vocab_v20230424.txt --port 8000
```

verified model endpoint

```text
GET http://127.0.0.1:8000/v1/models
```

verified chat endpoint

```text
POST http://127.0.0.1:8000/v1/chat/completions
```

verified chat request

```json
{
  "model": "rwkv7-g1g-2.9b-20260526-ctx8192",
  "messages": [
    { "role": "system", "content": "You are a concise assistant." },
    { "role": "user", "content": "用一句中文回答：2+2等于几？" }
  ],
  "max_tokens": 16,
  "temperature": 0.2,
  "top_p": 0.8,
  "stream": false
}
```

verified response content

```text
2+2等于4。
```

RakChat connection target after backend starts

```text
Base URL: http://127.0.0.1:8000/v1
Model: rwkv7-g1g-2.9b-20260526-ctx8192
API Key: empty when backend has no --password
```

If backend starts with `--password <value>`, RakChat should use the same value as API key

## Current Flutter application facts

Flutter app root

```text
D:\repo\rwkv_app
```

The current app already has an internal RWKV runtime path

- `lib/store/rwkv_model.dart` loads chat models through `rwkv_mobile_flutter`
- `lib/store/rwkv_backend.dart` manages native runtime metadata and QNN helper libs
- `lib/store/pth.dart` discovers local `.pth` and `.gguf` model files
- `lib/func/local_model_discovery.dart` recognizes `.pth` and `.gguf`
- `lib/store/api_server.dart` exposes OpenAI-compatible HTTP routes backed by the currently loaded internal model

Important current behavior

- A local `.pth` file is recognized by `P.pth`
- Current `_fileInfoFromLocalModelFile` maps `.pth` to `Backend.webRwkv`
- Current `P.rwkvModel.loadChat` uses tokenizer from `assets/config/chat/rwkv_vocab_v20230424.txt`
- Current `P.apiServer` uses port `52345` by default and needs a model loaded inside Flutter
- Current `P.apiServer` already exposes `/v1/models`, `/v1/chat/completions`, and `/v1/completions`

New Lightning CUDA integration should be treated as a Windows external process runtime

It should not require replacing the existing `rwkv_mobile_flutter` load path in the first implementation

## Desired file and directory relationship

Development layout used by this investigation

```text
D:\repo
|-- rwkv_app
|   |-- assets\config\chat\rwkv_vocab_v20230424.txt
|   `-- docs\requirements\rwkv_lightning_cuda_integration_plan.md
|
`-- rwkv_lightning_cuda
    `-- build_win10_sm86\bundle\rwkv_lighting_cuda
        |-- lib
        |-- rwkv_lighting_cuda.exe
        |-- rwkv_launcher.exe
        `-- rwkv_vocab_v20230424.txt
```

Recommended app runtime layout after integration

```text
<RWKV_Chat.exe directory>
|-- RWKV_Chat.exe
|-- flutter_windows.dll
|-- data
|   `-- flutter_assets
`-- lightning_cuda
    |-- lib
    |-- rwkv_lighting_cuda.exe
    `-- rwkv_vocab_v20230424.txt
```

Recommended model location

```text
<user selected path>\rwkv7-g1g-2.9b-20260526-ctx8192.pth
```

Example verified model path

```text
E:\rwkv7-g1g-2.9b-20260526-ctx8192.pth
```

Do not assume the PTH file lives next to the app binary

The app should store the selected PTH path in preferences or reuse `P.pth` folder entries

## Runtime bundle contract

The Flutter app should treat this directory as the required Lightning CUDA bundle

```text
lightning_cuda
|-- lib
|   |-- brotlicommon.dll
|   |-- brotlidec.dll
|   |-- brotlienc.dll
|   |-- cares.dll
|   |-- cublas64_12.dll
|   |-- cublasLt64_12.dll
|   |-- cudart64_12.dll
|   |-- drogon.dll
|   |-- jsoncpp.dll
|   |-- libcrypto-3-x64.dll
|   |-- libssl-3-x64.dll
|   |-- msvcp140.dll
|   |-- sqlite3.dll
|   |-- trantor.dll
|   |-- vcruntime140.dll
|   |-- vcruntime140_1.dll
|   `-- zlib1.dll
|-- rwkv_lighting_cuda.exe
`-- rwkv_vocab_v20230424.txt
```

`rwkv_launcher.exe` is useful for manual testing, but Flutter should start `rwkv_lighting_cuda.exe` directly

Reason: Flutter needs process ownership, logs, status, readiness checks, and stop control

## Proposed Flutter architecture

Add a dedicated store module

```text
lib/store/lightning_cuda.dart
```

Because files under `lib/store` use `part of 'p.dart';`, the new store file should follow the existing store rules

- Add `part "lightning_cuda.dart";` to `lib/store/p.dart`
- Add `static final lightningCuda = _LightningCuda();` to `P`
- Do not add imports in `lib/store/lightning_cuda.dart`
- Put any needed imports in `lib/store/p.dart`

Suggested state

```text
bundleDir: String?
exePath: String?
libDir: String?
vocabPath: String?
modelPath: String?
port: int
password: String
useWkv32: bool
process: Process?
state: BackendState
logs: List<String>
baseUrl: String
lastError: String?
detectedModelId: String?
```

Suggested public methods

```text
detectBundle()
setBundleDir(String path)
setModelPath(String path)
start()
stop()
restart()
probeModels()
probeChatCompletion()
openRakChatConfigHint()
clearLogs()
```

State ownership

- `P.lightningCuda` owns the external process
- `P.pth` continues to own local model discovery
- `P.apiServer` continues to own the existing internal OpenAI-compatible server
- RakChat can connect directly to Lightning CUDA backend on `http://127.0.0.1:<port>/v1`

## Process start contract

Flutter should start the backend with `Process.start`

Working directory

```text
<bundleDir>
```

Executable

```text
<bundleDir>\rwkv_lighting_cuda.exe
```

Arguments

```text
--model-path <selected PTH path>
--vocab-path <bundleDir>\rwkv_vocab_v20230424.txt
--port <port>
```

Optional arguments

```text
--password <password>
--wkv32
```

Windows environment

```text
PATH=<bundleDir>\lib;<existing PATH>
```

Important details

- Keep inherited environment variables
- Prepend `lib` to `PATH`
- Use absolute paths for `model-path` and `vocab-path`
- Keep `workingDirectory` as bundle root so runtime files stay near the backend
- Capture stdout and stderr
- Limit log memory, for example last 2000 lines

Readiness check

Use both signals

- stdout contains `http://0.0.0.0:<port>/v1/models` or `Mamba Out`
- `GET http://127.0.0.1:<port>/v1/models` returns HTTP 200

Stop behavior

- Kill process on user stop
- Mark state as stopped after process exit
- Clear or keep runtime files based on product choice
- Runtime files include `rwkv_sessions.db` and `uploads`

## API contract used by RakChat

Models

```http
GET /v1/models
```

Chat completions

```http
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer <password if configured>
```

Request example

```json
{
  "model": "rwkv7-g1g-2.9b-20260526-ctx8192",
  "messages": [
    { "role": "system", "content": "You are a concise assistant." },
    { "role": "user", "content": "Hello" }
  ],
  "max_tokens": 128,
  "temperature": 0.8,
  "top_p": 0.8,
  "stream": false
}
```

Streaming should also be supported by the backend through `stream: true`

The first integration should verify both modes

## UI integration plan

Minimal UI surface

- Windows-only section named `Lightning CUDA`
- Bundle path display and re-detect button
- PTH model path selector
- Port input
- Password input
- WKV32 toggle
- Start button
- Stop button
- Status chip
- Log panel
- Copy RakChat base URL button

Possible locations

- `lib/page/api_server.dart` if the feature is framed as local OpenAI-compatible service
- `lib/page/weight_manager.dart` if the feature is framed as a model runtime action
- Settings page if it starts as an advanced Windows-only feature

Recommended first placement

```text
lib/page/api_server.dart
```

Reason: The main user-facing value is serving an OpenAI-compatible endpoint for RakChat

## Model selection plan

Reuse existing PTH discovery

- `P.pth.folders` already lists recognized `.pth` files
- `FileInfo.fromPthFile == true` identifies a local PTH
- `fileInfo.raw` contains the absolute model path

Add a new action for PTH files

```text
Start with Lightning CUDA
```

This action should set `P.lightningCuda.modelPath` and open or update the Lightning CUDA service panel

Do not route this action through `P.rwkvModel.startLocalModelForChat`

That method loads the model into `rwkv_mobile_flutter`, while Lightning CUDA owns its own process and memory

## Tokenizer plan

Preferred path for backend process

```text
<bundleDir>\rwkv_vocab_v20230424.txt
```

Reason: The backend can start without reading Flutter assets

Build or install process should copy this tokenizer from

```text
D:\repo\rwkv_app\assets\config\chat\rwkv_vocab_v20230424.txt
```

to

```text
<bundleDir>\rwkv_vocab_v20230424.txt
```

Startup validation should fail early if tokenizer is missing

Suggested validation message

```text
Missing rwkv_vocab_v20230424.txt in Lightning CUDA bundle
```

## Artifact packaging plan

Development phase

- Allow user or developer to point the app at an external bundle directory
- Verified external bundle is currently at `D:\repo\rwkv_lightning_cuda\build_win10_sm86\bundle\rwkv_lighting_cuda`
- Store selected bundle path in `SharedPreferences`

Packaged app phase

- Copy runtime bundle into app install directory as `lightning_cuda`
- Do not commit CUDA DLLs or generated binaries to the Flutter app repo
- Prefer CI artifact download, installer step, or release packaging step

Recommended package location

```text
<RWKV_Chat.exe directory>\lightning_cuda
```

Recommended source artifact name

```text
rwkv_lighting_cuda-win10-sm86-cuda12.9.zip
```

The package should include

- `rwkv_lighting_cuda.exe`
- `rwkv_vocab_v20230424.txt`
- `lib` directory with required DLLs

The package may exclude

- `rwkv_launcher.exe`
- CMake build files
- Visual Studio project files
- `rwkv_sessions.db`
- `uploads`

## Port and process policy

Default Lightning CUDA port

```text
8000
```

Existing Flutter `P.apiServer` default port

```text
52345
```

Avoid port collision by checking whether the chosen port is available before process start

If port is occupied, show the owner state in logs when possible and ask the user to pick another port

Do not silently switch port after RakChat configuration has been shown

## Error handling checklist

Validate before start

- Windows platform
- Bundle directory exists
- `rwkv_lighting_cuda.exe` exists
- `lib` directory exists
- CUDA DLLs exist
- tokenizer exists
- selected `.pth` exists
- port is valid

Runtime errors to surface

- process exited before readiness
- stderr contains `create weight copy stream failed`
- `/v1/models` timeout
- `/v1/chat/completions` timeout
- missing CUDA runtime DLL
- missing or invalid PTH file
- missing tokenizer file

Suggested log format

```text
[12:34:56] started: <command>
[12:34:57] stdout: <line>
[12:34:58] stderr: <line>
[12:34:59] backend exited: <exit code>
```

## Verification checklist for next implementation thread

Backend direct verification

```powershell
cd D:\repo\rwkv_lightning_cuda\build_win10_sm86\bundle\rwkv_lighting_cuda
$env:PATH = "$PWD\lib;$env:PATH"
.\rwkv_lighting_cuda.exe --model-path E:\rwkv7-g1g-2.9b-20260526-ctx8192.pth --vocab-path .\rwkv_vocab_v20230424.txt --port 8000
```

Models endpoint

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/v1/models
```

Chat endpoint

```powershell
$body = @{
  model = "rwkv7-g1g-2.9b-20260526-ctx8192"
  messages = @(
    @{ role = "system"; content = "You are a concise assistant." },
    @{ role = "user"; content = "用一句中文回答：2+2等于几？" }
  )
  max_tokens = 16
  temperature = 0.2
  top_p = 0.8
  stream = $false
} | ConvertTo-Json -Depth 8

Invoke-WebRequest -UseBasicParsing `
  -Uri http://127.0.0.1:8000/v1/chat/completions `
  -Method Post `
  -ContentType application/json `
  -Body $body
```

Expected result includes

```text
2+2等于4。
```

Flutter integration verification

- App detects bundle path
- App detects selected PTH path
- App starts backend without user setting `PATH`
- Status changes from stopped to starting to running
- Logs show model layers loading
- App probes `/v1/models`
- App probes `/v1/chat/completions`
- RakChat connects to `http://127.0.0.1:8000/v1`
- App stops backend
- No backend process remains after stop

## Recommended implementation sequence

1. Add `P.lightningCuda` store with process state and path validation
2. Add bundle detection for dev path and packaged app path
3. Add process start and stop with stdout and stderr log capture
4. Add `/v1/models` readiness probe
5. Add `/v1/chat/completions` smoke test method
6. Add Windows-only UI panel in API server page
7. Add PTH action from model selector or weight manager
8. Add SharedPreferences persistence for bundle path, model path, port, password, and WKV32
9. Add packaging notes or build script for copying the runtime bundle next to `RWKV_Chat.exe`
10. Run RakChat end-to-end test with non-stream and stream completions

## Main decision for the integration thread

Use Lightning CUDA as an external Windows runtime owned by the Flutter app

Flutter should launch and supervise `rwkv_lighting_cuda.exe`

RakChat should talk directly to the Lightning CUDA backend through its OpenAI-compatible API

The first version should keep `P.apiServer` and `rwkv_mobile_flutter` behavior intact
