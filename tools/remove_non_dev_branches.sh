#!/bin/bash

# 脚本用于移除本地的非 dev 分支
# 保留 dev 分支和当前分支

echo "=== 移除本地非 dev 分支脚本 ==="

# 获取当前分支名
current_branch=$(git branch --show-current)
echo "当前分支: $current_branch"

# 获取所有本地分支
local_branches=$(git branch --format='%(refname:short)')

echo ""
echo "当前所有本地分支:"
echo "$local_branches"

echo ""
echo "将要删除的分支:"

# 遍历所有本地分支
for branch in $local_branches; do
    # 跳过当前分支
    if [ "$branch" = "$current_branch" ]; then
        echo "  ⚠️  跳过当前分支: $branch"
        continue
    fi
    
    # 跳过 dev 分支（包括 dev、develop、development 等变体）
    if [[ "$branch" =~ ^dev$|^develop$|^development$ ]]; then
        echo "  ✅ 保留 dev 分支: $branch"
        continue
    fi
    
    # 跳过 main 和 master 分支（通常需要保留）
    if [[ "$branch" =~ ^main$|^master$ ]]; then
        echo "  ✅ 保留主分支: $branch"
        continue
    fi
    
    # 标记要删除的分支
    echo "  ❌ 将要删除: $branch"
done

echo ""
read -p "确认要删除上述标记的分支吗？(y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo ""
    echo "开始删除分支..."
    
    deleted_count=0
    
    for branch in $local_branches; do
        # 跳过当前分支
        if [ "$branch" = "$current_branch" ]; then
            continue
        fi
        
        # 跳过 dev 分支
        if [[ "$branch" =~ ^dev$|^develop$|^development$ ]]; then
            continue
        fi
        
        # 跳过 main 和 master 分支
        if [[ "$branch" =~ ^main$|^master$ ]]; then
            continue
        fi
        
        # 删除分支
        echo "删除分支: $branch"
        if git branch -D "$branch"; then
            echo "  ✅ 成功删除: $branch"
            ((deleted_count++))
        else
            echo "  ❌ 删除失败: $branch"
        fi
    done
    
    echo ""
    echo "=== 删除完成 ==="
    echo "共删除 $deleted_count 个分支"
    
    echo ""
    echo "剩余分支:"
    git branch --format='%(refname:short)'
    
else
    echo "操作已取消"
fi
