#!/usr/bin/env bash

set -euo pipefail

echo "retired: the legacy rwkv_harmony plus rwkv_mobile Windows transfer workflow must not be executed; use rwkv_harmony_standalone and the active rwkv-mobile checkout" >&2
exit 64

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_ROOT="$(cd "${APP_ROOT}/.." && pwd)"
MOBILE_ROOT="${WORKSPACE_ROOT}/rwkv_mobile"
MOBILE_FLUTTER_ROOT="${WORKSPACE_ROOT}/rwkv_mobile_flutter"
HARMONY_ROOT="${WORKSPACE_ROOT}/rwkv_harmony"
WEBSITE_ROOT="${WORKSPACE_ROOT}/app_website"
TEMPLATE_ROOT="${SCRIPT_DIR}/windows_transfer"
CAPTURE_DATE="${RWKV_TRANSFER_DATE:-$(date '+%Y-%m-%d')}"
DEFAULT_OUTPUT="${HOME}/Desktop/RWKV-Harmony-Windows-Transfer-${CAPTURE_DATE}"
OUTPUT="${1:-${DEFAULT_OUTPUT}}"
OUTPUT_PARENT="$(cd "$(dirname "${OUTPUT}")" && pwd)"
OUTPUT_NAME="$(basename "${OUTPUT}")"
OUTER_ZIP="${OUTPUT}.zip"
OUTER_ZIP_HASH="${OUTER_ZIP}.sha256"
KIRIN_MODEL="${RWKV_KIRIN_MODEL:-}"
TOKENIZER="${RWKV_TOKENIZER:-}"
KNOWN_GOOD_HAP="${RWKV_KNOWN_GOOD_HAP:-${HARMONY_ROOT}/entry/build/default/outputs/default/entry-default-signed.hap}"

for required in \
    "${APP_ROOT}" \
    "${MOBILE_ROOT}" \
    "${MOBILE_FLUTTER_ROOT}" \
    "${HARMONY_ROOT}" \
    "${WEBSITE_ROOT}" \
    "${TEMPLATE_ROOT}"; do
    if [[ ! -d "${required}" ]]; then
        echo "required directory is missing: ${required}" >&2
        exit 1
    fi
done

for command_name in git python3 rsync shasum tar zip; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "required command is missing: ${command_name}" >&2
        exit 1
    fi
done

if [[ -e "${OUTPUT}" || -e "${OUTER_ZIP}" || -e "${OUTER_ZIP_HASH}" ]]; then
    echo "transfer output already exists: ${OUTPUT}" >&2
    exit 1
fi

TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/rwkv-windows-transfer.XXXXXX")"
PARTIAL_OUTPUT="${OUTPUT}.partial.$$"

cleanup() {
    rm -rf "${TEMP_ROOT}"
    if [[ -d "${PARTIAL_OUTPUT}" ]]; then
        rm -rf "${PARTIAL_OUTPUT}"
    fi
}
trap cleanup EXIT

mkdir -p "${PARTIAL_OUTPUT}/archives"

is_forbidden_transfer_path() {
    local relative_path="$1"
    local lower_path
    lower_path="$(printf '%s' "${relative_path}" | tr '[:upper:]' '[:lower:]')"
    case "${lower_path}" in
        .env|*/.env|.env.*|*/.env.*|*.p12|*.pfx|*.jks|*.keystore|*.pem|*.key|*.p7b|*.mobileprovision|*/key.properties|*/local.properties|sentry.properties|*/sentry.properties|.npmrc|*/.npmrc|.pypirc|*/.pypirc|.netrc|*/.netrc|credentials.json|*/credentials.json|service-account*.json|*/service-account*.json|google-services.json|*/google-services.json|id_rsa|*/id_rsa|id_ed25519|*/id_ed25519)
            if [[ "${lower_path}" == *.example ]]; then
                return 1
            fi
            return 0
            ;;
    esac
    return 1
}

copy_untracked_files() {
    local repository="$1"
    local final_snapshot="$2"
    local untracked_snapshot="$3"
    local state_directory="$4"
    local relative_path

    mkdir -p "${untracked_snapshot}"
    git -C "${repository}" ls-files --others --exclude-standard -z > "${state_directory}/untracked-files.z"
    while IFS= read -r -d '' relative_path; do
        if is_forbidden_transfer_path "${relative_path}"; then
            echo "refusing to package forbidden untracked path: ${relative_path}" >&2
            exit 1
        fi
        if [[ ! -e "${repository}/${relative_path}" && ! -L "${repository}/${relative_path}" ]]; then
            echo "untracked path disappeared during packaging: ${relative_path}" >&2
            exit 1
        fi
        mkdir -p \
            "${final_snapshot}/$(dirname "${relative_path}")" \
            "${untracked_snapshot}/$(dirname "${relative_path}")"
        cp -pP "${repository}/${relative_path}" "${final_snapshot}/${relative_path}"
        cp -pP "${repository}/${relative_path}" "${untracked_snapshot}/${relative_path}"
    done < "${state_directory}/untracked-files.z"
}

