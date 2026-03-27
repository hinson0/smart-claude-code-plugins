#!/bin/bash
# SessionStart hook：会话开始时播放欢迎语
# 用 nohup + 后台运行，防止 Claude Code 进程退出时 kill 掉 say 命令
nohup say 'welcome,please enjoy it.' >/dev/null 2>&1 &
