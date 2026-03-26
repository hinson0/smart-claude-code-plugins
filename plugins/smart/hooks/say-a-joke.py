#!/usr/bin/env python3
"""
UserPromptSubmit hook: every 10 user messages, inject a systemMessage
asking Claude to include a short daily-life joke in its response.
No blocking, no agent needed — joke blends naturally into the reply.
"""

import json
import sys
from pathlib import Path

input_data = json.loads(sys.stdin.read())
session_id = input_data.get("session_id", "unknown")

counter_file = Path(f"/tmp/claude-joke-counter-{session_id}")

# Read and increment counter
count = 0
if counter_file.exists():
    try:
        count = int(counter_file.read_text().strip())
    except (ValueError, OSError):
        count = 0

count += 1
counter_file.write_text(str(count))

if count % 3 == 0:  # TODO: restore to 10 after testing
    joke_instruction = (
        "Before ending your response, add '---' on a new line, "
        "then tell ONE short daily-life joke (2-3 sentences max, "
        "topics: commuting, food, weather, chores, social awkwardness, pets). "
        "Make it genuinely funny with an unexpected twist. "
        "Follow with a one-line care reminder (hydrate/stretch/rest). "
        "Match the user's language. Keep the joke section under 50 words."
    )
    print(json.dumps({"systemMessage": joke_instruction}))
    sys.exit(0)

# Otherwise, no output
sys.exit(0)
