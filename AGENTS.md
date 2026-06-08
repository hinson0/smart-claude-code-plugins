# Codex User Instructions

## Language Preferences

- 以后生成 spec / plan 默认使用中文；必要的英文技术词可以保留。

## 项目结构

```
根目录
├── .agents/plugins/marketplace.json     # Codex repo/team marketplace 注册文件（指向 plugins/smart）
├── assets/                              # i18n/ 多语言镜像 + imgs/ 截图资源
├── README.md / README_CN/TW/KO/JA.md   # 多语言用户文档
└── docs/                                # 设计文档（gitignored，不提交）

plugins/smart/                          # EN 主插件目录（被 Codex 实际加载）
├── .codex-plugin/plugin.json            # Codex 插件元数据
├── assets/                              # 打包脚本和资源
├── hooks/                               # hook 配置与脚本
├── rules/                               # 可选编码规则
└── skills/                              # EN skills
```

## 仓库约束

- 凡涉及功能变更、组件新增/删除、或用户可见行为改动，必须在同一次操作中同步更新所有 README 文件（`README.md`、`README_CN.md`、`README_TW.md`、`README_KO.md`、`README_JA.md`）。
- 修改任何 `plugins/smart/skills/<name>/SKILL.md` 后，必须同步更新 `assets/i18n/cn/smart/skills/<name>/SKILL.md`。
- 修改 hooks/assets/rules 时，保持 `plugins/smart/` 与 `assets/i18n/cn/smart/` 的结构一致；`plugins/` 下保留英文，`assets/i18n/cn/` 下保留中文。
- Codex 插件 manifest 必须保留 `plugins/smart/.codex-plugin/plugin.json`，根 marketplace 必须保留 `.agents/plugins/marketplace.json`。
- commit message 遵循 Conventional Commits：`<type>(<scope>): <description>`。
