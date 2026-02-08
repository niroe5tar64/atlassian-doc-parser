# Issue: IrBuilder（装飾系: strong/em/code/del）

- status: open
- estimate: 75m
- depends_on: irbuilder-basic.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#主要ノード一覧`

## 目的

基本インライン装飾要素を IR に変換できるようにする。

## 触るファイル

- `src/IrBuilder.res`
- `tests/unit/IrBuilder_test.res`

## 実装タスク

1. `<strong>/<b>` -> `Strong` を実装する。
2. `<em>/<i>` -> `Emphasis` を実装する。
3. `<code>` -> `InlineCode` を実装する。
4. `<del>/<s>` -> `Strikethrough` を実装する。

## 受け入れ条件

- 4要素の unit test が通る。
- ネストしたインライン（例: strong の内側に em）が壊れない。
