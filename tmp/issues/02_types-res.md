# Issue 02: Types.res 実装

- status: open
- estimate: 60m
- depends_on: 01
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#ir中間表現`

## 目的

公開 API 型と IR 型を `Types.res` に定義し、以降の実装で共通利用できる状態にする。

## 触るファイル

- `src/Types.res`
- `tests/unit/Types_test.res`

## 実装タスク

1. `convertOptions`, `convertResult`, `convertStats` を定義する。
2. `blockNode` / `inlineNode` / `document` の variant 型を定義する。
3. `types` が参照できることを確認する最小 unit test を作る。

## 受け入れ条件

- 型定義がコンパイル通過する。
- unit test で主要コンストラクタを1回以上生成できる。
