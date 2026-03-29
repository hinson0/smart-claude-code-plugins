#!/bin/bash
# SessionStart hook: plays a welcome message when the session starts
# Uses nohup + background to prevent Claude Code from killing the say command on exit
nohup say 'welcome,please enjoy it.' >/dev/null 2>&1 &