create_git_snapshot() {
    local name="$1"
    local repository="$2"
    local code_root="$3"
    local source_directory="${code_root}/sources/${name}"
    local state_directory="${code_root}/state/${name}"
    local after_fingerprint
    local before_fingerprint
    local origin_url

    if ! git -C "${repository}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "not a Git repository: ${repository}" >&2
        exit 1
    fi

    before_fingerprint="$(
        python3 "${TEMPLATE_ROOT}/git_state_fingerprint.py" "${repository}"
    )"
    mkdir -p "${source_directory}" "${state_directory}/untracked"
    git -C "${repository}" archive --format=tar HEAD | tar -xf - -C "${source_directory}"
    git -C "${repository}" rev-parse HEAD > "${state_directory}/base-head.txt"
    git -C "${repository}" branch --show-current > "${state_directory}/branch.txt"
    git -C "${repository}" status --porcelain=v1 --branch > "${state_directory}/status.txt"
    git -C "${repository}" status --porcelain=v1 > "${state_directory}/status.files.txt"
    git -C "${repository}" status --porcelain=v1 -z > "${state_directory}/status.porcelain.z"
    git -C "${repository}" diff --cached --binary --full-index --no-ext-diff > "${state_directory}/staged.patch"
    git -C "${repository}" diff --binary --full-index --no-ext-diff > "${state_directory}/unstaged.patch"

    origin_url="$(git -C "${repository}" remote get-url origin 2>/dev/null || true)"
    if [[ ! "${origin_url}" =~ ^https://[A-Za-z0-9.-]+/[A-Za-z0-9._~/-]+$ ]] &&
        [[ ! "${origin_url}" =~ ^git@[A-Za-z0-9.-]+:[A-Za-z0-9._~/-]+$ ]]; then
        origin_url="[REDACTED]"
    fi
    printf '%s\n' "${origin_url}" > "${state_directory}/origin-url.txt"

    if [[ -s "${state_directory}/staged.patch" ]]; then
        (
            cd "${code_root}"
            git apply \
                --binary \
                --unsafe-paths \
                --directory="sources/${name}" \
                "state/${name}/staged.patch"
        )
    fi
    if [[ -s "${state_directory}/unstaged.patch" ]]; then
        (
            cd "${code_root}"
            git apply \
                --binary \
                --unsafe-paths \
                --directory="sources/${name}" \
                "state/${name}/unstaged.patch"
        )
    fi

    copy_untracked_files \
        "${repository}" \
        "${source_directory}" \
        "${state_directory}/untracked" \
        "${state_directory}"

    after_fingerprint="$(
        python3 "${TEMPLATE_ROOT}/git_state_fingerprint.py" "${repository}"
    )"
    if [[ "${before_fingerprint}" != "${after_fingerprint}" ]]; then
        echo "repository changed while packaging: ${repository}" >&2
        exit 1
    fi
    printf '%s\n' "${before_fingerprint}" > "${state_directory}/state-fingerprint.txt"
}

