#!/bin/bash
# SessionEnd hook：会话结束时播报告别语
# 用 nohup + 后台运行，防止 Claude Code 进程退出时 kill 掉 say 命令
nohup say 'goodbye,see u again.' >/dev/null 2>&1 &
