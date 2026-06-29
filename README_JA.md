# smart-codex-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> コードを書き終えたら？**「PRを作って」**と言うだけ。チェック、コミット、プッシュ、PR まで全自動。
>
> PR はいらない、push だけ？**「プッシュして」**。
>
> commit だけ？**「コミットして」**。
>
> スラッシュコマンドも使えます：`/smart:pr`、`/smart:push`、`/smart:commit`。

**Claude Code** と **Codex** の両方に対応したプラグインです。コードを書き終えたら、ひとこと言うだけ — 自動でチェック、コミット、プッシュし、`main` ブランチへの Pull Request を作成します。追加の操作は一切不要です。`push` の一言で、複数 feature の自動分割、commit message の生成、プッシュまで完了：

![demo](./assets/imgs/ja.png)

---

## クイックスタート

プラグインは**両方のマニフェストを同梱**しています（Claude Code 用 `.claude-plugin/`、Codex 用 `.codex-plugin/`）。どちらのホストでもネイティブにインストールできます。お使いのホストを選んでください：

### Claude Code

マーケットプレイスを追加してからプラグインをインストールします — Claude Code 内で実行：

```
/plugin marketplace add hinson0/smart-claude-code-plugins
/plugin install smart@smart
```

> すでにローカルに clone 済みですか？マーケットプレイスをクローン先に向ければ OK です：`/plugin marketplace add /path/to/smart-claude-code-plugins`。インストール後はセッションを再起動すると skills・hooks・statusline が読み込まれます。

### Codex

いちばん手軽なのは Codex セッション内で直接追加する方法です — clone 不要：

1. `/plugins` を実行
2. **[Add Marketplace]** を選択
3. ソースを貼り付け — `hinson0/smart-claude-code-plugins`（owner/repo）または完全な git URL — して Enter
4. **Smart** マーケットプレイスを開き、**smart** プラグインをインストール

> CLI が好みですか？Git から直接取得するので clone は不要です：
>
> ```bash
> codex plugin marketplace add hinson0/smart-claude-code-plugins
> codex plugin add smart@smart
> ```

---

## 特徴

**コアパイプライン**

- **Fail-Fast パイプライン** — いずれかのステップが失敗した時点で即座に停止。不完全なプッシュや誤った PR は発生しません。
- **CI 自動検出** — `.github/workflows/*.yml` を読み取り、対応するローカルチェックを実行（ruff、pytest、mypy、eslint、tsc、vitest、jest、go test、turbo など）。lock ファイルからパッケージマネージャーを自動検出します。
- **2フェーズスマートコミットグルーピング** — フェーズ1では type で強制分割（feat vs fix vs refactor）、フェーズ2では同一 type 内で目的別に意味的分割。無関係な変更が1つのコミットに混入することを防止。
- **Conventional Commits** — すべての commit message が自動的に `<type>(<scope>): <description>` 形式に従います。プロジェクト `AGENTS.md` / `CLAUDE.md` の設定と既存の `git log` スタイルを優先的に尊重します。
- **自動バージョンバンプ** — バージョンファイル（`.codex-plugin/plugin.json`、`package.json`、`pyproject.toml`）を自動検出し、コミットタイプを分析してプッシュ前にセマンティックバージョンを自動バンプ。モノレポでは変更ファイルを所属パッケージにマッピングし、それぞれ独立にバンプします。
- **GitHub リポジトリ自動作成** — remote 未設定？自動で GitHub にプライベートリポジトリを作成し、origin に設定してプッシュします。手動操作は一切不要です。
- **言語の一貫性** — PR タイトル、概要、テストプランは commit message と同じ言語を自動的に使用します。デフォルトは英語で、プロジェクトの `AGENTS.md` / `CLAUDE.md` で変更可能。

**保護と自動化**

- **セッション Hook** — セッション開始時に挨拶、終了時にお別れ（macOS `say` TTS による音声出力）。
- **セッションログ** — すべてのツール呼び出しの完全な入力データが `.smart/session-logs/` に記録され、事後のデバッグと監査に活用できます。

**ユーティリティ**

