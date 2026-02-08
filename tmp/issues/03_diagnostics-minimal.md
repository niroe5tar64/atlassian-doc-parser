# Issue 03: Diagnostics 最小実装

- status: open
- estimate: 60m
- depends_on: 02
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#テスト戦略`

## 目的

warning の追加と stats 集計の最小機能を提供し、IrBuilder が副作用的に診断情報を貯められるようにする。

## 触るファイル

- `src/Diagnostics.res`
- `tests/unit/Diagnostics_test.res`

## 実装タスク

1. diagnostics state の初期化関数を作る。
2. warning 追加関数を作る（`[CATEGORY] ...` 形式）。
3. `unsupportedNodeCount` / `macroCount` の加算関数を作る。
4. state から `warnings` と `stats` を取り出す関数を作る。

## 受け入れ条件

- warning 追加で配列が増えるテストが通る。
- stats 加算結果が期待値と一致するテストが通る。
