# smart-codex-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> 寫完程式碼？在 Claude Code 執行 **`/smart:commit`**，或在 Codex 執行 **`$smart:commit`**。

這是一個同時支援 **Claude Code** 與 **Codex** 的外掛，提供聚焦的開發工作流、內容工具、會話工具和工程規則。

---

## 快速開始

外掛**同時內建兩套清單**（`.claude-plugin/` 給 Claude Code，`.codex-plugin/` 給 Codex），在任一宿主裡都能原生安裝。依你的宿主選擇：

### Claude Code

新增市場，然後安裝外掛——在 Claude Code 內執行：

```
/plugin marketplace add hinson0/smart-claude-code-plugins
/plugin install smart@smart
```

> 已經在本機克隆了？把市場指向你的克隆目錄即可：`/plugin marketplace add /path/to/smart-claude-code-plugins`。安裝後重啟工作階段，讓 skills、hooks 和 statusline 生效。

### Codex

最友好的方式是在 Codex session 內直接新增，無需克隆：

1. 執行 `/plugins`
2. 選擇 **[Add Marketplace]**
3. 貼上來源——`hinson0/smart-claude-code-plugins`（owner/repo）或完整 git URL——按 Enter 確認
4. 開啟 **Smart** 市場，安裝 **smart** 外掛

> 喜歡命令列？它會直接從 Git 拉取，無需克隆：
>
> ```bash
> codex plugin marketplace add hinson0/smart-claude-code-plugins
> codex plugin add smart@smart
> ```

---

## 本 Marketplace 的外掛

本倉庫發佈一個同時支援 Claude Code 與 Codex 的外掛：

| 外掛 | 安裝名稱 | 用途 |
|------|----------|------|
| Smart | `smart@smart` | 開發工作流、HTML/PDF/Wiki 工具、週報與會話工具 |

Claude Code 使用 `/smart:*`；Codex 提供對應的 `$smart:*` skills。

```bash
# Claude Code：加入 marketplace 後執行
/plugin install smart@smart

# Codex：加入 marketplace 後執行
codex plugin add smart@smart
```

Smart 包含十八個 skills：`ask`、`clean-branches`、`close-issue`、`code-simplifier`、`commit`、
`generate-wiki`、`github-skills-pdf`、`help`、`html`、`hud`、`learning`、`local`、
`matt-implement-all-tickets`、`my-weekly`、`one-by-one`、`pair-write`、`pr` 與 `show`。
部分流程依賴 Git、`gh`、`glab`、Node.js、Python/PDF 工具、
瀏覽器或文件能力；每個 skill 都會檢查自己的前置條件。
所有 skill 都只由使用者主動調用：請明確使用對應的 `/smart:*` 或
`$smart:*` 名稱，不依賴模型自動調用。
Codex 介面統一顯示 `smart:<name>`，保留 Claude Code 原調用名稱但省略 `/`，不再使用另一套標題。

---

## 特性

**Smart Commit**

- **低成本執行** — Claude Code 使用 Haiku；Codex 把完整提交工作流交給一個低 reasoning 的 GPT-5.6 Luna worker，並允許一次預設子 agent 兜底。
- **語意分組** — type 是硬邊界，purpose 是軟邊界，獨立改動必須成為獨立提交。
- **儲存庫感知 message** — 依序遵循專案規則、近期 Git 歷史和 Conventional Commits。
- **僅提交** — 不執行 CI 檢查、版本修改、push 或建立 PR。

**保護與自動化**

- **會話 Hook** — 會話開始時問候（透過 macOS `say` TTS 語音播報）。
- **會話日誌** — 每次工具呼叫的完整輸入資料均記錄到 `.smart/session-logs/`，便於事後除錯和稽核。
- **串行 Ticket 交付** — `/smart:matt-implement-all-tickets` 與 Matt `/implement` 一起明確載入後，以一個編排 session 驅動全新 workers，逐張實作、驗證、記錄並關閉目前 `/to-tickets` 輸出。支援已設定的 GitHub、GitLab 與本機 Markdown tracker，並在第一個未完成收口處停止。
- **可稽核的 GitLab Issue 收口** — `/implement` 完成提交與 Review 後，`/smart:close-issue` 會核對目前分支上的實作 commit、驗收證據與 Review 結論。明確授權關閉後，它會先發布這些開發資產、再關閉 Issue；目標分支是否整合只揭露，不作為關閉閘門。僅使用 `glab`，不會推導出 push、merge、建立 MR/PR、修改 checklist 或標籤的權限。