- **ビジュアル進行追跡** — パイプラインフェーズがリアルタイムタスクリストとして表示され、保留/進行中/完了ステータス、タイミング、トークン統計を確認できます。
- **HUD / Statusline インストーラー** — 1つのコマンドでモデル、Git ブランチ、コンテキスト使用量、レート制限、システムリソース、ツール呼び出し統計を表示するステータスラインをインストールします。2つのインストールレベル（最小 / フル）とバックアップ復元をサポート、user スコープのみ。
- **ヘルプ概要** — `/smart:help` で全スキル、フック、エージェントを動的にスキャンし、説明付きで一覧表示します。
- **Joke Teller Agent** — 適切なタイミングでプログラマージョークを提供し、作業ストレスを和らげます。
- **組み込みコーディングルール** — 事前に用意されたルールファイル（例：Pydantic V2 標準）が `rules/` に格納されています。プロジェクトの `.claude/rules/` にシンボリックリンクを作成するだけで有効化できます。
- **セッション知識蒸留** — `/smart:distill` は現在のセッションから価値ある Q&A を抽出し、トピック別の markdown ファイルにクラスタリングして知識ベースに書き出します。対象ディレクトリはローカルの `.smart/settings.json` から読み取り、なければ `AskUserQuestion` でグローバル `~/.smart/settings.json` を再利用するかローカル設定を新規作成するかを尋ね — どちらも無ければ書き出し先ディレクトリを尋ね — 選択をローカルに保存するので以降の実行は静かです。ディレクトリの確認はメインセッションに残り、重い抽出とファイル書き込みはバックグラウンドの **fork** で実行されるため、メインコンテキストには短い要約だけが返ります。デフォルト `.smart/knowledges/`；`{date}` トークンで `~/knowledges/md/{date}` のような日付ネストディレクトリに対応。重複/新規/差分の比較により再蒸留時は重複せず追記され、レビュー済みファイル（`.printed.md` または同名 PDF 付き）には一切触れません。
- **Workflow モデル階層化** — `/smart:wfb` は Workflow スクリプトを省 token にします：各 `agent()` を難易度で階層化し（機械的な作業は haiku、本体は sonnet、収束と重要/難しい実装は opus）、fan-out の前に呼び出しを剪定し、schema で出力を制約します。Workflow スクリプトを書くたびに自動的に適用されます。
- **クリップボードスクリーンショットアップローダー** — `/smart:sendshot` はクロスプラットフォームの `sendshot` shell 関数をインストールします：クリップボードの画像をキャプチャし、`scp` でリモートホスト（例：EC2）にアップロードして、リモートパスを出力しクリップボードに再コピーします。WSL（PowerShell で Windows クリップボードを読む）と macOS（`pngpaste`/`osascript`）に対応。zsh では **`Ctrl+G`** をバインドし、どのプロンプトからでも sendshot を実行できます。設定 — ホスト、鍵、リモートディレクトリ — は `~/.smart/settings.json` にあり実行時に読むため、ホストを変えても再インストール不要です。リモートディレクトリは `mkdir -p` で自動作成されます。
- **学習モード** — `/smart:learning 1` はコードの意味のある部分を*自分の手で*書く協働コーディングモードを有効にします：Claude は設定された割合のボイラープレート（~30%）、コアロジック（~60%）、データベーススキーマ（100%）を TODO スタブとして残し、手を止めてあなたに埋めてもらいます。トグルと調整可能なバケット別の割合は `.smart/settings.json`（`learning` + `learning_ratios`、distill と共有、git-ignore された `.smart/` ディレクトリ内）に保存され、有効化時にルールが `.claude/CLAUDE.local.md` に注入されて全セッションで持続し、`/smart:learning config boilerplate=40 core=70` で割合を調整し、`/smart:learning 0` でブロックを削除します。

---

## 使い方

**💬 自然言語** — チャットでやりたいことを直接説明：

| 言う内容 | 実行結果 |
|---|---|
| "commit" / "コミットして" / "完了" | スマートコミットのみ（ステージング + グループ化 + コミット） |
| "push" / "プッシュして" | commit → version → push |
| "PRを作って" / "create PR" / "open a pull request" | check → commit → version → push → PR |

