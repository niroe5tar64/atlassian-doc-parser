# Issue 12: MarkdownRenderer（list/table/code fence）

- status: open
- estimate: 90m
- depends_on: 11
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#markdown出力規約固定`

## 目的

Markdown 出力の構造ルール（ネストリスト、テーブル、fence 衝突回避）を実装する。

## 触るファイル

- `src/MarkdownRenderer.res`
- `tests/unit/MarkdownRenderer_test.res`

## 実装タスク

1. ネストリストのインデントをマーカー幅ベースで実装する。
2. ヘッダーなしテーブル時の空ヘッダー合成を実装する。
3. テーブルセル内 `LineBreak` を `<br>` 出力する。
4. code block で backtick 最大長 + 1 の fence を選ぶ。

## 受け入れ条件

- list/table/codeblock の unit test が通る。
- `10. item` ネストと fence 衝突ケースのテストがある。
