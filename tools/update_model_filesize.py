#!/usr/bin/env python3
"""
脚本用于遍历demo-config.json中的模型配置，
从HuggingFace获取文件大小并更新fileSize字段（多线程版本）
"""

import json
import requests
from typing import Dict, Any, List, Tuple
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
import argparse
from datetime import datetime
import subprocess
from urllib.parse import quote

# 全局锁用于线程安全的打印
print_lock = Lock()
cache_lock = Lock()
tree_cache: Dict[Tuple[str, str, str], List[Dict[str, Any]]] = {}


def safe_print(*args, **kwargs):
    """线程安全的打印函数"""
    with print_lock:
        print(*args, **kwargs)


def parse_hf_iso_datetime_to_timestamp(date_str: str) -> int:
    if not date_str:
        return 0

    try:
        dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        return int(dt.timestamp())
    except Exception:
        return 0


def parse_hf_resolve_url(url: str) -> Tuple[str, str, str]:
    """
    解析形如 owner/repo/resolve/revision/path/to/file 的 URL。

    Returns:
        (repo_id, revision, file_path)
    """
    pattern = r"^([^/]+/[^/]+)/resolve/([^/]+)/(.+)$"
    match = re.match(pattern, url)
    if not match:
        return "", "", ""
    return match.group(1), match.group(2), match.group(3)


def normalize_tree_entry_name(file_name: str) -> str:
    normalized_file_name = file_name.lower()
    normalized_file_name = normalized_file_name.replace(".ggufs", ".gguf")
    return normalized_file_name


def find_matching_tree_entry(entries: List[Dict[str, Any]], file_path: str) -> Tuple[Dict[str, Any] | None, str]:
    for entry in entries:
        if entry.get("path") == file_path and entry.get("type") == "file":
            return entry, file_path

    file_name = file_path.rsplit("/", 1)[-1]
    normalized_file_name = normalize_tree_entry_name(file_name)
    candidates: List[Dict[str, Any]] = []

    for entry in entries:
        if entry.get("type") != "file":
            continue

        entry_path = entry.get("path", "")
        if not isinstance(entry_path, str) or not entry_path:
            continue

        entry_name = entry_path.rsplit("/", 1)[-1]
        if normalize_tree_entry_name(entry_name) == normalized_file_name:
            candidates.append(entry)

    if len(candidates) != 1:
        return None, file_path

    matched_entry = candidates[0]
    matched_path = matched_entry.get("path", "")
    if not isinstance(matched_path, str) or not matched_path:
        return None, file_path

    safe_print(f"\033[93m  HF tree API 未找到精确文件: {file_path}\033[0m")
    safe_print(f"\033[93m  自动使用唯一匹配文件: {matched_path}\033[0m")
    return matched_entry, matched_path


def get_model_tree_entries(repo_id: str, revision: str, dir_path: str) -> List[Dict[str, Any]]:
    cache_key = (repo_id, revision, dir_path)
    with cache_lock:
        if cache_key in tree_cache:
            return tree_cache[cache_key]

    encoded_dir = quote(dir_path, safe="/")
    if encoded_dir:
        api_url = f"https://huggingface.co/api/models/{repo_id}/tree/{revision}/{encoded_dir}?recursive=false&expand=true"
    else:
        api_url = f"https://huggingface.co/api/models/{repo_id}/tree/{revision}?recursive=false&expand=true"

    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
    response = requests.get(api_url, headers=headers, timeout=30)
    if response.status_code != 200:
        safe_print(f"\033[91m  HF tree API 请求失败: {response.status_code} - {api_url}\033[0m")
        return []

    entries = response.json()
    if not isinstance(entries, list):
        safe_print(f"\033[91m  HF tree API 响应格式异常: {api_url}\033[0m")
        return []

    with cache_lock:
        tree_cache[cache_key] = entries
    return entries


