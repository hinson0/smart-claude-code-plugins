---

description: This skill should be used when the user wants to create a pull request (e.g. "create PR", "open PR", "open a pull request", "submit
PR", "merge request"), or wants the full check+commit+push+PR pipeline. Includes push and version bump — no need to push first.
argument-hint: "[base-branch] (optional) Target branch for the PR, defaults to main. Auto [check+add+commit+version+push+pr]"

---

Launch the **pr-pipeline** agent (subagent_type: `smart:pr-pipeline`) to execute the full pipeline (check → commit → version → push → PR).

If the user provided a base branch argument via `$ARGUMENTS`, include it in the agent prompt: "Base branch: <argument>". Otherwise the agent
defaults to `main`.

Report to the user: "PR pipeline is running in background. You will be notified when it completes."

Do not execute the pipeline in this conversation. Dispatch to the agent immediately.
