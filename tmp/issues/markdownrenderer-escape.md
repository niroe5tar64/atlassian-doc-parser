# Issue: MarkdownRenderer（text escape）

- status: open
- estimate: 75m
- depends_on: types-res.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#markdownrendererのエスケープ境界`

## 目的

Text ノードの文脈依存エスケープを実装し、Markdown 誤解釈を防ぐ。

## 触るファイル

- `src/MarkdownRenderer.res`
- `tests/unit/MarkdownRenderer_test.res`

## 実装タスク

1. 通常 text のエスケープ文字（`\\ * _ [ ] \` < >`）を実装する。
2. テーブルセル内で `|` を追加エスケープする。
3. `InlineCode` / `CodeBlock` / URL はエスケープしない境界を守る。

## 受け入れ条件

- 通常文脈とセル文脈の unit test が通る。
- InlineCode と URL が過剰エスケープされない。
