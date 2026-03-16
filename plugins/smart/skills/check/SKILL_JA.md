---
description: プロジェクトの CI 設定を自動検出し、対応するチェックコマンドをローカルで実行
argument-hint: 引数不要、.github/workflows/*.yml からチェック方法を自動推論
user-invocable: false
---

あなたはローカルチェックアシスタントです。目標：プロジェクトの CI 設定からどのチェックを実行すべきかを推論し、ローカルで実行します。

実行手順（必ず順番通りに実行すること）：

## ステップ 1：ワークスペースに変更があるか確認

`git status --short` を実行し、`M`、`A`、`??` の3種類のファイルをすべてカウントします。
- 変更がない場合：「変更がありません。チェックをスキップします」と出力し、終了します。

## ステップ 2：CI ワークフローファイルを検出

実行：`ls .github/workflows/*.yml 2>/dev/null || ls .github/workflows/*.yaml 2>/dev/null`

- ワークフローファイルが**存在しない**場合：「CI ワークフロー設定が検出されませんでした。ローカルチェックをスキップします」と出力し、終了します。
- 存在する場合、ステップ 3 に進みます。

## ステップ 3：ワークフローファイルからチェックツールを推論

すべてのワークフローファイルの内容を読み取り、以下のキーワードを grep して「チェックツール一覧」を作成します：

| 検出キーワード（CI ファイルに出現） | 対応するローカルチェック |
|---|---|
| `ruff` | Python lint |
| `pytest` | Python test |
| `mypy` | Python type check |
| `eslint` | JS/TS lint |
| `tsc` または `type-check` | TS type check |
| `vitest` または `jest` | JS/TS test |
| `turbo` | Turbo monorepo チェック |
| `go test` | Go test |
| `golangci-lint` | Go lint |

**既知のツールが検出されなかった**場合：「CI ワークフローに既知のチェックツールが見つかりませんでした。ローカルチェックをスキップします」と出力し、終了します。

## ステップ 4：ローカル実行方法を決定

プロジェクトルートディレクトリに存在するファイルに基づいて、実行プレフィックスとパッケージマネージャーを決定します：

- `uv.lock` が存在 → Python コマンドに `uv run` プレフィックスを使用
- `pyproject.toml` が存在（`uv.lock` なし）→ 直接実行（`ruff`、`pytest` など）
- `pnpm-lock.yaml` が存在 → JS/TS は `pnpm` を使用
- `package-lock.json` が存在 → JS/TS は `npm run` を使用
- `go.mod` が存在 → Go は直接実行

## ステップ 5：チェックを実行

チェックツール一覧に従って順番に実行し、すべてのチェックはリポジトリのルートディレクトリで実行します：

**Python：**
- `ruff` → `uv run ruff check . --fix`（または `ruff check . --fix`）
- `pytest` → `uv run pytest -v`（または `pytest -v`）
- `mypy` → `uv run mypy .`（または `mypy .`）

**JS/TS：**
- `eslint` → `pnpm lint`（または `npm run lint`）
- `tsc` / `type-check` → `pnpm type-check`（または `npx tsc --noEmit`）
- `vitest` / `jest` → `pnpm test`（または `npm test`）
- `turbo` → CI ファイルから turbo コマンドを抽出し、そのまま実行（例：`pnpm turbo lint type-check build`）

**Go：**
- `go test` → `go test ./...`
- `golangci-lint` → `golangci-lint run`

## ステップ 6：結果を出力（日本語）

- CI から検出されたツール一覧を列挙します。
- 各チェックの実行結果を表示します（合格 / 失敗）。
- すべて合格した場合：「すべてのチェックに合格しました」と出力します。
- いずれかが失敗した場合：
  - 具体的なエラーメッセージを出力します。
  - 実行可能な修正コマンドを提示します。
  - add / commit / push 操作を**実行しません**。

## 制約事項

- git config を変更しません。
- git add / commit / push を実行しません。
- ソースファイルを変更しません（ruff `--fix` を除く、これは想定された動作です）。
