#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-rwkv-fec94}"
TEST_TARGET="${TEST_TARGET:-integration_test/firebase_test_lab_engine_smoke_test.dart}"
MODEL_URL="${MODEL_URL:-}"
MODEL_PATH="${MODEL_PATH:-}"
MODEL_FILE_NAME="${MODEL_FILE_NAME:-}"
MODEL_SHA256="${MODEL_SHA256:-}"
BACKEND="${BACKEND:-llamacpp}"
MAX_TOKENS="${MAX_TOKENS:-4}"
PROMPT="${PROMPT:-Hello, RWKV}"
DOWNLOAD_TIMEOUT_MINUTES="${DOWNLOAD_TIMEOUT_MINUTES:-35}"
DOWNLOAD_RETRY_COUNT="${DOWNLOAD_RETRY_COUNT:-8}"
LOAD_TIMEOUT_MINUTES="${LOAD_TIMEOUT_MINUTES:-20}"
GENERATION_TIMEOUT_SECONDS="${GENERATION_TIMEOUT_SECONDS:-90}"
TIMEOUT="${TIMEOUT:-45m}"
RESULTS_DIR="${RESULTS_DIR:-rwkv-engine-smoke-$(date +%Y%m%d-%H%M%S)}"
DEVICE_FILE="${DEVICE_FILE:-}"
DEVICES="${DEVICES:-}"
DEVICE_COUNT="${DEVICE_COUNT:-5}"
DEVICE_FILTER="${DEVICE_FILTER:-form=PHYSICAL}"
DEVICE_MIN_VERSION="${DEVICE_MIN_VERSION:-29}"
DEVICE_PREFERRED_MAKES="${DEVICE_PREFERRED_MAKES:-Vivo,OnePlus,Xiaomi,Oppo,Huawei,Samsung,Google}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -z "$MODEL_URL" && -z "$MODEL_PATH" ]]; then
  echo "Set MODEL_URL for network download, or MODEL_PATH for a file already present on the device."
  echo "Example:"
  echo "  MODEL_URL=https://example.com/model.gguf DEVICES='model=oriole,version=33,locale=en,orientation=portrait' $0"
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud is not installed or not available in PATH."
  echo "Install Google Cloud CLI, then run: gcloud auth login && gcloud config set project $PROJECT_ID"
  exit 1
fi

if [[ "$DEVICES" == *"<"* || "$DEVICES" == *">"* ]]; then
  echo "DEVICES still contains a placeholder. Remove DEVICES to auto-pick devices, or use real Firebase model ids."
  exit 1
fi

if [[ -z "$DEVICES" && -z "$DEVICE_FILE" && ! "$DEVICE_COUNT" =~ ^[0-9]+$ ]]; then
  echo "DEVICE_COUNT must be a positive integer."
  exit 1
fi

if [[ -z "$DEVICES" && -z "$DEVICE_FILE" && "$DEVICE_COUNT" -le 0 ]]; then
  echo "Set DEVICES, DEVICE_FILE, or DEVICE_COUNT greater than 0."
  exit 1
fi

encode_define() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

DART_DEFINES=(
  "$(encode_define "RWKV_TEST_MODEL_URL=$MODEL_URL")"
  "$(encode_define "RWKV_TEST_MODEL_PATH=$MODEL_PATH")"
  "$(encode_define "RWKV_TEST_MODEL_FILE_NAME=$MODEL_FILE_NAME")"
  "$(encode_define "RWKV_TEST_MODEL_SHA256=$MODEL_SHA256")"
  "$(encode_define "RWKV_TEST_BACKEND=$BACKEND")"
  "$(encode_define "RWKV_TEST_MAX_TOKENS=$MAX_TOKENS")"
  "$(encode_define "RWKV_TEST_PROMPT=$PROMPT")"
  "$(encode_define "RWKV_TEST_DOWNLOAD_TIMEOUT_MINUTES=$DOWNLOAD_TIMEOUT_MINUTES")"
  "$(encode_define "RWKV_TEST_DOWNLOAD_RETRY_COUNT=$DOWNLOAD_RETRY_COUNT")"
  "$(encode_define "RWKV_TEST_LOAD_TIMEOUT_MINUTES=$LOAD_TIMEOUT_MINUTES")"
  "$(encode_define "RWKV_TEST_GENERATION_TIMEOUT_SECONDS=$GENERATION_TIMEOUT_SECONDS")"
)
DART_DEFINES_CSV="$(IFS=,; echo "${DART_DEFINES[*]}")"