**⌨️ スラッシュコマンド** — 正確な制御：

| コマンド | 機能 |
|---|---|
| `/smart:commit` | コミットのみ（スマートグルーピング、メッセージ自動生成） |
| `/smart:version [ベースブランチ]` | コミットを分析しバージョンをバンプ（バージョンファイルを自動検出；任意のブランチで実行可能） |
| `/smart:push` | commit → version → push（PR は作成しない） |
| `/smart:pr [ターゲットブランチ]` | フルパイプライン：check → commit → version → push → PR（デフォルト：`main`） |
| `/smart:hud [0\|1\|2\|reset\|normal\|all]` | ステータスライン設置（`1`/`normal`=最小、`2`/`all`=フル）またはバックアップ復元（`0`/`reset`）、user スコープ |
| `/smart:help [skill\|hook\|agent]` | 全プラグインコンポーネントの概要表示（カテゴリ別フィルタも可能） |
| `/smart:distill [ディレクトリ]` | 現在のセッションをトピック別の知識ファイルに蒸留（デフォルト `.smart/knowledges/`） |
| `/smart:wfb` | Workflow スクリプト作成のための省 token・モデル階層化ガイド（難易度別に haiku/sonnet/opus） |
| `/smart:sendshot [install\|config\|uninstall]` | クロスプラットフォーム `sendshot` 関数をインストール（クリップボード画像 → `scp` でリモート → リモートパスをコピー）；設定は `~/.smart/settings.json` |
| `/smart:learning [0\|1\|config]` | 学習モードの切り替え — コードの一部を*自分で*書く；バケット別の割合（ボイラープレート/コア/DB）は `.smart/settings.json` で設定。`1`=オン、`0`=オフ、`config bucket=NN`=割合調整、空=状態。ルールは `.claude/CLAUDE.local.md` に永続化 |

---

## パイプライン

### 概要

```
/smart:pr
    │
    ├── 1. check   — CI 自動検出＆ローカル実行
    │
    ├── 2. commit  — 2フェーズセマンティック分析＆スマートグルーピング
    │
    ├── 3. version — セマンティックバージョンバンプ（モノレポ対応）
    │
    ├── 4. push    — origin にプッシュ（必要に応じて GitHub リポジトリを自動作成）
    │
    └── 5. pr      — Pull Request を生成＆作成
```

各フェーズは独立した skill であり、`@../path/SKILL.md` 参照で連結されています。いずれかのフェーズが失敗すると、パイプライン全体が即座に停止します。

### フェーズ1：Check

プロジェクトの CI 設定を自動検出し、対応するチェックをローカルで実行します。

**動作の仕組み：**

1. `.github/workflows/*.yml` をスキャンしてツールキーワードを識別
2. マッチングツール：`ruff`、`pytest`、`mypy`、`eslint`、`tsc`、`vitest`、`jest`、`go test`、`golangci-lint`、`turbo` など
3. lock ファイルからパッケージマネージャーを検出（`uv.lock` → `uv run`、`pnpm-lock.yaml` → `pnpm`、`package-lock.json` → `npm run`、`go.mod` → 直接実行）
4. 検出されたすべてのチェックを順次実行 — いずれかが失敗するとパイプラインを中断
5. `ruff --fix` が失敗前に問題を自動修正することを許可

**対応エコシステム：**

| エコシステム | ツール |
|---|---|
| Python | ruff（lint + format）、pytest、mypy |
| JavaScript / TypeScript | eslint、tsc、vitest、jest、turbo |
| Go | go test、golangci-lint |

プロジェクトに `.github/workflows/` ディレクトリがない場合、このフェーズはサイレントにスキップされます。

### フェーズ2：Commit

コアインテリジェンス — すべての保留中の変更を分析し、きれいにグループ化されたコミットを生成します。

**2フェーズグルーピングアルゴリズム：**