copy_harmony_snapshot() {
    local code_root="$1"
    local destination="${code_root}/sources/rwkv_harmony"

    mkdir -p "${destination}"
    rsync -a \
        --exclude '/local.properties' \
        --exclude '/build' \
        --exclude '/entry/build' \
        --exclude '/entry/.cxx' \
        --exclude '/entry/oh_modules' \
        --exclude '/.hvigor' \
        --exclude '/.idea' \
        --exclude '/.archive' \
        --exclude '/node_modules' \
        --exclude '/oh_modules' \
        --exclude '**/__pycache__' \
        --exclude '*.pyc' \
        --exclude '.DS_Store' \
        --exclude '._*' \
        --exclude '*.hap' \
        --exclude '*.hsp' \
        --exclude '*.p12' \
        --exclude '*.pfx' \
        --exclude '*.jks' \
        --exclude '*.keystore' \
        --exclude '*.pem' \
        --exclude '*.key' \
        --exclude '*.p7b' \
        "${HARMONY_ROOT}/" \
        "${destination}/"

    if [[ -d "${HARMONY_ROOT}/build/golden" ]]; then
        mkdir -p "${destination}/build/golden"
        rsync -a "${HARMONY_ROOT}/build/golden/" "${destination}/build/golden/"
    fi
    python3 "${TEMPLATE_ROOT}/sanitize_json_paths.py" \
        "${destination}/tools/results" \
        "${destination}/build/golden"

    if [[ -d "${HARMONY_ROOT}/build/deps" ]]; then
        mkdir -p "${code_root}/offline-deps"
        rsync -a \
            --exclude '.git' \
            --exclude '*/.git' \
            --exclude '.DS_Store' \
            "${HARMONY_ROOT}/build/deps/" \
            "${code_root}/offline-deps/"
    fi

    mkdir -p "${code_root}/evidence/device"
    for evidence_file in \
        "${HARMONY_ROOT}/build/nnrt-quant-probe-kirin9020.log" \
        "${HARMONY_ROOT}/build/final-kirin-quant-layout.json" \
        "${HARMONY_ROOT}/build/kirin-final-generation-hilog.txt" \
        "${HARMONY_ROOT}/build/kirin-final-generation.json" \
        "${HARMONY_ROOT}/build/device-logs/20260711-1718-current.log" \
        "${HARMONY_ROOT}/build/kirin-final-selftest-hilog.txt"; do
        if [[ -f "${evidence_file}" ]]; then
            cp -p "${evidence_file}" "${code_root}/evidence/device/"
        fi
    done
}

materialize_windows_agent_pointer() {
    local pointer="$1"
    if [[ ! -L "${pointer}" ]]; then
        return
    fi
    rm "${pointer}"
    printf '../AGENTS.md\n' > "${pointer}"
}

verify_exact_asset() {
    local path="$1"
    local expected_size="$2"
    local expected_hash="$3"
    local label="$4"
    local actual_size
    local actual_hash

    if [[ ! -f "${path}" ]]; then
        echo "${label} is missing: ${path}" >&2
        exit 1
    fi
    actual_size="$(stat -f '%z' "${path}")"
    if [[ "${actual_size}" != "${expected_size}" ]]; then
        echo "${label} size mismatch: ${actual_size}" >&2
        exit 1
    fi
    actual_hash="$(shasum -a 256 "${path}" | awk '{print $1}')"
    if [[ "${actual_hash}" != "${expected_hash}" ]]; then
        echo "${label} SHA-256 mismatch: ${actual_hash}" >&2
        exit 1
    fi
}

zip_and_verify() {
    local staging_parent="$1"
    local root_name="$2"
    local archive="$3"

    (
        cd "${staging_parent}"
        zip -q -r -X "${archive}" "${root_name}"
    )
    python3 "${TEMPLATE_ROOT}/verify_transfer_archive.py" "${archive}"
}

CODE_PARENT="${TEMP_ROOT}/code"
CODE_ROOT="${CODE_PARENT}/rwkv-transfer-code"
mkdir -p "${CODE_ROOT}"

create_git_snapshot "rwkv_app" "${APP_ROOT}" "${CODE_ROOT}"
create_git_snapshot "rwkv_mobile" "${MOBILE_ROOT}" "${CODE_ROOT}"
create_git_snapshot "rwkv_mobile_flutter" "${MOBILE_FLUTTER_ROOT}" "${CODE_ROOT}"
create_git_snapshot "app_website" "${WEBSITE_ROOT}" "${CODE_ROOT}"
copy_harmony_snapshot "${CODE_ROOT}"
materialize_windows_agent_pointer "${CODE_ROOT}/sources/rwkv_app/.github/copilot-instructions.md"

cp -p "${TEMPLATE_ROOT}/START_HERE_WINDOWS.md" "${CODE_ROOT}/"
cp -p "${TEMPLATE_ROOT}/VERIFY_CODE_WINDOWS.ps1" "${CODE_ROOT}/"
cp -p "${TEMPLATE_ROOT}/RESTORE_WORKSPACES.ps1" "${CODE_ROOT}/"
cp -p "${TEMPLATE_ROOT}/OPTIONAL_ASSETS.md" "${CODE_ROOT}/"

python3 "${TEMPLATE_ROOT}/audit_transfer_tree.py" \
    "${CODE_ROOT}" \
    --machine-home "${HOME}"
python3 "${TEMPLATE_ROOT}/create_sha256_manifest.py" "${CODE_ROOT}"
zip_and_verify \
    "${CODE_PARENT}" \
    "$(basename "${CODE_ROOT}")" \
    "${PARTIAL_OUTPUT}/archives/rwkv-harmony-windows-code.zip"

