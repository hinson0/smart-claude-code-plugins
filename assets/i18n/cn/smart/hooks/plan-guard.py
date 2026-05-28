#!/usr/bin/env python3

"""
UserPromptSubmit hook：当 prompt 要求编写或敲定实现计划时，向上下文注入一份
保真清单，使计划忠实于已批准的设计。检测基于关键词（确定性、无 LLM 开销）；
未命中则保持静默。
"""

import json
import re
import sys

try:
    data = json.loads(sys.stdin.read())
except json.JSONDecodeError:
    sys.exit(0)

prompt = data.get("prompt") or data.get("user_prompt") or ""

# 计划编写意图：斜杠命令或自然语言，中英文均覆盖。
triggers = re.compile(
    r"write[-_ ]?plan|implementation plan|/plan\b|写计划|实现计划|编写计划|制定计划",
    re.IGNORECASE,
)

if not triggers.search(prompt):
    sys.exit(0)

print(
    "[plan-guard] 你即将编写实现计划。动手前请遵守：\n"
    "1. 把任何已批准的设计/预览当作「源文件」逐元素照搬。重新打开它，不要凭记忆重建。\n"
    "2. 任何打算省略或简化的元素（描述行、纹理、光晕、配色等），先显式列出来并征得"
    "用户同意，绝不静默裁剪。\n"
    "3. 单测只验字符串/逻辑，不验视觉保真。计划若含 UI，收尾要做一次真实渲染核验，"
    "或明确说明未做视觉比对。"
)
sys.exit(0)
