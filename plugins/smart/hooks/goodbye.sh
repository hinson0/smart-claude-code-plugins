#!/bin/bash
# SessionEnd hook: plays a farewell message when the session ends
# Uses nohup + background to prevent Claude Code from killing the say command on exit
nohup say 'goodbye,see u again.' >/dev/null 2>&1 &
