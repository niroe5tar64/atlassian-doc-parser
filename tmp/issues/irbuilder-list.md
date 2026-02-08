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

## ReScript コード例

### リスト変換の基本パターン

```rescript
// <ul> → BulletList、<ol> → OrderedList
// <li> の children にはテキスト/インラインとネストリストが混在しうる

| (Tag, Some("ul")) =>
  BulletList(node.children->Array.map(child => buildListItem(child, diag, ~strict)))

| (Tag, Some("ol")) =>
  OrderedList(node.children->Array.map(child => buildListItem(child, diag, ~strict)))
```

### listItem の構築（ネストリスト対応）

```rescript
// <li> の子要素を走査し、ブロック要素に分類する
// テキスト/インラインは暗黙の Paragraph として扱い、
// ネストリスト（<ul>/<ol>）はそのまま blockNode として再帰処理

and buildListItem = (
  node: ConfluenceInputXml.xmlNode,
  diag: Diagnostics.t,
  ~strict: bool,
): Types.listItem => {
  // children を「インライン要素」と「ブロック要素（ネストリスト等）」に分離
  let blocks: array<Types.blockNode> = []
  let inlines: array<Types.inlineNode> = []

  node.children->Array.forEach(child => {
    switch (child.nodeType, child.name) {
    | (Tag, Some("ul")) | (Tag, Some("ol")) => {
        // 先行するインラインがあれば Paragraph にまとめて flush
        if Array.length(inlines) > 0 {
          blocks->Array.push(Paragraph(inlines->Array.copy))
          // inlines をクリア（Array.splice 等で）
        }
        blocks->Array.push(buildBlock(child, diag, ~strict))
      }
    | _ =>
      inlines->Array.push(buildInline(child, diag, ~strict))
    }
  })

  // 残りのインラインがあれば Paragraph にまとめる
  if Array.length(inlines) > 0 {
    blocks->Array.push(Paragraph(inlines->Array.copy))
  }

  {children: blocks}
}
```

### テスト例

```rescript
test("B08: nested list", () => {
  let doc = buildFromXml("<ul><li>A<ul><li>B</li></ul></li></ul>")
  switch doc.children[0] {
  | Some(BulletList([{children: [Paragraph([Text("A")]), BulletList([_])]}])) =>
    expect(true)->toBe(true)
  | _ => expect(true)->toBe(false)
  }
})
```

### 補足: 不正構造の扱い

```rescript
// 親なし <li> が出現した場合
| (Tag, Some("li")) => {
    Diagnostics.addWarning(diag, "[INVALID_STRUCTURE] li without parent ul/ol")
    if strict {
      raise(Types.ConvertError({code: StrictModeViolation, message: "li without parent ul/ol"}))
    }
    // Best Effort: Paragraph として扱う
    Paragraph(buildInlineChildren(node, diag, ~strict))
  }
```

## 受け入れ条件

- 単純リストとネストリストの unit test が通る。
- `INVALID_STRUCTURE` のテストが最低1件ある。
