# 更新敏感词加密文件

当 `assets/filter.txt` 发生变化时，使用本操作手册重新生成 `assets/filter.txt.gpg`，同步更新 GitHub Actions 密钥，并验证后续打包流程

下次可直接对 Coding Agent 说：

```text
按 docs/update-filter-gpg.md 更新敏感词加密文件
```

## 适用范围

- 仓库：`RWKV-APP/RWKV_APP`
- 明文文件：`assets/filter.txt`
- Git 跟踪的加密文件：`assets/filter.txt.gpg`
- GitHub Actions Secret：`FILTER_DECRYPT_PASS`
- Linux 解密 Action：`.github/actions/decrypt-assets`
- Windows 解密 Action：`.github/actions/decrypt-assets-windows`

`assets/filter.txt` 由 `.gitignore` 忽略，发布流程通过 GitHub Actions 解密 `.gpg` 文件后再执行 Flutter 打包

## 执行前检查

在仓库根目录执行：

```bash
test -f assets/filter.txt
gpg --version
openssl version
gh auth status
gh secret list --repo RWKV-APP/RWKV_APP | rg '^FILTER_DECRYPT_PASS\b'
rg -n 'FILTER_DECRYPT_PASS|filter\.txt\.gpg|decrypt-assets' .github/actions .github/workflows
shasum -a 256 assets/filter.txt assets/filter.txt.gpg
```

如果 GitHub CLI 尚未登录，先完成 `gh auth login`，随后继续

## 重新加密并轮换密钥

下面的命令会生成随机密钥，先加密到临时文件，再进行解密比对。比对成功后更新 GitHub Secret，并替换仓库中的 `.gpg` 文件。密钥仅存在于当前 shell 进程内，不输出到终端，也不写入本地文件

```bash
set -euo pipefail

filter_pass="$(openssl rand -base64 48 | tr -d '\n')"
tmp_gpg="$(mktemp /tmp/filter.txt.gpg.XXXXXX)"
tmp_plain="$(mktemp /tmp/filter.txt.verify.XXXXXX)"

cleanup() {
  rm -f "$tmp_gpg" "$tmp_plain"
}
trap cleanup EXIT

gpg --quiet --batch --yes --pinentry-mode loopback \
  --passphrase-fd 3 \
  --symmetric \
  --cipher-algo AES256 \
  --output "$tmp_gpg" \
  assets/filter.txt \
  3<<<"$filter_pass"

gpg --quiet --batch --yes --pinentry-mode loopback \
  --passphrase-fd 3 \
  --decrypt \
  --output "$tmp_plain" \
  "$tmp_gpg" \
  3<<<"$filter_pass"

cmp -s assets/filter.txt "$tmp_plain"
printf '%s' "$filter_pass" | gh secret set FILTER_DECRYPT_PASS --repo RWKV-APP/RWKV_APP

mv "$tmp_gpg" assets/filter.txt.gpg
chmod 600 assets/filter.txt.gpg
rm -f "$tmp_plain"
trap - EXIT
```

任何命令失败时都应停止执行，并保留现有用户改动。禁止打印、记录或提交 `filter_pass`

## 验证

```bash
shasum -a 256 assets/filter.txt assets/filter.txt.gpg
wc -c assets/filter.txt assets/filter.txt.gpg
gh secret list --repo RWKV-APP/RWKV_APP | rg '^FILTER_DECRYPT_PASS\b'
flutter test test/sensitive_filter_test.dart
git diff --check
git status --short assets/filter.txt.gpg docs/update-filter-gpg.md
```

完成标准：

- 临时解密文件与 `assets/filter.txt` 逐字节一致
- `FILTER_DECRYPT_PASS` 的更新时间对应本次执行
- `test/sensitive_filter_test.dart` 全部通过
- `assets/filter.txt.gpg` 显示为本次修改
- 未经用户明确要求，不执行 Git commit 或 push

提交并推送新的 `assets/filter.txt.gpg` 后，后续 GitHub Actions 构建会自动解密并打包最新敏感词文件
