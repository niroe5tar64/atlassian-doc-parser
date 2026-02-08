# Issue 08: IrBuilder（link/image）

- status: open
- estimate: 90m
- depends_on: 06
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#変換マトリクス固定`

## 目的

外部リンク、内部リンク、外部画像、添付画像を仕様どおりに変換する。

## 触るファイル

- `src/IrBuilder.res`
- `tests/unit/IrBuilder_test.res`

## 実装タスク

1. `<a href>` -> `Link` を実装する。
2. `ac:link + ri:page` -> `confluence-internal://...` を実装する。
3. `ac:image + ri:url` -> `Image(url)` を実装する。
4. `ac:image + ri:attachment` -> `confluence-attachment://...` を実装する。

## 受け入れ条件

- link/image の4パターンが unit test で通る。
- これらは warning を出さない。
