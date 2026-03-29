#!/usr/bin/env python3

"""
Flow:

  stdin (JSON) → extract file_path
      → find project root (cwd from hook input or CLAUDE_PROJECT_DIR env var)
      → read <project_root>/.claude/.protect_files.jsonc
      → strip comments → json.loads → get patterns array
      → match each pattern:
          no wildcard → exact basename match
          with wildcard → fnmatch match
      → match found → stderr output + exit(2)
      → no match → exit(0)

  Key points:
  - Uses fnmatch.fnmatch for glob matching (Python stdlib, no extra deps)
  - JSONC comment stripping: removes // line comments via regex
  - Silently passes through if config file does not exist (exit(0))
"""

import fnmatch
import json
import os
import re
import sys
from pathlib import Path


def _load_protected_patterns(project_root: str) -> list[str]:
    """Load protected file patterns from .claude/.protect_files.jsonc in project root.

    Args:
        project_root: Absolute path string of the project root directory.

    Returns:
        List of protected file pattern strings. Returns empty list if config
        file does not exist or fails to parse.
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
    """Check whether a pattern string contains wildcard characters.

    Args:
        pattern: File matching pattern string.

    Returns:
        True if the pattern contains * or ? wildcards, False otherwise.
    """
    return "*" in pattern or "?" in pattern


def _strip_jsonc_comments(text: str) -> str:
    """Remove line comments (//...) from JSONC text.

    Args:
        text: JSONC-formatted text that may contain // line comments.

    Returns:
        Pure JSON text with all // line comments removed.
    """
    return re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)


def _is_protected(rel_path: str, patterns: list[str]) -> str | None:
    """Check if a file is protected; returns the matched pattern or None."""
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
        sys.exit(0)  # File is outside the project, allow through

    matched = _is_protected(rel_path, patterns)
    if matched:
        print(
            f'Cannot modify file: {file_path}\nMatched protection rule "{matched}"',
            file=sys.stderr,
        )
        sys.exit(2)
    sys.exit(0)


if __name__ == "__main__":
    main()
