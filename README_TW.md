# smart-claude-code-plugins

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> 寫完程式碼？直接說 **"發個PR"**，檢查、提交、推送、PR 全自動搞定。
>
> 不想開 PR，只想 push？說 **"推一下"**。
>
> 只想 commit？說 **"提交"**。
>
> 也可以用斜線指令：`/smart:pr`、`/smart:push`、`/smart:commit`。

一個為 Claude Code 設計的外掛。程式碼寫完之後，說一句話就行——它自動檢查、提交、推送，並向 `main` 分支建立 Pull Request，無需任何額外操作。一句 `push`，自動拆分多 feature、產生 commit message 並推送，效果如下：

![demo](./assets/imgs/tw.png)

---

## 快速開始

**1. 安裝外掛**（推薦）

先在 Claude Code 中註冊外掛市場：

```
/plugin marketplace add hinson0/smart-claude-code-plugins
```

然後從該市場安裝外掛：

```
/plugin install smart@smart-claude-code-plugins
```

---

## 特性

**核心流水線**

- **Fail-Fast 管線** — 任意步驟失敗立即停止，不會出現殘缺推送或錯誤 PR。
- **自動 CI 偵測** — 讀取 `.github/workflows/*.yml`，在本機執行對應檢查（ruff、pytest、mypy、eslint、tsc、vitest、jest、go test、turbo 等）。自動從 lock 檔案偵測套件管理器。
- **兩階段智慧提交分組** — 第一階段按 type 硬分割（feat vs fix vs refactor），第二階段按目的對同類 type 進行語義分割。杜絕無關變更混入同一次提交。
- **Conventional Commits** — 所有 commit message 自動遵循 `<type>(<scope>): <description>` 格式。優先尊重專案 `CLAUDE.md` 設定和既有 `git log` 風格。
- **自動版本升級** — 自動偵測版本檔案（`plugin.json`、`package.json`、`pyproject.toml`），分析 commit 類型，在推送前自動 bump 語義化版本號。Monorepo 中按檔案歸屬對映到對應 package，各自獨立升級。
- **自動建立 GitHub 倉庫** — 未設定 remote？自動在 GitHub 建立私有倉庫、設為 origin 並推送，全程無需手動操作。
- **語言一致性** — PR 標題、摘要和測試計畫自動與 commit message 使用相同語言。預設英文，可透過專案 `CLAUDE.md` 覆蓋。

**保護與自動化**

- **會話 Hook** — 會話開始時問候，結束時告別（透過 macOS `say` TTS 語音播報）。
- **會話日誌** — 每次工具呼叫的完整輸入資料均記錄到 `.smart/session-logs/`，便於事後除錯和稽核。

**實用工具**

- **視覺化進度追蹤** — 管道階段以即時任務清單顯示，包含待執行/執行中/已完成狀態、計時和 token 統計。
- **HUD / Statusline 安裝器** — 一條指令安裝功能豐富的狀態列，顯示模型、Git 分支、上下文用量、速率限制、系統資源和工具呼叫統計。支援安裝 / 刪除 / 重置，可選 user 或 project 作用域。
- **說明概覽** — `/smart:help` 動態掃描並列出所有技能、hook 和 agent 及其描述。
- **Joke Teller Agent** — 在合適的時機講個程式設計師笑話，緩解工作壓力。
- **內建編碼規則** — 預置規則檔案（如 Pydantic V2 標準）存於 `rules/` 目錄，按需軟連結至專案的 `.claude/rules/` 即可啟用。
- **會話知識蒸餾** — `/smart:distill` 從當前會話擷取有價值的問答對，按主題聚類成 markdown 檔案，落盤到知識庫。目標目錄讀自 `.smart/settings.json`（專案）或 `~/.smart/settings.json`（全域），沒有則用 `AskUserQuestion` 問一次並保存——之後靜默。預設 `.smart/knowledges/`；`{date}` 佔位符支援按日期嵌套的目錄（如 `~/knowledges/md/{date}`）。重複/新增/差分三態比對讓重複蒸餾只追加不重複，已 review 檔案（`.printed.md` 或有同名 PDF）絕不觸碰。

---

## 使用方式

**💬 自然語言** — 在對話中直接描述你的意圖：

