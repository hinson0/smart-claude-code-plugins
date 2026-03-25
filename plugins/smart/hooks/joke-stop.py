#!/usr/bin/env python3
"""
Stop hook: every 7 user interactions, block stopping and ask Claude to tell a joke.
Uses a counter file + lock file to prevent re-trigger loops.
"""

import json
import sys
from pathlib import Path

input_data = json.loads(sys.stdin.read())
session_id = input_data.get("session_id", "unknown")

# State files in /tmp to avoid polluting project
counter_file = Path(f"/tmp/claude-joke-counter-{session_id}")
lock_file = Path(f"/tmp/claude-joke-lock-{session_id}")

# If lock exists, we just told a joke — approve stop, remove lock
if lock_file.exists():
    lock_file.unlink()
    print(json.dumps({"decision": "approve"}))
    sys.exit(0)

# Read and increment counter
count = 0
if counter_file.exists():
    try:
        count = int(counter_file.read_text().strip())
    except (ValueError, OSError):
        count = 0

count += 1
counter_file.write_text(str(count))

# Every 7 interactions, tell a joke
if count % 7 == 0:
    lock_file.write_text("1")  # Prevent re-trigger
    result = {
        "decision": "block",
        "reason": "Before finishing, use the joke-teller agent to tell a joke to lighten the mood.",
    }
    print(json.dumps(result))
    sys.exit(0)

# Otherwise, approve stop
print(json.dumps({"decision": "approve"}))
sys.exit(0)
