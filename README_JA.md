# smart-claude-code-plugins

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

Claude Code 向けのプラグインです。コードを書き終えたら、ひとこと言うだけ — 自動でチェック、コミット、プッシュし、`main` ブランチへの Pull Request を作成します。追加の操作は一切不要です。`push` の一言で、複数 feature の自動分割、commit message の生成、プッシュまで完了：

![demo](./assets/imgs/ja.png)

---

## 特徴

- **2フェーズスマートコミットグルーピング** — フェーズ1では type で強制分割（feat vs fix vs refactor）、フェーズ2では同一 type 内で目的別に意味的分割。無関係な変更が1つのコミットに混入することを防止。
- **Fail-Fast パイプライン** — いずれかのステップが失敗した時点で即座に停止。不完全なプッシュや誤った PR は発生しません。
- **CI 自動検出** — `.github/workflows/*.yml` を読み取り、対応するローカルチェックを実行（ruff、pytest、eslint、tsc、jest、go test、turbo など）。
- **GitHub リポジトリ自動作成** — remote 未設定？自動で作成します。
- **Conventional Commits** — すべての commit message が自動的に `<type>(<scope>): <description>` 形式に従います。
- **言語の一貫性** — PR タイトル、概要、テストプランは commit message と同じ言語を自動的に使用します。デフォルトは英語で、プロジェクトの `CLAUDE.md` で変更可能。
- **ファイル保護 Hook** — Claude が機密ファイル（`.env`、lock ファイルなど）を編集するのをブロックします。プロジェクトレベルの `.claude/.protect_files.jsonc` で設定し、正確なファイル名マッチングと glob パターン（`*`、`**`）をサポートします。
- **セッション Hook** — セッション開始時に挨拶、終了時にお別れ。
- **コンテキスト分析 Agent** — どのプラグインが最もコンテキストウィンドウを消費しているか分析し、サイズ別ランキングテーブルとパーセンテージを表示します。

---

## 2つの使い方

**💬 話しかけるだけ** — チャットで自然に入力：

- "commit" / "コミットして" → スマートグルーピングでコミット
- "push" / "プッシュして" → check + commit + push
- "PRを作って" / "create PR" → check + commit + push + PR

**⌨️ スラッシュコマンド** — 明示的に指定したい時に：

| コマンド | 機能 |
|---|---|
| `/smart:pr [ターゲットブランチ]` | フルパイプライン：check → commit → push → PR（デフォルト：`main`） |
| `/smart:push` | check → commit → push（PR は作成しない） |
| `/smart:commit` | コミットのみ（スマートグルーピング、メッセージ自動生成） |
| `/smart:check` | ローカル CI チェックのみ実行（workflow 設定を自動検出） |

---

## クイックスタート

**1. プラグインのインストール** _(強く推奨)_

まず Claude Code でプラグインマーケットプレイスを登録します：

```
/plugin marketplace add hinson0/smart-claude-code-plugins
```

次にそのマーケットプレイスからプラグインをインストールします：

```
/plugin install smart@smart-claude-code-plugins
```

**2. GitHub CLI にログイン** _(初回のみ)_

```bash
gh auth login
```

**3. 完了。任意のリポジトリで実行してください：**

```
/smart:pr
```

自動で実行されます：CI 設定を検出しローカルチェックを実行 → スマートコミット → プッシュ → GitHub 上で PR を作成。

---

## 仕組み

```
/smart:pr
    │
    ├── 1. check   — .github/workflows/*.yml を読み取り、対応するローカルチェックを実行
    │                （ruff/pytest、eslint/tsc、go test — CI 設定がなければスキップ）
    │
    ├── 2. commit  — 2フェーズセマンティック分析：
    │                フェーズ1：type で強制分割（feat/fix/refactor/...）
    │                フェーズ2：同一 type 内で目的別に分割
    │                （Conventional Commit message を自動生成）
    │
    ├── 3. push    — origin にプッシュ
    │                （remote 未設定の場合は自動で GitHub リポジトリを作成し紐付け）
    │
    └── 4. pr      — タイトルと本文を自動生成し、Pull Request を作成
                     （言語はステップ 2 の commit message に従う）
```

いずれかのステップが失敗した時点で即座に停止し、後続のステップは実行されません。

---

## ファイル保護

プロジェクトルートに `.claude/.protect_files.jsonc` を作成して、Claude が機密ファイルを編集するのをブロックします：

```jsonc
// 保護対象ファイルリスト — Claude Code は編集できません
// ワイルドカードなしは正確なファイル名マッチング、* または ** 付きは glob パターンマッチング
[
  ".env",
  "package-lock.json",
  "pnpm-lock.yaml",
  "yarn.lock",
  "*.secret",
  "config/production/**"
]
```

**マッチングルール：**
- ワイルドカードなし → 正確なファイル名マッチング（`.env` は `.env` をブロックしますが `.env.example` は許可）
- `*` → 単一ディレクトリレベルの glob マッチング（`*.lock` は `pnpm-lock.yaml` にマッチ）
- `**` → ディレクトリを横断する再帰マッチング（`config/production/**` は `config/production/db/secret.json` にマッチ）

---

## 前提条件

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — GitHub remote の自動作成と PR 作成に使用

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