| 你說的話 | 執行效果 |
|---|---|
| "commit" / "提交" / "完成了" | 僅智慧提交（暫存 + 分組 + 提交） |
| "push" / "推一下" | commit → version → push |
| "發個PR" / "create PR" / "open a pull request" | check → commit → version → push → PR |

**⌨️ 斜線指令** — 精確控制：

| 指令 | 作用 |
|---|---|
| `/smart:commit` | 僅提交（智慧分組，自動產生 message） |
| `/smart:version [基準分支]` | 分析 commit 並升級版本號（自動偵測版本檔案；任意分支均可執行） |
| `/smart:push` | commit → version → push（不建立 PR） |
| `/smart:pr [目標分支]` | 完整流程：check → commit → version → push → PR（預設目標分支：`main`） |
| `/smart:hud [rm\|reset]` | 安裝、刪除或重置狀態列（`--user` / `--project` 作用域） |
| `/smart:help [skill\|hook\|agent]` | 顯示所有外掛元件概覽（或按類別篩選） |
| `/smart:distill [目錄]` | 把當前會話蒸餾成按主題命名的知識檔案（預設 `.smart/knowledges/`） |

---

## 流水線

### 總覽

```
/smart:pr
    │
    ├── 1. check   — 自動 CI 偵測，本機執行
    │
    ├── 2. commit  — 兩階段語義分析，智慧分組提交
    │
    ├── 3. version — 語義化版本升級（支援 monorepo）
    │
    ├── 4. push    — 推送到 origin（需要時自動建立 GitHub 倉庫）
    │
    └── 5. pr      — 產生並建立 Pull Request
```

每個階段是獨立的 skill，透過 `@../path/SKILL.md` 引用串聯。任意階段失敗則立即停止整條流水線。

### 階段一：Check

自動偵測專案 CI 設定，在本機執行對應檢查。

**工作流程：**

1. 掃描 `.github/workflows/*.yml`，識別工具關鍵字
2. 配對工具：`ruff`、`pytest`、`mypy`、`eslint`、`tsc`、`vitest`、`jest`、`go test`、`golangci-lint`、`turbo` 等
3. 從 lock 檔案偵測套件管理器（`uv.lock` → `uv run`、`pnpm-lock.yaml` → `pnpm`、`package-lock.json` → `npm run`、`go.mod` → 直接執行）
4. 順序執行所有偵測到的檢查——任一失敗即阻斷後續流程
5. 允許 `ruff --fix` 在失敗前自動修復問題

**支援的生態系統：**

| 生態系統 | 工具 |
|---|---|
| Python | ruff（lint + format）、pytest、mypy |
| JavaScript / TypeScript | eslint、tsc、vitest、jest、turbo |
| Go | go test、golangci-lint |

若專案中無 `.github/workflows/` 目錄，此階段靜默跳過。

### 階段二：Commit

核心智慧——分析所有待提交變更，產生整潔、分組良好的提交。

**兩階段分組演算法：**

1. **按 type 硬分割** — 先按 Conventional Commit 類型（`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`）分類。不同 type **必定**是獨立提交。
2. **按目的語義分割** — 同一 type 內，若變更服務於不同目的，則進一步拆分。例如兩個獨立的 `feat` 新增功能會成為兩次獨立提交。

`scope` 欄位描述的是「在哪裡改」，不影響分組。分組邏輯完全由 type + purpose 驅動。

**Commit message 產生優先順序：**

1. 專案 `CLAUDE.md` — 若指定了 commit 格式，優先使用
2. `git log` 風格 — 若既有提交遵循一致風格，自動配對
3. 預設 — Conventional Commits：`<type>(<scope>): <description>`

**執行方式：**
- 單組 → `git add -A` + 提交
- 多組 → 逐組 `git add <具體檔案>` + HEREDOC 提交
- 迴圈執行直到工作區乾淨（處理 hook 或 formatter 在提交過程中修改檔案的情況）

### 階段三：Version

分析 commit 歷史，自動 bump 語義化版本號。

**Semver 規則：**

| Commit 模式 | Bump 類型 | 範例 |
|---|---|---|
| `feat` | minor | 0.1.0 → 0.2.0 |
| `fix`、`refactor`、`perf`、`docs` 等 | patch | 0.1.0 → 0.1.1 |
| `BREAKING CHANGE` 或 `!` 後綴 | major | 0.1.0 → 1.0.0 |

