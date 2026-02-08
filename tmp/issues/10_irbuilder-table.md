# Issue 10: IrBuilder（table）

- status: open
- estimate: 90m
- depends_on: 06,03
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#変換マトリクス固定`

## 目的

テーブルを `Table` IR に変換し、不整合構造の補正と diagnostics 連携を実装する。

## 触るファイル

- `src/IrBuilder.res`
- `tests/unit/IrBuilder_test.res`

## 実装タスク

1. `<table><tr><th>/<td>` を `Table` に変換する。
2. 列数不一致時の空セル補完を実装する。
3. 構造不正時に `INVALID_STRUCTURE` または `CONVERSION_ERROR` を記録する。
4. strict=true で `StrictModeViolation` に昇格する分岐を追加する。

## 受け入れ条件

- 正常テーブルと列不一致テーブルの unit test が通る。
- strict=false では継続、strict=true では例外になる。
