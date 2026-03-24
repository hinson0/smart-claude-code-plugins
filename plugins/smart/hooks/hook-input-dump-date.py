#!/usr/bin/env python3

import sys
import json
from pathlib import Path
import os
from datetime import date

raw = sys.stdin.read()

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    # JSON解析失败，打印错误并退出
    print(f"JSON解析失败: {raw}", file=sys.stderr)
    sys.exit(1)

# 获取当前项目的目录
project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR", "."))

# 确定log目录
log_dir = Path(project_dir, ".claude", "hook-logs", date.today().isoformat())

# mkdir -p 目录
log_dir.mkdir(exist_ok=True, parents=True)

# 写日志
log_file = log_dir / f'{data["session_id"]}.json'
with open(log_file, 'a', encoding='utf-8') as f:
    f.write(json.dumps(data, ensure_ascii=False, indent=2))
    f.write("\n\n")
