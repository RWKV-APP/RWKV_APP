#!/bin/bash
# Check native Apple authentication; exit without running a release.
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "用法：tools/apple_auth.command（只验证 Apple 登录，不接受发布参数）" >&2
  exit 2
fi
if [ ! -t 0 ] || [ ! -t 1 ]; then
  echo "请在本机可见终端运行，或在 Finder 中双击此脚本。" >&2
  exit 1
fi

if [ -z "${APPLE_ID_EMAIL:-}" ] || [ -z "${MACOS_APP_PASSWORD:-}" ]; then
  echo "请先加载私有发布环境中的 APPLE_ID_EMAIL 和 MACOS_APP_PASSWORD。" >&2
  exit 1
fi

export MACOS_APP_PASSWORD
echo "仅通过 Apple 原生工具验证账号访问；不会构建、签名或上传。"
exec xcrun altool --list-providers --username "$APPLE_ID_EMAIL" --password '@env:MACOS_APP_PASSWORD'
