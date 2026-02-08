# Issue: IrBuilder（list）

- status: open
- estimate: 90m
- depends_on: irbuilder-basic.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#markdown出力規約固定`

## 目的

`ul/ol/li` を IR の `BulletList` / `OrderedList` / `listItem` に変換し、ネスト構造を保持する。

## 触るファイル

- `src/IrBuilder.res`
- `tests/unit/IrBuilder_test.res`

## 実装タスク

1. `<ul><li>` を `BulletList` へ変換する。
2. `<ol><li>` を `OrderedList` へ変換する。
3. ネストリストを `listItem.children: array<blockNode>` で保持する。
4. 不正構造（親なし `li`）の warning 方針を適用する。

## 受け入れ条件

- 単純リストとネストリストの unit test が通る。
- `INVALID_STRUCTURE` のテストが最低1件ある。