DEVICE_ARGS=()
if [[ -n "$DEVICE_FILE" ]]; then
  while IFS= read -r device; do
    [[ -z "$device" || "$device" =~ ^# ]] && continue
    DEVICE_ARGS+=(--device "$device")
  done < "$DEVICE_FILE"
fi

if [[ -n "$DEVICES" ]]; then
  IFS=';' read -r -a device_items <<< "$DEVICES"
  for device in "${device_items[@]}"; do
    [[ -z "$device" ]] && continue
    DEVICE_ARGS+=(--device "$device")
  done
fi

if [[ -z "$DEVICES" && -z "$DEVICE_FILE" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for automatic Firebase device selection."
    exit 1
  fi

  while IFS= read -r device; do
    [[ -z "$device" ]] && continue
    DEVICE_ARGS+=(--device "$device")
  done < <(
    python3 - "$PROJECT_ID" "$DEVICE_COUNT" "$DEVICE_FILTER" "$DEVICE_MIN_VERSION" "$DEVICE_PREFERRED_MAKES" <<'PY'
import json
import subprocess
import sys

project_id = sys.argv[1]
device_count = int(sys.argv[2])
device_filter = sys.argv[3]
min_version = int(sys.argv[4])
preferred_makes = [value.strip().lower() for value in sys.argv[5].split(",") if value.strip()]

proc = subprocess.run(
    [
        "gcloud",
        "firebase",
        "test",
        "android",
        "models",
        "list",
        "--project",
        project_id,
        "--filter",
        device_filter,
        "--format",
        "json",
    ],
    check=True,
    stdout=subprocess.PIPE,
    text=True,
)

models = json.loads(proc.stdout)

def get_value(model, *names):
    for name in names:
        if name in model:
            return model[name]
    return None

def version_number(value):
    try:
        return int(str(value))
    except ValueError:
        return -1

def has_arm64(model):
    supported_abis = get_value(model, "supportedAbis", "SUPPORTED_ABIS") or []
    if not supported_abis:
        return True
    return any("arm64-v8a" in str(value) for value in supported_abis)

def capacity_score(model, version):
    per_version_info = get_value(model, "perVersionInfo", "PER_VERSION_INFO") or []
    for item in per_version_info:
        if str(get_value(item, "versionId", "VERSION_ID")) != str(version):
            continue
        capacity = str(get_value(item, "deviceCapacity", "DEVICE_CAPACITY") or "")
        if capacity.endswith("HIGH"):
            return 3
        if capacity.endswith("MEDIUM"):
            return 2
        if capacity.endswith("LOW"):
            return 1
        if capacity.endswith("NONE"):
            return -1
    return 0

def make_key(model):
    raw = get_value(model, "brand", "BRAND", "manufacturer", "MANUFACTURER") or ""
    return str(raw).lower()

candidates = []
for model in models:
    form = str(get_value(model, "form", "FORM") or "").upper()
    if form and form != "PHYSICAL":
        continue
    if not has_arm64(model):
        continue

    versions = get_value(model, "supportedVersionIds", "SUPPORTED_VERSION_IDS", "OS_VERSION_IDS") or []
    versions = sorted([version_number(value) for value in versions if version_number(value) >= min_version], reverse=True)
    if not versions:
        continue

    version = versions[0]
    tags = [str(value).lower() for value in (get_value(model, "tags", "TAGS") or [])]
    if "deprecated" in tags or f"deprecated={version}" in tags or f"reduced_stability={version}" in tags:
        continue

    score = capacity_score(model, version)
    if score < 0:
        continue

    model_id = get_value(model, "id", "ID", "modelId", "MODEL_ID")
    if not model_id:
        continue

    brand = get_value(model, "brand", "BRAND", "manufacturer", "MANUFACTURER") or "Unknown"
    name = get_value(model, "name", "NAME", "modelName", "MODEL_NAME") or model_id
    preferred_rank = preferred_makes.index(make_key(model)) if make_key(model) in preferred_makes else len(preferred_makes)
    candidates.append(
        {
            "arg": f"model={model_id},version={version},locale=en,orientation=portrait",
            "brand": str(brand),
            "name": str(name),
            "score": score,
            "version": version,
            "preferred_rank": preferred_rank,
        }
    )

candidates.sort(key=lambda item: (item["preferred_rank"], -item["score"], -item["version"], item["name"]))

selected = []
used_brands = set()
for item in candidates:
    brand_key = item["brand"].lower()
    if brand_key in used_brands:
        continue
    selected.append(item)
    used_brands.add(brand_key)
    if len(selected) >= device_count:
        break

if len(selected) < device_count:
    selected_args = {item["arg"] for item in selected}
    for item in candidates:
        if item["arg"] in selected_args:
            continue
        selected.append(item)
        if len(selected) >= device_count:
            break

if len(selected) < device_count:
    print(f"Only found {len(selected)} eligible Firebase Test Lab physical devices.", file=sys.stderr)

for item in selected:
    print(f"Selected Firebase device: {item['brand']} {item['name']} ({item['arg']})", file=sys.stderr)
    print(item["arg"])
PY
  )
fi

cd "$ROOT_DIR"
flutter pub get

pushd android >/dev/null
./gradlew app:assembleDebug app:assembleAndroidTest \
  -Ptarget="$ROOT_DIR/$TEST_TARGET" \
  -Pdart-defines="$DART_DEFINES_CSV"
popd >/dev/null

gcloud --quiet config set project "$PROJECT_ID"
gcloud firebase test android run \
  --project "$PROJECT_ID" \
  --type instrumentation \
  --app "$ROOT_DIR/build/app/outputs/apk/debug/app-debug.apk" \
  --test "$ROOT_DIR/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" \
  --timeout "$TIMEOUT" \
  --results-dir "$RESULTS_DIR" \
  "${DEVICE_ARGS[@]}"
