#!/usr/bin/env python3

"""
Reads JSON data from stdin and appends it to the session log file in the
project directory. Logs are organized by date under
.smart/session-logs/YYYY-MM-DD/, with filenames based on the session_id field.
Each log file is kept as a single valid JSON array of entries.
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
log_dir = Path(project_dir, ".smart", "session-logs", date.today().isoformat())

# Create directory if it doesn't exist
log_dir.mkdir(exist_ok=True, parents=True)

# Read existing entries, append, and rewrite so the file stays a valid JSON array.
# A corrupt or legacy-format file is discarded rather than crashing the hook.
log_file = log_dir / f"{data['session_id']}.json"
entries = []
if log_file.exists():
    try:
        with open(log_file, "r", encoding="utf-8") as f:
            existing = json.load(f)
        if isinstance(existing, list):
            entries = existing
    except (json.JSONDecodeError, OSError):
        entries = []

entries.append(data)

with open(log_file, "w", encoding="utf-8") as f:
    json.dump(entries, f, ensure_ascii=False, indent=2)
    f.write("\n")