1. **type による強制分割** — まず Conventional Commit タイプ（`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`）で分類します。異なる type は**必ず**別のコミットになります。
2. **目的による意味的分割** — 同一 type 内で、異なる目的の変更はさらに分割されます。例えば、2つの独立した `feat` 追加は2つの別々のコミットになります。

`scope` フィールドは「どこを変更したか」を表し、グルーピングには影響しません。グルーピングロジックは純粋に type + purpose で決定されます。

**Commit message 生成の優先順位：**

1. プロジェクト `AGENTS.md` / `CLAUDE.md` — commit フォーマットが指定されていれば優先使用
2. `git log` スタイル — 既存のコミットが一貫したスタイルに従っていれば自動マッチング
3. デフォルト — Conventional Commits：`<type>(<scope>): <description>`

**実行方法：**
- 単一グループ → `git add -A` + コミット
- 複数グループ → グループごとに `git add <特定ファイル>` + HEREDOC コミット
- ワーキングツリーがクリーンになるまでループ（hook やフォーマッターがコミット中にファイルを変更する場合に対応）

### フェーズ3：Version

コミット履歴を分析し、セマンティックバージョン番号を自動バンプします。

**Semver ルール：**

| コミットパターン | バンプタイプ | 例 |
|---|---|---|
| `feat` | minor | 0.1.0 → 0.2.0 |
| `fix`、`refactor`、`perf`、`docs` など | patch | 0.1.0 → 0.1.1 |
| `BREAKING CHANGE` または `!` サフィックス | major | 0.1.0 → 1.0.0 |

**バージョンファイル検出：**

プロジェクトルートと workspace ディレクトリで `plugin.json`、`package.json`、`pyproject.toml` を自動スキャンします。

**モノレポサポート：**

各変更ファイルはディレクトリツリーを遡って最も近いバージョンファイルを検索します（「closest owner」戦略）。各パッケージは自身のコミットに基づいて独立にバンプされます。

**動作：**
- 任意のブランチで実行可能（main ブランチ・feature ブランチ両対応）
- 前回のバージョンバンプ以降に新しいコミットがなければスキップ
- すべてのバージョン変更は単一の `chore(version): bump version to X.X.X` としてコミット

### フェーズ4：Push

リモートリポジトリにコミットをプッシュします。

`origin` remote が設定されていない場合：
1. `gh repo create` を通じて GitHub に**プライベート**リポジトリを作成
2. `origin` に設定
3. `git push -u origin HEAD` を実行

### フェーズ5：PR

GitHub 上で Pull Request を生成・作成します。

**動作の仕組み：**

1. 現在のブランチと言語を検出（commit フェーズの言語決定を継承、または `git log` から推論）
2. プロンプトでターゲットブランチを確認（デフォルト `main`）
3. 同じ head branch のオープン PR があるか確認 — あれば URL を表示して停止
4. `BASE_BRANCH..HEAD` 間のすべてのコミットを収集
5. PR タイトルを生成：
   - 単一コミット → commit message をそのまま使用
   - 複数コミット → 概要タイトルを生成
6. Markdown 形式の PR 本文を生成：
   - **Summary** — 変更内容の要点
   - **Commits** — 完全なコミットリスト
   - **Test Plan** — コミットタイプに基づいて `- [ ]` チェックリストを自動生成（例：`feat` → "verify new feature works"、`fix` → "confirm bug is resolved"）
7. `gh pr create` で PR を作成

PR タイトル、本文、テストプランの言語は commit message と一致します。

---

## 組み込みルール

プラグインには事前に用意されたコーディングルールファイルが `rules/` ディレクトリに含まれています。プロジェクトの `.claude/rules/` にシンボリックリンクを作成するだけで有効化できます：

```bash
ln -s /path/to/plugin/rules/pydantic-v2.md .claude/rules/pydantic-v2.md
```

**利用可能なルール：**

