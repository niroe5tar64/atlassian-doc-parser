# Issue: IrBuilder（table）

- status: open
- estimate: 90m
- depends_on: irbuilder-basic.md, diagnostics-minimal.md
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

## ReScript コード例

### テーブル変換の全体像

```rescript
// <table> → Table IR
// 1. <tr> を走査し、<th> を含む行を headers、残りを rows にする
// 2. 列数不一致があれば空セルで補完
// 3. セル内はインラインノードのみ（tableCell = {children: array<inlineNode>}）

| (Tag, Some("table")) => {
    let rows = extractTableRows(node)  // <tbody> の中身も含めて <tr> を抽出
    let (headerRow, dataRows) = splitHeaderRow(rows)
    let maxCols = calcMaxColumns(headerRow, dataRows)

    // 列数不一致チェック
    if hasInconsistentColumns(dataRows, maxCols) {
      Diagnostics.addWarning(diag, "[INVALID_STRUCTURE] table: inconsistent column count")
      if strict {
        raise(Types.ConvertError({
          code: StrictModeViolation,
          message: "table: inconsistent column count",
        }))
      }
    }

    Table({
      headers: headerRow->Option.map(row => padCells(row, maxCols)),
      rows: dataRows->Array.map(row => padCells(row, maxCols)),
    })
  }
```

### 空セル補完

```rescript
// 列数が足りない行に空セルを追加する
let padCells = (
  row: array<Types.tableCell>,
  maxCols: int,
): array<Types.tableCell> => {
  let current = Array.length(row)
  if current >= maxCols {
    row
  } else {
    // 不足分を空セルで埋める
    let padding = Array.make(~length=maxCols - current, ({children: []}: Types.tableCell))
    Array.concat(row, padding)
  }
}
```

### セル内ブロック要素のインライン化（正本 4.4 節）

```rescript
// <td> の子が <p> × 複数の場合は LineBreak で結合
let buildTableCell = (
  node: ConfluenceInputXml.xmlNode,
  diag: Diagnostics.t,
  ~strict: bool,
): Types.tableCell => {
  let paragraphs = node.children->Array.filter(c =>
    c.nodeType == Tag && c.name == Some("p")
  )

  let inlines = switch Array.length(paragraphs) {
  | 0 => buildInlineChildren(node, diag, ~strict)
  | 1 => buildInlineChildren(paragraphs[0]->Option.getExn, diag, ~strict)
  | _ =>
    // 複数 <p> を LineBreak で結合
    paragraphs
    ->Array.mapWithIndex((p, i) => {
        let children = buildInlineChildren(p, diag, ~strict)
        if i > 0 {
          Array.concat([Types.LineBreak], children)
        } else {
          children
        }
      })
    ->Array.flat
  }

  {children: inlines}
}
```

### テスト例

```rescript
test("B09: table with headers", () => {
  let xml = "<table><tbody><tr><th>H</th></tr><tr><td>C</td></tr></tbody></table>"
  let doc = buildFromXml(xml)
  switch doc.children[0] {
  | Some(Table({headers: Some(_), rows: [_]})) => expect(true)->toBe(true)
  | _ => expect(true)->toBe(false)
  }
})

test("B10: table without headers", () => {
  let xml = "<table><tbody><tr><td>C</td></tr></tbody></table>"
  let doc = buildFromXml(xml)
  switch doc.children[0] {
  | Some(Table({headers: None, rows: [_]})) => expect(true)->toBe(true)
  | _ => expect(true)->toBe(false)
  }
})
```

## 受け入れ条件

- 正常テーブルと列不一致テーブルの unit test が通る。
- strict=false では継続、strict=true では例外になる。