if [[ -z "${KIRIN_MODEL}" || -z "${TOKENIZER}" ]]; then
    echo "RWKV_KIRIN_MODEL and RWKV_TOKENIZER must point to verified model assets" >&2
    exit 1
fi

verify_exact_asset \
    "${KIRIN_MODEL}" \
    "382205426" \
    "3706582deaf23056ac284afcd1203d62102028bcc9fc88559858e6e3566ac208" \
    "Kirin NNRT model"
verify_exact_asset \
    "${TOKENIZER}" \
    "2275556" \
    "4931cd8fd86354cf1d0ecab72e1302aac6235bea73dc9aab1421b9245641ee5b" \
    "RWKV tokenizer"

MODEL_PARENT="${TEMP_ROOT}/model"
MODEL_ROOT="${MODEL_PARENT}/rwkv-kirin-0.1b-model"
mkdir -p "${MODEL_ROOT}"
cp -p \
    "${KIRIN_MODEL}" \
    "${MODEL_ROOT}/rwkv7-g1d-0.1b-20260129-ctx8192-nnrt-f16.st"
cp -p \
    "${TOKENIZER}" \
    "${MODEL_ROOT}/b_rwkv_vocab_v20230424.txt"
cp -p "${TEMPLATE_ROOT}/MODEL_README.md" "${MODEL_ROOT}/README.md"
cp -p \
    "${MOBILE_ROOT}/converter/nnrt_model_conversion_report.json" \
    "${MODEL_ROOT}/"
cp -p \
    "${MOBILE_ROOT}/converter/requirements-nnrt.txt" \
    "${MODEL_ROOT}/"
cp -p \
    "${MOBILE_ROOT}/converter/verify_rwkv_nnrt_safetensors.py" \
    "${MODEL_ROOT}/"
python3 "${TEMPLATE_ROOT}/create_sha256_manifest.py" "${MODEL_ROOT}"
zip_and_verify \
    "${MODEL_PARENT}" \
    "$(basename "${MODEL_ROOT}")" \
    "${PARTIAL_OUTPUT}/archives/rwkv-kirin-0.1b-model.zip"

if [[ -f "${KNOWN_GOOD_HAP}" ]]; then
    verify_exact_asset \
        "${KNOWN_GOOD_HAP}" \
        "68239984" \
        "baa91844b76fb7a96d0576cb3663ba87416c1e2cd6fbe1c08f5497e5683fd747" \
        "last-known signed HAP"
    HAP_PARENT="${TEMP_ROOT}/hap"
    HAP_ROOT="${HAP_PARENT}/rwkv-known-good-signed-hap"
    mkdir -p "${HAP_ROOT}"
    cp -p "${KNOWN_GOOD_HAP}" "${HAP_ROOT}/entry-default-signed.hap"
    cp -p "${TEMPLATE_ROOT}/KNOWN_GOOD_HAP_README.md" "${HAP_ROOT}/README.md"
    python3 "${TEMPLATE_ROOT}/create_sha256_manifest.py" "${HAP_ROOT}"
    zip_and_verify \
        "${HAP_PARENT}" \
        "$(basename "${HAP_ROOT}")" \
        "${PARTIAL_OUTPUT}/archives/rwkv-known-good-signed-hap.zip"
fi

cp -p "${TEMPLATE_ROOT}/README_FIRST.md" "${PARTIAL_OUTPUT}/README_FIRST.md"
cp -p "${TEMPLATE_ROOT}/VERIFY_ALL_WINDOWS.ps1" "${PARTIAL_OUTPUT}/VERIFY_ALL_WINDOWS.ps1"
cp -p "${TEMPLATE_ROOT}/OPTIONAL_ASSETS.md" "${PARTIAL_OUTPUT}/OPTIONAL_ASSETS.md"
python3 "${TEMPLATE_ROOT}/create_sha256_manifest.py" "${PARTIAL_OUTPUT}"

mv "${PARTIAL_OUTPUT}" "${OUTPUT}"
(
    cd "${OUTPUT_PARENT}"
    zip -q -r -X "${OUTER_ZIP}" "${OUTPUT_NAME}"
)
python3 "${TEMPLATE_ROOT}/verify_transfer_archive.py" "${OUTER_ZIP}"
(
    cd "${OUTPUT_PARENT}"
    shasum -a 256 "$(basename "${OUTER_ZIP}")" > "$(basename "${OUTER_ZIP_HASH}")"
)

trap - EXIT
rm -rf "${TEMP_ROOT}"

echo "transfer folder: ${OUTPUT}"
echo "all-in-one ZIP: ${OUTER_ZIP}"
echo "ZIP SHA-256: ${OUTER_ZIP_HASH}"
