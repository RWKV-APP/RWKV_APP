#!/usr/bin/env python3
"""
脚本用于修复项目中所有 JSON 文件的换行符结尾问题
如果 JSON 文件不以换行符结尾，则添加换行符
"""

import os
import json
import glob
from pathlib import Path

def fix_json_newlines(directory="."):
    """
    修复指定目录下所有 JSON 文件的换行符结尾问题
    
    Args:
        directory (str): 要处理的目录路径，默认为当前目录
    """
    # 查找所有 JSON 文件
    json_files = []
    for root, dirs, files in os.walk(directory):
        # 跳过一些不需要处理的目录
        dirs[:] = [d for d in dirs if d not in ['.git', 'build', 'node_modules', '.dart_tool', 'Pods']]
        
        for file in files:
            if file.endswith('.json'):
                json_files.append(os.path.join(root, file))
    
    print(f"找到 {len(json_files)} 个 JSON 文件")
    
    fixed_count = 0
    error_count = 0
    
    for json_file in json_files:
        try:
            # 读取文件内容
            with open(json_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查文件是否以换行符结尾
            if not content.endswith('\n'):
                # 验证 JSON 格式是否正确
                try:
                    json.loads(content)
                    
                    # 添加换行符并写回文件
                    with open(json_file, 'w', encoding='utf-8') as f:
                        f.write(content + '\n')
                    
                    print(f"✓ 已修复: {json_file}")
                    fixed_count += 1
                    
                except json.JSONDecodeError as e:
                    print(f"✗ JSON 格式错误，跳过: {json_file} - {e}")
                    error_count += 1
            else:
                print(f"- 已正确: {json_file}")
                
        except Exception as e:
            print(f"✗ 处理文件时出错: {json_file} - {e}")
            error_count += 1
    
    print(f"\n处理完成:")
    print(f"  修复的文件: {fixed_count}")
    print(f"  已正确的文件: {len(json_files) - fixed_count - error_count}")
    print(f"  错误文件: {error_count}")

if __name__ == "__main__":
    # 获取当前工作目录
    current_dir = os.getcwd()
    print(f"正在处理目录: {current_dir}")
    
    # 执行修复
    fix_json_newlines(current_dir)