**版本檔案偵測：**

自動掃描專案根目錄和 workspace 目錄中的 `plugin.json`、`package.json`、`pyproject.toml`。

**Monorepo 支援：**

每個變更檔案沿目錄樹向上查找最近的版本檔案（「closest owner」策略），各 package 根據自己的 commit 獨立 bump。

**行為：**
- 任意分支均可執行（main 與 feature 分支均支援）
- 若上次 version bump 後無新提交，則跳過
- 所有版本變更統一提交為一個 `chore(version): bump version to X.X.X`

### 階段四：Push

推送提交到遠端倉庫。

若未設定 `origin` remote：
1. 透過 `gh repo create` 在 GitHub 建立**私有**倉庫
2. 設為 `origin`
3. 執行 `git push -u origin HEAD`

### 階段五：PR

產生並在 GitHub 上建立 Pull Request。

**工作流程：**

1. 偵測當前分支和語言（繼承 commit 階段的語言決策，或從 `git log` 推斷）
2. 透過提示詢問目標分支（預設 `main`）
3. 檢查是否已存在相同 head branch 的開放 PR——若有則顯示 URL 並停止
4. 收集 `BASE_BRANCH..HEAD` 之間的全部提交
5. 產生 PR 標題：
   - 單次提交 → 直接使用 commit message
   - 多次提交 → 產生概要標題
6. 產生 Markdown 格式 PR 內文：
   - **Summary** — 變更描述要點
   - **Commits** — 完整提交清單
   - **Test Plan** — 根據 commit 類型自動產生 `- [ ]` 檢查清單（如 `feat` → "verify new feature works"，`fix` → "confirm bug is resolved"）
7. 透過 `gh pr create` 建立 PR

PR 標題、內文和測試計畫的語言與 commit message 保持一致。

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
| `/smart:hud` | 安裝到 user 作用域（自動備份既有狀態列） |
| `/smart:hud --project` | 安裝到 project 作用域（`.claude/settings.json`，僅當前專案） |
| `/smart:hud rm` | 刪除狀態列（自動偵測已安裝的作用域） |
| `/smart:hud reset` | 從備份還原之前的狀態列 |

**注意：** 需要安裝 `jq`。狀態列腳本針對 macOS 最佳化（使用 `pmset` 取得電量、`sysctl` 取得系統資訊）。

---

## Agents

### 笑話講述器（Joke Teller）

講個程式設計師笑話來緩解工作壓力。

```
"tell me a joke" / "講個笑話" / "I need a laugh"
```

- 自動偵測對話語言，用對應語言講笑話
- 短格式（2–4 句，抖包袱風格，不用一問一答範本）
- 附帶一句溫馨提醒（喝水、伸展、休息）

---

## 會話 Hooks

外掛包含在會話邊界和工具呼叫時觸發的 hooks：

| Hook | 觸發時機 | 功能 |
|------|---------|------|
| `greet.sh` | `SessionStart` | 透過 macOS TTS（`say`）播放歡迎語 |
| `goodbye.sh` | `SessionEnd` | 透過 macOS TTS（`say`）播放告別語 |
| `session-logs.py` | `PreToolUse`（所有工具） | 將每次工具呼叫的完整輸入記錄到 `.smart/session-logs/<日期>/<session_id>.json` |
| `plan-guard.py` | `UserPromptSubmit` | 當 prompt 要求編寫實作計畫時，注入一份清單使計畫忠實於已批准的設計 |
| _(prompt hook)_ | `Stop` | 停止前比對已批准的 UI 設計與計畫/實作，若有元素未經報備就被丟棄則阻斷 |

所有 hooks 透過 `${CLAUDE_PLUGIN_ROOT}` 解析路徑。TTS hooks 在背景執行（`nohup &`），不阻塞 Claude Code。`plan-guard.py` 與 `Stop` 這一對用於防止已批准設計與實作計畫之間的靜默走樣；`Stop` 檢查為盡力而為（基於 transcript 推理，不比對算繪像素）。

---

## 前置需求

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — 用於推送（自動建立 remote）和 PR 建立
- `jq` — 僅 HUD 狀態列需要（其他功能無需）

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
