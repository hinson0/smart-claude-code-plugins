#!/usr/bin/env python3

"""
流程：

  stdin (JSON) → 提取 file_path
      → 找项目根目录 (hook 输入的 cwd 或 CLAUDE_PROJECT_DIR 环境变量)
      → 读取 <项目根>/.claude/protect_files.jsonc
      → strip 注释 → json.loads → 得到 patterns 数组
      → 逐个 pattern 匹配:
          无通配符 → basename 精确匹配
          有通配符 → fnmatch 匹配
      → 命中 → stderr 输出中文提示 + exit(2)
      → 未命中 → exit(0)

  关键点：
  - 用 fnmatch.fnmatch 做 glob 匹配（Python 标准库，无额外依赖）
  - JSONC strip 注释：用正则去掉 // 行注释
  - 配置文件不存在时静默放行（exit(0)）
"""

import fnmatch
import json
import os
import re
import sys
from pathlib import Path


def _load_protected_patterns(project_root: str) -> list[str]:
    """读取项目根目录下的 .claude/protect_files.jsonc 配置文件，返回受保护文件模式列表。

    Args:
        project_root: 项目根目录的绝对路径字符串。

    Returns:
        受保护文件模式字符串列表。如果配置文件不存在或解析失败，返回空列表。
    """
    config_path = Path(project_root, ".claude", ".protect_files.jsonc")
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            content = _strip_jsonc_comments(f.read())
            patterns = json.loads(content)
            if isinstance(patterns, list):
                return [p for p in patterns if isinstance(p, str)]
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    return []


def _has_wildcard(pattern: str) -> bool:
    """检查模式字符串是否包含通配符。

    Args:
        pattern: 文件匹配模式字符串。

    Returns:
        如果模式包含 * 或 ? 通配符则返回 True，否则返回 False。
    """
    return "*" in pattern or "?" in pattern


def _strip_jsonc_comments(text: str) -> str:
    """移除 JSONC 文本中的行注释（//...）。

    Args:
        text: 可能包含 // 行注释的 JSONC 格式文本。

    Returns:
        移除所有 // 行注释后的纯 JSON 文本。
    """
    return re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)


def _is_protected(rel_path: str, patterns: list[str]) -> str | None:
    """检查文件是否被保护，返回命中的 pattern 或 None"""
    base_name = Path(rel_path).name
    for pattern in patterns:
        if _has_wildcard(pattern):
            if "**" in pattern:
                prefix = pattern.split("**")[0]
                if rel_path.startswith(prefix):
                    return pattern
            elif fnmatch.fnmatch(rel_path, pattern) or fnmatch.fnmatch(
                base_name, pattern
            ):
                return pattern
        else:
            if base_name == pattern or rel_path == pattern:
                return pattern
    return None


def main():
    hook_input = json.load(sys.stdin)
    file_path = hook_input.get("tool_input", {}).get("file_path", ".")

    if not file_path:
        sys.exit(0)

    project_root = hook_input.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR")
    if not project_root:
        sys.exit(0)

    patterns = _load_protected_patterns(project_root)
    if not patterns:
        sys.exit(0)

    try:
        rel_path = str(Path(file_path).relative_to(project_root))
    except ValueError:
        sys.exit(0)  # 不在项目内的文件，放行

    matched = _is_protected(rel_path, patterns)
    if matched:
        print(
            f'不可以修改文件:{file_path} \n 匹配保护规则 "{matched}"', file=sys.stderr
        )
        sys.exit(2)
    sys.exit(0)


if __name__ == "__main__":
    main()