**實用工具**

- **HUD / Statusline 安裝器** — 一條指令安裝功能豐富的狀態列，顯示模型、Git 分支、上下文用量、速率限制、系統資源和工具呼叫統計。提供兩個安裝級別（簡化版 / 完整版）及從備份還原，僅 user 作用域。
- **說明概覽** — `/smart:help` 動態掃描並列出所有技能、hook 和 agent 及其描述。
- **唯讀指導** — `/smart:ask` 回傳簡潔判斷、指令、片段或清單，不修改檔案、不執行工具。
- **全新上下文程式碼簡化** — `/smart:code-simplifier` 把完整流程交給一個串行、不可遞迴委派且不帶對話歷史的 worker。主 agent 不接觸目標程式碼；worker 負責限定近期改動範圍、遵循儲存庫規範並證明行為等價。
- **單 Cycle TDD** — `/smart:one-by-one` 驗證一個最小 Red，再引導使用者完成對應 Green。
- **結對手寫** — `/smart:pair-write` 為一個使用者手寫步驟同輪提供註解骨架和直接展開的完整參考實作，預設只檢查書寫是否正確及落盤內容是否與指引一致。
- **Markdown 轉 HTML** — `/smart:html` 確定性地把 Markdown 轉為安全自包含 HTML，不自動開啟瀏覽器。
- **Wiki 產生** — `/smart:generate-wiki` 把資料整理為 GitLab、GitHub 或本機 Markdown Wiki，並安全發佈。
- **雙語 Skills PDF** — `/smart:github-skills-pdf` 固定 GitHub skills 倉庫版本並產生經驗證的英中 A4 手冊。
- **個人週報** — `/smart:my-weekly` 依自然週彙總目前使用者的 Git 提交。
- **內建編碼規則** — 預置規則檔案（如 Pydantic V2 標準）存於 `rules/` 目錄，按需軟連結至專案的 `.claude/rules/` 即可啟用。
- **學習模式** — `/smart:learning 1` 開啟一種簡單的協作編碼模式：由*你*親手編寫程式碼。它是一個純粹的開/關開關——沒有占比、沒有設定。開啟時，凡是 Claude 本會寫的程式碼都改為印到主控台——每段標明 新增檔案 / 新增程式碼 / 修改 / 刪除，並附檔案與位置——由你敲入，然後 Claude 審查你落盤的程式碼再繼續，每次只處理一個任務。開啟時把規則注入 `.claude/CLAUDE.local.md`（Claude Code 每次工作階段載入的、已 git-ignore 的專案級記憶）使其持續生效；該塊是否存在就是全部狀態，`/smart:learning 0` 移除它。`.smart/settings.json` 裡不存任何東西。
- **HTML 審閱頁** — `/smart:show` 把冗長交付物——當前對話的方案/分析/評審，或一個 Markdown 檔案——渲染成單檔案、零 JavaScript 的自包含 HTML 審閱頁並在瀏覽器開啟。灰底白卡視覺系統：黏性目錄、編號章節、風險徽章、方案對比卡（選定項高亮）、內聯 SVG 架構圖與 `<details>` 摺疊。三種固定版式配方（plan-review / explainer / report）保證每次生成的頁面結構一致。每頁強制攜帶出處頁腳（時間、commit SHA、來源），且僅是衍生視圖——Markdown 仍是事實來源。每次執行都在 `.smart/pages/`（已 git-ignore）寫入帶時間戳的新檔案，保留舊頁面作為不可變審閱資產，不再覆蓋。示例見 `assets/demos/`。

---

## 使用方式

**💬 明確調用** — 每個 skill 只在使用者指定名稱時啟動：
Claude Code 使用 `/smart:*`，Codex 使用 `$smart:*`。