def get_file_size_from_huggingface(url: str) -> Tuple[str, int, int, str]:
    """
    从HuggingFace URL获取文件大小和文件时间

    Args:
        url: HuggingFace文件URL

    Returns:
        (原始URL, 文件大小字节数, 文件时间戳, 修正后的URL)
    """
    try:
        repo_id, revision, file_path = parse_hf_resolve_url(url)
        if not repo_id or not revision or not file_path:
            safe_print(f"\033[91m不支持的URL格式: {url}\033[0m")
            return url, 0, 0, url

        safe_print(f"  查询HF tree API: {repo_id}@{revision}/{file_path}")

        dir_path = ""
        if "/" in file_path:
            dir_path = file_path.rsplit("/", 1)[0]

        entries = get_model_tree_entries(repo_id, revision, dir_path)
        matched_entry, resolved_path = find_matching_tree_entry(entries, file_path)
        resolved_url = url
        if resolved_path != file_path:
            resolved_url = f"{repo_id}/resolve/{revision}/{resolved_path}"

        if matched_entry:
            size = matched_entry.get("size", 0)
            if not isinstance(size, int):
                size = 0

            last_commit = matched_entry.get("lastCommit", {})
            last_commit_date = ""
            if isinstance(last_commit, dict):
                last_commit_date = last_commit.get("date", "")
            timestamp = parse_hf_iso_datetime_to_timestamp(last_commit_date)

            if size > 0:
                return url, size, timestamp, resolved_url

        # Fallback: 使用 resolve 响应头兜底大小（时间不作为最后提交时间）
        api_url = f"https://huggingface.co/{repo_id}/resolve/{revision}/{quote(resolved_path, safe='/')}"
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        response = requests.head(api_url, headers=headers, timeout=30, allow_redirects=True)
        if response.status_code == 200:
            content_length = response.headers.get("Content-Length")
            if content_length:
                return url, int(content_length), 0, resolved_url

        safe_print(f"\033[91m  无法获取文件信息，状态码: {response.status_code}\033[0m")
        return url, 0, 0, resolved_url

    except Exception as e:
        safe_print(f"\033[91m  获取文件大小时出错: {e}\033[0m")
        return url, 0, 0, url


def find_models(config: Dict[str, Any]) -> List[Dict[str, Any]]:
    models = []

    for section_name, section_data in config.items():
        if isinstance(section_data, dict) and "model_config" in section_data:
            for model in section_data["model_config"]:
                if isinstance(model, dict) and "backends" in model:
                    models.append({"section": section_name, "model": model})

    return models


