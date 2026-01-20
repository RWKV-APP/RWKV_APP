#!/usr/bin/env python3
"""
脚本用于遍历demo-config.json中的模型配置，
从HuggingFace获取文件大小并更新fileSize字段（多线程版本）
"""

import json
import requests
import time
from typing import Dict, Any, List, Tuple
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
import argparse
from email.utils import parsedate_to_datetime

# 全局锁用于线程安全的打印
print_lock = Lock()


def safe_print(*args, **kwargs):
    """线程安全的打印函数"""
    with print_lock:
        print(*args, **kwargs)


def get_file_size_from_huggingface(url: str) -> Tuple[str, int]:
    """
    从HuggingFace URL获取文件大小

    Args:
        url: HuggingFace文件URL

    Returns:
        (模型名称, 文件大小字节数)
    """
    try:
        # 解析HuggingFace URL
        # 格式: mollysama/rwkv-mobile-models/resolve/main/...
        if not url.startswith("mollysama/rwkv-mobile-models/resolve/main/"):
            safe_print(f"\033[91m不支持的URL格式: {url}\033[0m")
            return url, 0, 0

        # 提取文件路径
        file_path = url.replace("mollysama/rwkv-mobile-models/resolve/main/", "")

        # 构建HuggingFace API URL
        api_url = f"https://huggingface.co/mollysama/rwkv-mobile-models/resolve/main/{file_path}"

        safe_print(f"  请求API: {api_url}")

        # 发送HEAD请求获取文件信息
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

        response = requests.head(api_url, headers=headers, timeout=30, allow_redirects=True)

        if response.status_code == 200:
            # 从Content-Length头获取文件大小
            content_length = response.headers.get("Content-Length")
            date_str = response.headers.get("Date")
            timestamp = 0
            if date_str:
                try:
                    dt = parsedate_to_datetime(date_str)
                    timestamp = int(dt.timestamp())
                except Exception:
                    pass

            if content_length:
                return url, int(content_length), timestamp

        # 如果HEAD请求失败，尝试GET请求
        safe_print(f"  HEAD请求失败，尝试GET请求")
        response = requests.get(api_url, headers=headers, stream=True, timeout=30, allow_redirects=True)

        if response.status_code == 200:
            content_length = response.headers.get("Content-Length")
            date_str = response.headers.get("Date")
            timestamp = 0
            if date_str:
                try:
                    dt = parsedate_to_datetime(date_str)
                    timestamp = int(dt.timestamp())
                except Exception:
                    pass

            if content_length:
                return url, int(content_length), timestamp

        safe_print(f"\033[91m  无法获取文件大小，状态码: {response.status_code}\033[0m")
        return url, 0, 0

    except Exception as e:
        safe_print(f"\033[91m  获取文件大小时出错: {e}\033[0m")
        return url, 0, 0


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
                url_key, file_size, timestamp = future.result()
                results[url_key] = (file_size, timestamp)

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
                new_size, new_timestamp = file_size_info
            else:
                new_size = file_size_info
                new_timestamp = 0

            old_size = model.get("fileSize", 0)

            if new_size > 0:
                changed = False
                if old_size != new_size:
                    model["fileSize"] = new_size
                    safe_print(f"  更新: {model_name}")
                    safe_print(f"    文件大小: {old_size:,} -> {new_size:,} 字节 ({new_size / 1024 / 1024:.2f} MB)")
                    changed = True

                if changed and new_timestamp > 0:
                    model["date"] = new_timestamp
                    # 这里不打印日期更新日志，以免太啰嗦，除非需要

                if changed:
                    updated_count += 1
                else:
                    safe_print(f"  跳过: {model['url']}（文件大小未变化）")
            else:
                safe_print(f"\033[91m  跳过: {model['url']}（无法获取文件大小）\033[0m")
        else:
            safe_print(f"  跳过: {model['url']}（没有URL）")

    # 保存更新后的配置文件，保持原有格式
    with open(config_file, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)

    safe_print(f"\n配置文件已更新: {config_file}")
    safe_print(f"成功更新了 {updated_count}/{len(models)} 个模型")


def format_json_with_prettier(file_path: str, print_width: int = 200) -> bool:
    try:
        import subprocess

        cmd = ["npx", "prettier", "--parser", "json", f"--print-width={print_width}", "--write", file_path]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode != 0:
            safe_print(f"\033[91mPrettier 格式化失败: {result.stderr.strip()}\033[0m")
            return False
        safe_print("使用 Prettier 完成 JSON 格式化")
        return True
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