| ルールファイル | 適用内容 |
|---|---|
| `pydantic-v2.md` | Pydantic V2 標準：`ConfigDict`、バリデータ、判別共用体、`TypeAdapter`、`RootModel`、`SecretStr`、`pydantic-settings`、V1→V2 移行 |
| `python-3.14.md` | Python 3.14 標準：遅延アノテーション、`[T]` ジェネリクス、`@override`、`Self`、`TaskGroup`、`StrEnum`、`datetime.UTC`、サブインタープリタ、`match` ガード |
| `fastapi.md` | FastAPI 0.115+ 標準：`Annotated` 依存性注入、`lifespan`、`APIRouter` 組織、`BackgroundTasks`、`dependency_overrides`、セキュリティスコープ |
| `sqlalchemy-v2.md` | SQLAlchemy 2.0 標準：`DeclarativeBase`、`Mapped[T]`、命名規則、非同期セッション、`AsyncAttrs`、`selectinload`、UPSERT、Alembic |

ルールはデフォルトで無効です — 必要なものだけシンボリックリンクしてください。

---

## HUD（ステータスライン）

1つのコマンドで機能豊富なステータスラインをインストール：

```
/smart:hud
```

![hud](./assets/imgs/hud.png)

**表示内容（6行）：**

| 行 | 内容 |
|----|------|
| 1 | セッション ID / セッション名、モデル@バージョン、総コスト（USD） |
| 2 | ディレクトリ、Git ブランチ（dirty/ahead/behind/stash）、最近のコミット時間、worktree 名、バッテリー |
| 3 | コンテキスト進捗バー + トークン + キャッシュ、レート制限（5h/7d）リセットカウントダウン、セッション時間、agent 名 |
| 4 | CPU、メモリ、ディスク、稼働時間、ランタイムバージョン（Node/Python/Go/Rust/Ruby）、ローカル IP |
| 5 | ツール呼び出し統計（Bash/Skill/Agent/Edit 回数、transcript からリアルタイムにパース） |
| 6 | 出力スタイル、vim モード（有効時のみ表示） |

**コマンド：**

| コマンド | 操作 |
|----------|------|
| `/smart:hud` · `/smart:hud 2` · `/smart:hud all` | フルステータスライン（全6行）を user スコープにインストール、自動バックアップ |
| `/smart:hud 1` · `/smart:hud normal` | 最小ステータスラインをインストール（session + ctx のみ） |
| `/smart:hud 0` · `/smart:hud reset` | バックアップから以前のステータスラインを復元 |

**注意：** クロスプラットフォーム（macOS + Linux/WSL/Ubuntu）—— OS を自動検出し、バッテリー・CPU・メモリ・IP に応じたコマンドを使用します。`jq` が必要で、ない場合は `/smart:hud` が自動インストールします（apt/dnf/pacman/apk/brew）。

---

## Agents

### ジョークテラー（Joke Teller）

プログラマージョークを提供して作業ストレスを和らげます。

```
"tell me a joke" / "ジョーク言って" / "I need a laugh"
```

- 会話言語を自動検出し、該当言語でジョークを提供
- 短い形式（2–4文、オチスタイル — Q&A 形式ではない）
- やさしいセルフケアリマインダー付き（水分補給、ストレッチ、休憩）

---

## セッション Hooks

セッション境界とツール呼び出し時にトリガーされる hook が含まれています：

| Hook | トリガー | 機能 |
|------|---------|------|
| `greet.sh` | `SessionStart` | macOS TTS（`say`）でウェルカムメッセージを再生 |
| `goodbye.sh` | `SessionEnd` | macOS TTS（`say`）でお別れメッセージを再生 |
| `session-logs.py` | `PreToolUse`（すべてのツール） | すべてのツール呼び出しの完全な入力を `.smart/session-logs/<日付>/<session_id>.json` に記録 |

同梱 hook 設定は Claude 互換 host で `${CLAUDE_PLUGIN_ROOT}` を使ってパスを解決します。TTS hook はバックグラウンドで実行され（`nohup &`）、host プロセスをブロックしません。

---

## 前提条件

- **Claude Code** または **Codex**（プラグイン対応）—— プラグインは両方のマニフェストを同梱し、どちらのホストでもネイティブに動作
- `git`
- [`gh` CLI](https://cli.github.com) — プッシュ（リモート自動作成）と PR 作成に使用
- `jq` — HUD ステータスラインのみ必要（その他の機能には不要）

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
