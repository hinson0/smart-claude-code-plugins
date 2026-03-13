# smart-claude-code-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> コードを書き終えたら `/smart:pr` を実行するだけ。あとは全部おまかせ。
>
> PR はいらない、push だけしたい？了解 — `/smart:push`。
> push もいらない、commit だけ？もちろん — `/smart:commit`。
> コミット前にチェックだけ走らせたい？お好きにどうぞ — `/smart:check`。

Claude Code 向けのプラグインです。コードを書き終えたら、コマンドをひとつ実行するだけ — 自動でチェック、コミット、プッシュし、`main` ブランチへの Pull Request を作成します。追加の操作は一切不要です。

---

## クイックスタート

**1. プラグインのインストール** _(強く推奨)_

まず Claude Code でプラグインマーケットプレイスを登録します：

```
/plugin marketplace add hinson0/smart-claude-code-plugin
```

次にそのマーケットプレイスからプラグインをインストールします：

```
/plugin install smart@smart-claude-code-plugin
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
    ├── 2. commit  — 変更内容をセマンティック分析し、commit message を自動生成
    │                （独立した feature が複数ある場合は自動的に複数のコミットに分割）
    │
    ├── 3. push    — origin にプッシュ
    │                （remote 未設定の場合は自動で GitHub リポジトリを作成し紐付け）
    │
    └── 4. pr      — タイトルと本文を自動生成し、Pull Request を作成
```

いずれかのステップが失敗した時点で即座に停止し、後続のステップは実行されません。

---

## 全コマンド

| コマンド | 機能 |
|---|---|
| `/smart:pr [ターゲットブランチ]` | フルパイプライン：check → commit → push → PR（デフォルトのターゲットブランチ：`main`） |
| `/smart:push` | check → commit → push（PR は作成しない） |
| `/smart:commit` | コミットのみ（スマートグルーピング、メッセージ自動生成） |
| `/smart:check` | CI 設定から推論されたローカルチェックのみ実行 |

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
