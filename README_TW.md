# smart-claude-code-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> 寫完程式碼？直接說 **"發個PR"**，檢查、提交、推送、PR 全自動搞定。
>
> 不想開 PR，只想 push？說 **"推一下"**。
>
> 只想 commit？說 **"提交"**。
>
> 也可以用斜線指令：`/smart:pr`、`/smart:push`、`/smart:commit`、`/smart:check`。

一個為 Claude Code 設計的外掛。程式碼寫完之後，說一句話就行——它自動檢查、提交、推送，並向 `main` 分支建立 Pull Request，無需任何額外操作。

---

## 兩種使用方式

**💬 直接說** — 在對話中自然表達：

- "commit" / "提交" / "完成了" → 智慧提交
- "push" / "推一下" → check + commit + push
- "發個PR" / "create PR" → check + commit + push + PR

**⌨️ 斜線指令** — 精確控制：

| 指令 | 作用 |
|---|---|
| `/smart:pr [目標分支]` | 完整流程：check → commit → push → PR（預設目標分支：`main`） |
| `/smart:push` | check → commit → push（不建立 PR） |
| `/smart:commit` | 僅提交（智慧分組，自動產生 message） |
| `/smart:check` | 僅執行 CI 設定推斷出的本機檢查 |

---

## 快速開始

**1. 安裝外掛**（強烈推薦）

先在 Claude Code 中註冊外掛市場：

```
/plugin marketplace add hinson0/smart-claude-code-plugin
```

然後從該市場安裝外掛：

```
/plugin install smart@smart-claude-code-plugin
```

**2. 登入 GitHub CLI** _（僅需一次）_

```bash
gh auth login
```

**3. 完成。在任意倉庫中執行：**

```
/smart:pr
```

它會自動完成：偵測 CI 設定並在本機執行檢查 → 智慧提交 → 推送 → 在 GitHub 上建立 PR。

---

## 工作原理

```
/smart:pr
    │
    ├── 1. check   — 讀取 .github/workflows/*.yml，執行對應本機檢查
    │                （ruff/pytest、eslint/tsc、go test，無 CI 設定則跳過）
    │
    ├── 2. commit  — 語義分析變更，自動產生 commit message
    │                （多個獨立 feature 時自動拆分為多次提交）
    │
    ├── 3. push    — 推送到 origin
    │                （未設定 remote 時自動在 GitHub 建立倉庫並關聯）
    │
    └── 4. pr      — 自動產生標題和內文，建立 Pull Request
```

任意步驟失敗均立即停止，不會執行後續操作。

---

## 前置需求

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — 用於自動建立 GitHub remote 和 PR

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
