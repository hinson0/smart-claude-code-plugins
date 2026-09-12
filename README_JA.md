# smart-codex-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> コーディングが終わったら、Claude Code で **`/smart:commit`**、Codex で **`$smart:commit`** を実行してください。

**Claude Code** と **Codex** の両方をサポートし、開発ワークフロー、コンテンツツール、セッションユーティリティ、エンジニアリングルールを提供するプラグインです。

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

## この Marketplace のプラグイン

このリポジトリは、Claude Code と Codex の両方をサポートする 1 つのプラグインを配布します。

| プラグイン | インストール名 | 用途 |
|------------|----------------|------|
| Smart | `smart@smart` | 開発ワークフロー、HTML/PDF/Wiki ツール、週報、セッションユーティリティ |

Claude Code は `/smart:*`、Codex は対応する `$smart:*` skills を使用します。

```bash
# Claude Code：marketplace 追加後に実行
/plugin install smart@smart

# Codex：marketplace 追加後に実行
codex plugin add smart@smart
```

Smart には `ask`、`close-issue`、`code-simplifier`、`commit`、`generate-wiki`、
`github-skills-pdf`、`help`、`html`、`hud`、`learning`、`local`、
`matt-implement-all-tickets`、`my-weekly`、`one-by-one`、`pair-write`、`show` の
16 個の skill が含まれます。一部のフローは Git、`gh`、`glab`、Node.js、
Python/PDF ツール、ブラウザ、文書機能を必要とし、
各 skill は自身の前提条件を確認します。
すべての skill はユーザーが明示的に呼び出します。モデルの自動呼び出しに頼らず、
対応する `/smart:*` または `$smart:*` 名を指定してください。
Codex UI は Claude Code の元の呼び出し名から `/` だけを省いた `smart:<name>` を表示し、別タイトルに置き換えません。

---

## 特徴

**Smart Commit**

- **低コスト実行** — Claude Code は Haiku を使用します。Codex はコミットワークフロー全体を low reasoning の GPT-5.6 Luna worker 1 つに任せ、デフォルトサブエージェントへのフォールバックは 1 回だけです。
- **意味ベースのグループ化** — type はハード境界、purpose はソフト境界で、独立した変更は独立したコミットになります。
- **リポジトリ対応 message** — プロジェクト規則、最近の Git 履歴、Conventional Commits の順で従います。
- **コミット専用** — CI チェック、バージョン変更、push、PR 作成は実行しません。

**保護と自動化**

- **セッション Hook** — セッション開始時に挨拶（macOS `say` TTS による音声出力）。
- **セッションログ** — すべてのツール呼び出しの完全な入力データが `.smart/session-logs/` に記録され、事後のデバッグと監査に活用できます。
- **直列 Ticket デリバリー** — `/smart:matt-implement-all-tickets` を Matt `/implement` と同時に明示的に読み込むと、1 つのオーケストレーター session が新しい workers を順番に動かし、現在の `/to-tickets` 出力を Ticket ごとに実装、検証、記録、クローズします。設定済みの GitHub、GitLab、ローカル Markdown tracker をサポートし、最初の未完了クローズで停止します。
- **監査可能な GitLab Issue クローズ** — `/implement` が実装を commit して Review を完了した後、`/smart:close-issue` は現在のブランチ上の実装 commit、受け入れ証拠、Review 結論を確認します。明示的な承認後、それらの開発資産を公開してから Issue を閉じます。対象ブランチへの統合は開示事項であり、クローズ条件ではありません。`glab` のみを使用し、push、merge、MR/PR 作成、checklist や label の変更権限は含みません。

**ユーティリティ**