**⌨️ Skill 指令** — 在 Codex 中把 `/smart:` 替換為 `$smart:`：

| 指令 | 作用 |
|---|---|
| `/smart:commit` | 僅提交（智慧分組，自動產生 message） |
| `/smart:pr [分支]` | 建立或更新 PR；無參數須確認預設 `main`，有參數直接執行；不自動合併 |
| `/smart:clean-branches [分支]` | 清理完整合併到目標的本機和遠端分支；無參數須確認預設 `main`；保留保護分支和 worktree 使用中的分支 |
| `/smart:ask` | 回傳簡潔唯讀指導，不執行指令或修改內容 |
| `/smart:close-issue <IID或URL>` | 唯讀核對單一 GitLab Issue；明確授權關閉後，先發布可稽核的開發資產記錄，再關閉 Issue |
| `/smart:code-simplifier [路徑或diff]` | 使用一個全新上下文 worker 簡化近期程式碼，同時保持可觀察行為不變 |
| `/smart:matt-implement-all-tickets` | 明確載入 Matt `/implement` 後，串行實作並關閉目前 `/to-tickets` 輸出 |
| `/smart:generate-wiki` | 把資料整理為受保護的 GitLab、GitHub 或本機 Wiki |
| `/smart:github-skills-pdf [--notes 2\|4]` | 從 GitHub skills 倉庫產生經驗證的英中 A4 手冊 |
| `/smart:html <input.md> [output.html]` | 把 Markdown 轉為安全自包含 HTML，不自動開啟瀏覽器 |
| `/smart:hud [0\|1\|2\|reset\|normal\|all]` | 安裝狀態列（`1`/`normal`=簡化版，`2`/`all`=完整版）或還原備份（`0`/`reset`），user 作用域 |
| `/smart:help [skill\|hook\|agent]` | 顯示所有外掛元件概覽（或按類別篩選） |
| `/smart:learning [0\|1]` | 切換學習模式——由*你*親手寫程式碼；Claude 把每段印到主控台並標明 新增檔案 / 新增程式碼 / 修改 / 刪除 供你敲入，再審查你落盤的程式碼。`1`=開，`0`=關，留空=狀態。狀態就是注入到 `.claude/CLAUDE.local.md` 的塊——無設定、無占比 |
| `/smart:my-weekly <repo> [-N]` | 依指定自然週彙總目前使用者的 Git 提交 |
| `/smart:one-by-one` | 每次執行一個最小 Red-to-Green Cycle |
| `/smart:pair-write` | 引導使用者手寫一個步驟，再對照骨架和參考實作檢查落盤程式碼 |
| `/smart:show [<path>.md]` | 把當前對話交付物（或指定 Markdown 檔案）渲染成帶時間戳的全新自包含零 JS HTML 審閱頁，寫入 `.smart/pages/`，保留舊頁面並在瀏覽器開啟。三種版式配方：plan-review / explainer / report |

---

## Smart Commit

`commit`、`pr`、`clean-branches` 同時在 Codex 中繼資料中停用自動呼叫，必須由使用者明確觸發。

`/smart:commit` 讀取狀態、已暫存和未暫存 diff、未追蹤檔案內容及近期歷史；先按 type、再按獨立目的分組，同一檔案可按變更區塊拆分；提交前簡要列出各組的提交訊息和檔案。

Claude Code 使用 `haiku` 執行整個 turn。Codex 把完整工作流交給一個低 reasoning 的 `gpt-5.6-luna` worker；Luna 不可用時，用使用者設定的預設子 agent 重試一次。主 agent 不自行分組或提交。

每組只暫存明確路徑或變更區塊，提交前核對暫存差異，禁止全量暫存。技能輸出提交雜湊、提交訊息和剩餘變更，不執行檢查、不改版本、不 push，也不建立 PR。


---

## 內建規則

外掛預置了編碼規則檔案，存放在 `rules/` 目錄下。按需將規則檔案軟連結到專案的 `.claude/rules/` 中即可啟用：

```bash
ln -s /path/to/plugin/rules/pydantic-v2.md .claude/rules/pydantic-v2.md
```

**可用規則：**

