#!/bin/bash
# Artifact-free native Apple ID authentication; credentials stay in the environment.
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "Usage: tools/apple_auth.command (authentication only; no arguments)" >&2
  exit 2
fi
if [ ! -t 0 ] || [ ! -t 1 ]; then
  echo "Apple ID authentication requires a visible foreground terminal." >&2
  exit 1
fi
if [ -z "${APPLE_ID_EMAIL:-}" ] || [ -z "${MACOS_APP_PASSWORD:-}" ]; then
  echo "Supply APPLE_ID_EMAIL and MACOS_APP_PASSWORD through private environment storage." >&2
  exit 1
fi
if ! python3 -c 'import os, sys
try:
    foreground = os.tcgetpgrp(0) == os.getpgrp()
except OSError:
    foreground = False
sys.exit(0 if foreground else 1)'; then
  echo "Apple ID authentication requires the terminal foreground process group." >&2
  exit 1
fi
exec xcrun altool --list-providers --username "$APPLE_ID_EMAIL" \
  --password '@env:MACOS_APP_PASSWORD' --output-format json