- **HUD / Statusline インストーラー** — 1つのコマンドでモデル、Git ブランチ、コンテキスト使用量、レート制限、システムリソース、ツール呼び出し統計を表示するステータスラインをインストールします。2つのインストールレベル（最小 / フル）とバックアップ復元をサポート、user スコープのみ。
- **ヘルプ概要** — `/smart:help` で全スキル、フック、エージェントを動的にスキャンし、説明付きで一覧表示します。
- **読み取り専用ガイド** — `/smart:ask` はファイルやツールを変更せず、簡潔な判断、コマンド、スニペット、チェックリストを返します。
- **新規コンテキストでのコード簡略化** — `/smart:code-simplifier` は実行全体を会話履歴のない直列・非再帰 worker 1 つに任せます。primary agent は対象コードに触れず、worker が最近の変更範囲を定め、リポジトリ規則に従い、動作の同等性を証明します。
- **単一 Cycle TDD** — `/smart:one-by-one` は最小 Red を 1 つ検証し、対応する Green 実装を案内します。
- **ペアライティング** — `/smart:pair-write` はユーザーが書く 1 ステップにコメント骨格と展開済みの完全な参考実装を示し、デフォルトでは記述の正しさとガイドとの一致だけを確認します。
- **Markdown to HTML** — `/smart:html` は Markdown を安全な自己完結型 HTML に決定的に変換し、ブラウザを自動で開きません。
- **Wiki 生成** — `/smart:generate-wiki` は資料を GitLab、GitHub、ローカル Markdown Wiki に整理して安全に公開します。
- **バイリンガル Skills PDF** — `/smart:github-skills-pdf` は GitHub skills リポジトリを固定し、検証済み英中 A4 ハンドブックを生成します。
- **個人週報** — `/smart:my-weekly` は選択した自然週の現在ユーザーの Git コミットを要約します。
- **組み込みコーディングルール** — 事前に用意されたルールファイル（例：Pydantic V2 標準）が `rules/` に格納されています。プロジェクトの `.claude/rules/` にシンボリックリンクを作成するだけで有効化できます。
- **学習モード** — `/smart:learning 1` は*あなたが*コードを自分の手で書く、シンプルな協働コーディングモードを有効にします。割合も設定もない、単純なオン/オフのスイッチです。オンの間、Claude が書くはずのコードは代わりにコンソールへ出力され——各片は 新規ファイル / 新規コード / 修正 / 削除 とファイル・位置つきでラベル付けされ——あなたが入力し、Claude はあなたが保存したコードをレビューしてから次へ進みます（一度に一タスク）。有効化するとルールが `.claude/CLAUDE.local.md`（Claude Code が毎セッション読み込む、git-ignore されたプロジェクト別メモリ）に注入されて持続し、そのブロックの有無こそが状態のすべてで、`/smart:learning 0` がそれを削除します。`.smart/settings.json` には何も保存しません。
- **HTML レビューページ** — `/smart:show` は長い成果物——現在の会話のプラン/分析/レビュー、または Markdown ファイル——を単一ファイル・ゼロ JavaScript の自己完結型 HTML レビューページにレンダリングし、ブラウザで開きます。グレー地に白カードのビジュアルシステム：固定目次、番号付きセクション、リスクバッジ、代替案比較カード（採用案をハイライト）、インライン SVG 図、`<details>` 折りたたみ。3 つの固定レイアウトレシピ（plan-review / explainer / report）がページ構造の一貫性を保証します。全ページに出所フッター（時刻、commit SHA、ソース）を必須で刻み、あくまで派生ビュー——Markdown が事実の源泉のままです。実行のたびに `.smart/pages/`（git-ignore 済み）へタイムスタンプ付きの新規ファイルを書き出し、以前のページを上書きせず、不変のレビュー資産として保持します。デモは `assets/demos/` を参照。

---

## 使い方

**💬 明示的な呼び出し** — 各 skill はユーザーが名前を指定した場合のみ起動します。
Claude Code では `/smart:*`、Codex では `$smart:*` を使用してください。

**⌨️ Skill コマンド** — Codex では `/smart:` を `$smart:` に置き換えます：

