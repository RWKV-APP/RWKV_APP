#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-rwkv-fec94}"
FILTER="${FILTER:-form=PHYSICAL}"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud is not installed or not available in PATH."
  echo "Install Google Cloud CLI, then run: gcloud auth login && gcloud config set project $PROJECT_ID"
  exit 1
fi

gcloud firebase test android models list \
  --project "$PROJECT_ID" \
  --filter="$FILTER"
