#!/usr/bin/env python3

"""
UserPromptSubmit hook: when the prompt asks to write or finalize an
implementation plan, inject a fidelity checklist into context so the plan stays
faithful to any approved design. Detection is keyword-based (deterministic, no
LLM cost); on any non-match it stays silent.
"""

import json
import re
import sys

try:
    data = json.loads(sys.stdin.read())
except json.JSONDecodeError:
    sys.exit(0)

prompt = data.get("prompt") or data.get("user_prompt") or ""

# Plan-writing intent: slash commands or natural language, EN + CN.
triggers = re.compile(
    r"write[-_ ]?plan|implementation plan|/plan\b|写计划|实现计划|编写计划|制定计划",
    re.IGNORECASE,
)

if not triggers.search(prompt):
    sys.exit(0)

print(
    "[plan-guard] You are about to write an implementation plan. "
    "Before drafting:\n"
    "1. Treat any approved design/preview as the SOURCE — copy it element by "
    "element. Reopen it; do not rebuild from memory.\n"
    "2. For anything you intend to omit or simplify (description lines, "
    "textures, glow, colors, etc.), list it explicitly and get the user's "
    "sign-off first. Never trim silently.\n"
    "3. Unit tests verify strings/logic, not visual fidelity. If the plan "
    "includes UI, do a real render check at the end or state plainly that no "
    "visual diff was done."
)
sys.exit(0)
