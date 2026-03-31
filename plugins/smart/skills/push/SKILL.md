---

description: Use when the user wants to push code to remote (e.g. "push", "push to origin"), or wants the full check+commit+push pipeline. Not for
creating PRs — use smart:pr instead. Includes automatic version bump before push.
argument-hint: No arguments needed. Auto [check+add+commit+version+push]

---

Launch the **push-pipeline** agent (subagent_type: `smart:push-pipeline`) to execute the full pipeline (check → commit → version → push).

Report to the user: "Push pipeline is running in background. You will be notified when it completes."

Do not execute the pipeline in this conversation. Dispatch to the agent immediately.