def update_filesizes(config_file: str, max_workers: int = 5):
    """
    更新模型的文件大小（多线程版本）

    Args:
        config_file: 配置文件路径
        max_workers: 最大线程数
    """
    # 读取原始配置文件
    with open(config_file, "r", encoding="utf-8") as f:
        config = json.load(f)

    # 查找所有模型
    models = find_models(config)

    safe_print(f"找到 {len(models)} 个模型配置")
    safe_print(f"使用 {max_workers} 个线程并发处理")

    # 创建URL到模型的映射
    url_to_model = {}
    for item in models:
        model = item["model"]
        if "url" in model:
            url_to_model[model["url"]] = item

    # 收集所有需要处理的URL
    urls_to_process = list(url_to_model.keys())

    safe_print(f"\n开始并发获取文件大小...")

    # 使用线程池并发处理
    results = {}
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # 提交所有任务
        future_to_url = {executor.submit(get_file_size_from_huggingface, url): url for url in urls_to_process}

        # 处理完成的任务
        for future in as_completed(future_to_url):
            url = future_to_url[future]
            try:
                url_key, file_size, timestamp, resolved_url = future.result()
                results[url_key] = (file_size, timestamp, resolved_url)

                # 显示进度
                completed = len(results)
                total = len(urls_to_process)
                safe_print(f"  进度: {completed}/{total} - {url_key}")

            except Exception as e:
                safe_print(f"\033[91m处理URL时出错 {url}: {e}\033[0m")
                results[url] = (0, 0)

    # 更新模型配置
    safe_print(f"\n开始更新模型配置...")
    updated_count = 0

    for item in models:
        model = item["model"]
        model_name = model.get("name", "Unknown")

        if "url" in model and model["url"] in results:
            file_size_info = results[model["url"]]
            # 兼容旧代码，如果results只存了size（理论上不会，但为了健壮性）
            if isinstance(file_size_info, tuple):
                if len(file_size_info) == 3:
                    new_size, new_timestamp, resolved_url = file_size_info
                elif len(file_size_info) == 2:
                    new_size, new_timestamp = file_size_info
                    resolved_url = model["url"]
                else:
                    new_size = 0
                    new_timestamp = 0
                    resolved_url = model["url"]
            else:
                new_size = file_size_info
                new_timestamp = 0
                resolved_url = model["url"]

            old_size = model.get("fileSize", 0)
            old_timestamp = model.get("date", 0)
            old_url = model["url"]

            if new_size > 0:
                changed = False
                if resolved_url != old_url:
                    model["url"] = resolved_url
                    safe_print(f"  更新: {model_name}")
                    safe_print(f"    URL: {old_url} -> {resolved_url}")
                    changed = True

                if old_size != new_size:
                    if not changed:
                        safe_print(f"  更新: {model_name}")
                    model["fileSize"] = new_size
                    safe_print(f"    文件大小: {old_size:,} -> {new_size:,} 字节 ({new_size / 1024 / 1024:.2f} MB)")
                    changed = True

                if new_timestamp > 0 and old_timestamp != new_timestamp:
                    if not changed:
                        safe_print(f"  更新: {model_name}")
                    model["date"] = new_timestamp
                    safe_print(f"    时间: {old_timestamp} -> {new_timestamp}")
                    changed = True

                if changed:
                    updated_count += 1
                else:
                    safe_print(f"  跳过: {model['url']}（文件大小和时间未变化）")
            else:
                safe_print(f"\033[91m  跳过: {model['url']}（无法获取文件大小）\033[0m")
        else:
            safe_print(f"  跳过: {model['url']}（没有URL）")

    # 保存更新后的配置文件，保持原有格式
    with open(config_file, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)

    safe_print(f"\n配置文件已更新: {config_file}")
    safe_print(f"成功更新了 {updated_count}/{len(models)} 个模型")


def format_json_with_prettier(file_path: str, print_width: int = 200, timeout_seconds: int = 120) -> bool:
    try:
        cmd = ["npx", "--yes", "prettier", "--parser", "json", f"--print-width={print_width}", "--write", file_path]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=timeout_seconds)
        if result.returncode != 0:
            safe_print(f"\033[91mPrettier 格式化失败: {result.stderr.strip()}\033[0m")
            return False
        safe_print("使用 Prettier 完成 JSON 格式化")
        return True
    except subprocess.TimeoutExpired:
        safe_print(f"\033[93mPrettier 格式化超时（>{timeout_seconds} 秒），跳过\033[0m")
        return False
    except FileNotFoundError:
        safe_print("\033[93m未找到 npx 或 prettier，跳过 Prettier 格式化\033[0m")
        return False
    except Exception as e:
        safe_print(f"\033[91mPrettier 格式化出错: {e}\033[0m")
        return False


def main():
    parser = argparse.ArgumentParser(description="更新模型文件大小")
    parser.add_argument("--config", type=str, default="remote/latest.json", help="配置文件路径")
    parser.add_argument("--max-workers", type=int, default=5, help="最大线程数")
    args = parser.parse_args()

    """主函数"""
    config_file = args.config
    max_workers = args.max_workers

    safe_print("开始更新模型文件大小（多线程版本）...")
    safe_print("=" * 60)

    try:
        update_filesizes(config_file, max_workers)
        # 最后格式化 JSON，printWidth = 200
        formatted = format_json_with_prettier(config_file, 200)
        if not formatted:
            safe_print("已跳过或无法使用 Prettier 格式化，继续使用默认缩进格式")
        safe_print("\n更新完成！")
    except Exception as e:
        safe_print(f"\033[91m更新过程中出错: {e}\033[0m")


if __name__ == "__main__":
    main()
