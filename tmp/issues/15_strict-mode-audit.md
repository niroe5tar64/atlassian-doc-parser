# Issue 15: strict モード総点検

- status: open
- estimate: 60m
- depends_on: 13,14
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#変換マトリクス固定`

## 目的

warning category ごとに strict=true の失敗挙動を検証し、契約の抜け漏れをなくす。

## 触るファイル

- `tests/integration/AtlassianStrictMode_test.res`
- `tests/fixtures/`（strict 用 fixture を必要分追加）

## 実装タスク

1. `UNSUPPORTED_ELEMENT` 用 strict ケースを追加する。
2. `UNSUPPORTED_MACRO` 用 strict ケースを追加する。
3. `UNSUPPORTED_INLINE` 用 strict ケースを追加する。
4. `INVALID_STRUCTURE` / `CONVERSION_ERROR` の strict ケースを追加する。

## 受け入れ条件

- 各 category で strict=true が `StrictModeViolation` になる。
- strict=false は warning 記録で継続する比較テストがある。
