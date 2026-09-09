#!/bin/bash
# Contact Apple for an interactive login check; exit without running a release.
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "用法：tools/apple_auth.command（只验证 Apple 登录，不接受发布参数）" >&2
  exit 2
fi
if [ ! -t 0 ] || [ ! -t 1 ]; then
  echo "请在本机可见终端运行，或在 Finder 中双击此脚本；验证码需要你手动输入。" >&2
  exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."
export BUNDLE_GEMFILE="$PWD/Gemfile"
export BUNDLE_FROZEN=true
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1
export FASTLANE_OPT_OUT_USAGE=1
export FASTLANE_SKIP_DOCS=1
bundler_version="$(awk '/^BUNDLED WITH$/{getline; print $1}' Gemfile.lock)"
if [ -z "$bundler_version" ]; then
  echo "Gemfile.lock 缺少 Bundler 版本。" >&2
  exit 1
fi
bundle "_${bundler_version}_" check

echo "仅验证 Apple ID / App Store Connect 登录；不会构建、签名或上传。"
echo "Apple 如要求密码或验证码，请在此终端输入。验证结束后临时会话会清除。"
exec bundle "_${bundler_version}_" exec fastlane ios_auth_preflight apple_auth_mode:apple_id