| 規則檔案 | 約束內容 |
|---|---|
| `pydantic-v2.md` | Pydantic V2 規範：`ConfigDict`、校驗器、判別聯合、`TypeAdapter`、`RootModel`、`SecretStr`、`pydantic-settings`、V1→V2 遷移 |
| `python-3.14.md` | Python 3.14 規範：延遲注解、`[T]` 泛型、`@override`、`Self`、`TaskGroup`、`StrEnum`、`datetime.UTC`、子直譯器、`match` 守衛 |
| `fastapi.md` | FastAPI 0.115+ 規範：`Annotated` 依賴注入、`lifespan`、`APIRouter` 組織、`BackgroundTasks`、`dependency_overrides`、安全作用域 |
| `sqlalchemy-v2.md` | SQLAlchemy 2.0 規範：`DeclarativeBase`、`Mapped[T]`、命名約定、非同步會話、`AsyncAttrs`、`selectinload`、UPSERT、Alembic |

規則預設不啟用，按需軟連結即可。

---

## HUD（狀態列）

一條指令安裝功能豐富的狀態列：

```
/smart:hud
```

![hud](./assets/imgs/hud.png)

**顯示內容（6 行）：**

| 行 | 內容 |
|----|------|
| 1 | 會話 ID / 會話名稱、模型@版本、總花費（USD） |
| 2 | 目錄、Git 分支（dirty/ahead/behind/stash）、最近 commit 時間、worktree 名稱、電池 |
| 3 | 上下文進度條 + tokens + cache、速率限制（5h/7d）含重置倒數、會話時長、agent 名稱 |
| 4 | CPU、記憶體、磁碟、運行時間、Runtime 版本（Node/Python/Go/Rust/Ruby）、本機 IP |
| 5 | 工具呼叫統計（Bash/Skill/Agent/Edit 次數，從 transcript 即時解析） |
| 6 | 輸出風格、vim 模式（僅啟用時顯示） |

**指令：**

| 指令 | 操作 |
|------|------|
| `/smart:hud` · `/smart:hud 2` · `/smart:hud all` | 安裝完整版狀態列（全部 6 行）到 user 作用域，自動備份 |
| `/smart:hud 1` · `/smart:hud normal` | 安裝簡化版狀態列（僅 session + ctx） |
| `/smart:hud 0` · `/smart:hud reset` | 從備份還原之前的狀態列 |

**注意：** 跨平台（macOS + Linux/WSL/Ubuntu）—— 自動偵測作業系統，電量、CPU、記憶體、IP 各取對應指令。需要 `jq`；缺少時 `/smart:hud` 會自動安裝（apt/dnf/pacman/apk/brew）。

---

## 會話 Hooks

外掛包含在會話邊界和工具呼叫時觸發的 hooks：

| Hook | 觸發時機 | 功能 |
|------|---------|------|
| `greet.sh` | `SessionStart` | 透過 macOS TTS（`say`）播放歡迎語 |
| `session-logs.py` | `PreToolUse`（所有工具） | 將每次工具呼叫的完整輸入記錄到 `.smart/session-logs/<日期>/<session_id>.json` |

內置 hook 配置在 Claude 相容宿主中透過 `${CLAUDE_PLUGIN_ROOT}` 解析路徑。TTS hooks 在背景執行（`nohup &`），不阻塞宿主進程。

---

## 前置需求

- **Claude Code** 或 **Codex**（支援外掛）—— 外掛內建兩套清單，在任一宿主都能原生執行
- `git`
- Matt Pocock Skills 的 `/implement` — `/smart:matt-implement-all-tickets` 必需
- [`gh` CLI](https://cli.github.com/) — `/smart:matt-implement-all-tickets` 使用 GitHub Issues 時需要
- [`glab` CLI](https://gitlab.com/gitlab-org/cli) — `/smart:close-issue` 以及 `/smart:matt-implement-all-tickets` 使用 GitLab Issues 時需要
- Node.js — 供 `/smart:html` 和收口腳本使用
- Python 3、`reportlab` 與可嵌入 CJK 字型 — 供 `/smart:github-skills-pdf` 使用
- `jq` — 僅 HUD 狀態列需要（其他功能無需）

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