| コマンド | 機能 |
|---|---|
| `/smart:commit` | コミットのみ（スマートグルーピング、メッセージ自動生成） |
| `/smart:ask` | 実行や変更をせず簡潔な読み取り専用ガイドを返す |
| `/smart:close-issue <IID-or-URL>` | 単一 GitLab Issue を読み取り専用で確認し、明示的なクローズ承認後に監査可能な開発資産 note を公開してから閉じる |
| `/smart:code-simplifier [paths-or-diff]` | 新規コンテキスト worker 1 つで観測可能な動作を保ちながら最近のコードを簡略化 |
| `/smart:matt-implement-all-tickets` | Matt `/implement` を明示的に読み込んだ上で、現在の `/to-tickets` 出力を直列に実装してクローズ |
| `/smart:generate-wiki` | 資料を保護された GitLab、GitHub、ローカル Wiki に整理 |
| `/smart:github-skills-pdf [--notes 2\|4]` | GitHub skills リポジトリから検証済み英中 A4 ハンドブックを生成 |
| `/smart:html <input.md> [output.html]` | Markdown を安全な自己完結型 HTML に変換 |
| `/smart:hud [0\|1\|2\|reset\|normal\|all]` | ステータスライン設置（`1`/`normal`=最小、`2`/`all`=フル）またはバックアップ復元（`0`/`reset`）、user スコープ |
| `/smart:help [skill\|hook\|agent]` | 全プラグインコンポーネントの概要表示（カテゴリ別フィルタも可能） |
| `/smart:learning [0\|1]` | 学習モードの切り替え — *あなたが*コードを自分で書く；Claude が各片を 新規ファイル / 新規コード / 修正 / 削除 とラベル付けしてコンソールに出力し、あなたが入力、保存したコードをレビュー。`1`=オン、`0`=オフ、空=状態。状態は `.claude/CLAUDE.local.md` に注入されたブロック——設定も割合もなし |
| `/smart:my-weekly <repo> [-N]` | 選択した自然週の現在ユーザーの Git コミットを要約 |
| `/smart:one-by-one` | 一度に 1 つの最小 Red-to-Green Cycle を実行 |
| `/smart:pair-write` | ユーザー作成の 1 ステップを案内し、保存済みコードを骨格と参考実装に照合 |
| `/smart:show [<path>.md]` | 現在の会話の成果物（または Markdown ファイル）をタイムスタンプ付きの新しい自己完結型ゼロ JS HTML レビューページにレンダリングし、以前のページを保持したまま `.smart/pages/` に書き出してブラウザで開く。レイアウトレシピ 3 種：plan-review / explainer / report |

---

## Smart Commit

`/smart:commit` は状態、staged/unstaged diff、未追跡ファイルの内容、最近の履歴を読み、type と独立した目的で分割します。同じファイル内も hunk 単位で分割し、コミット前に各グループのメッセージとファイルを示します。

Claude Code は turn 全体を `haiku` で実行します。Codex はワークフロー全体を low reasoning の `gpt-5.6-luna` worker 1 つに任せ、Luna が使えない場合はユーザー設定のデフォルトサブエージェントで 1 回再試行します。primary agent は直接グループ化やコミットを行いません。

各グループの明示的なパスまたは hunk だけを stage し、コミット前に staged diff を確認します。一括 stage は禁止です。コミットハッシュ、メッセージ、残りの変更を報告し、チェック、バージョン変更、push、PR 作成は実行しません。


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

## セッション Hooks

セッション境界とツール呼び出し時にトリガーされる hook が含まれています：

| Hook | トリガー | 機能 |
|------|---------|------|
| `greet.sh` | `SessionStart` | macOS TTS（`say`）でウェルカムメッセージを再生 |
| `session-logs.py` | `PreToolUse`（すべてのツール） | すべてのツール呼び出しの完全な入力を `.smart/session-logs/<日付>/<session_id>.json` に記録 |

同梱 hook 設定は Claude 互換 host で `${CLAUDE_PLUGIN_ROOT}` を使ってパスを解決します。TTS hook はバックグラウンドで実行され（`nohup &`）、host プロセスをブロックしません。

---

## 前提条件

- **Claude Code** または **Codex**（プラグイン対応）—— プラグインは両方のマニフェストを同梱し、どちらのホストでもネイティブに動作
- `git`
- Matt Pocock Skills の `/implement` — `/smart:matt-implement-all-tickets` に必要
- [`gh` CLI](https://cli.github.com/) — `/smart:matt-implement-all-tickets` で GitHub Issues を使う場合に必要
- [`glab` CLI](https://gitlab.com/gitlab-org/cli) — `/smart:close-issue` と `/smart:matt-implement-all-tickets` で GitLab Issues を使う場合に必要
- Node.js — `/smart:html` とクローズスクリプトに使用
- Python 3、`reportlab`、埋め込み可能な CJK フォント — `/smart:github-skills-pdf` に使用
- `jq` — HUD ステータスラインのみ必要（その他の機能には不要）

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
