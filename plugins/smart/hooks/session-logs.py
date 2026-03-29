#!/usr/bin/env python3

"""
Reads JSON data from stdin and appends it to the session log file in the
project directory. Logs are organized by date under
.claude/session-logs/YYYY-MM-DD/, with filenames based on the session_id field.
"""

import json
import os
import sys
from datetime import date
from pathlib import Path

raw = sys.stdin.read()

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    # JSON parse failed, print error and exit
    print(f"JSON parse error: {raw}", file=sys.stderr)
    sys.exit(1)

# Get the current project directory
project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR", "."))

# Determine log directory
log_dir = Path(project_dir, ".claude", "session-logs", date.today().isoformat())

# Create directory if it doesn't exist
log_dir.mkdir(exist_ok=True, parents=True)

# Write log entry
log_file = log_dir / f"{data['session_id']}.json"
with open(log_file, "a", encoding="utf-8") as f:
    f.write(json.dumps(data, ensure_ascii=False, indent=2))
    f.write("\n\n")
