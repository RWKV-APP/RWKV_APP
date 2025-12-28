#!/bin/bash
# 同步 .env 文件中的配置到 GitHub Secrets
# 使用方法: ./scripts/sync_secrets_to_github.sh

set -e

# 获取仓库信息
REPO=$(git remote get-url origin 2>/dev/null | sed -E 's/.*github.com[:/]([^/]+\/[^/]+)(\.git)?$/\1/' | sed 's/\.git$//')
ENV_FILE=".env"

if [ -z "$REPO" ]; then
    echo "❌ 无法检测到 GitHub 仓库，请手动设置 REPO 变量"
    exit 1
fi

echo "🔍 检查 GitHub CLI..."
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) 未安装"
    echo "   安装方法: brew install gh"
    exit 1
fi

echo "✅ GitHub CLI 已安装"
echo "📦 仓库: $REPO"
echo "📄 环境文件: $ENV_FILE"
echo ""

# 检查 .env 文件是否存在
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env 文件不存在: $ENV_FILE"
    exit 1
fi

# 定义需要同步的 secrets（根据 workflows 中使用的）
SECRETS_TO_SYNC=(
    "ANDROID_KEYSTORE_BASE64"
    "ANDROID_KEYSTORE_PASSWORD"
    "ANDROID_KEY_ALIAS"
    "ANDROID_KEY_PASSWORD"
    "APPLE_ID_EMAIL"
    "MACOS_APP_PASSWORD"
    "MACOS_CERTIFICATE"
    "MACOS_CERTIFICATE_PWD"
    "MACOS_IDENTITY_ID"
    "HF_TOKEN"
    "HF_DATASETS_ID"
    "PGYER_API_KEY"
)

# 读取 .env 文件
echo "📖 读取 .env 文件..."
declare -A ENV_VARS

while IFS= read -r line || [ -n "$line" ]; do
    # 跳过注释和空行
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue
    
    # 解析 KEY=VALUE
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # 去除前后空格
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # 移除可能的引号
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"
        
        if [ -n "$key" ] && [ -n "$value" ]; then
            ENV_VARS["$key"]="$value"
        fi
    fi
done < "$ENV_FILE"

echo "✅ 读取完成，找到 ${#ENV_VARS[@]} 个环境变量"
echo ""
echo "📋 准备同步以下 Secrets:"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

for secret_name in "${SECRETS_TO_SYNC[@]}"; do
    if [[ -n "${ENV_VARS[$secret_name]}" ]]; then
        echo -n "  🔄 $secret_name ... "
        if gh secret set "$secret_name" --repo "$REPO" --body "${ENV_VARS[$secret_name]}" 2>/dev/null; then
            echo "✅"
            ((SUCCESS_COUNT++))
        else
            echo "❌"
            ((FAIL_COUNT++))
        fi
    else
        echo "  ⚠️  $secret_name (在 .env 中未找到，跳过)"
        ((SKIP_COUNT++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 成功: $SUCCESS_COUNT"
echo "❌ 失败: $FAIL_COUNT"
echo "⚠️  跳过: $SKIP_COUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAIL_COUNT -eq 0 ] && [ $SUCCESS_COUNT -gt 0 ]; then
    echo ""
    echo "🎉 所有 secrets 已成功同步到 GitHub!"
    echo "   查看: https://github.com/$REPO/settings/secrets/actions"
fi

