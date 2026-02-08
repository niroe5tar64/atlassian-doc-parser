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

## ReScript コード例

### buildInline に新しい arm を追加する

```rescript
// irbuilder-basic で作った buildInline 関数の switch に、新しいパターンを追加する

and buildInline = (node, diag, ~strict) => {
  switch (node.nodeType, node.name) {
  | (Text, _) => Text(normalizeWhitespace(node.data->Option.getOr("")))

  // --- ここから追加 ---

  // <strong> / <b> → Strong（children を再帰変換）
  | (Tag, Some("strong")) | (Tag, Some("b")) =>
    Strong(buildInlineChildren(node, diag, ~strict))

  // <em> / <i> → Emphasis
  | (Tag, Some("em")) | (Tag, Some("i")) =>
    Emphasis(buildInlineChildren(node, diag, ~strict))

  // <code> → InlineCode（子テキストを結合、空白正規化しない）
  | (Tag, Some("code")) =>
    InlineCode(extractText(node))  // extractText は子の data を結合するヘルパー

  // <del> / <s> → Strikethrough
  | (Tag, Some("del")) | (Tag, Some("s")) =>
    Strikethrough(buildInlineChildren(node, diag, ~strict))

  // <u> / <sub> / <sup> → transparent（子要素をそのまま返す）
  // ※ transparent は親にインライン子を展開するため、呼び出し側で flatten が必要
  // --- ここまで追加 ---

  | _ => UnsupportedInline(node.name->Option.getOr("unknown"))
  }
}
```

### `|` パターンの OR 結合

```rescript
// 複数のパターンを | で結合すると「どちらかに一致」の意味になる
| (Tag, Some("strong")) | (Tag, Some("b")) =>
  Strong(buildInlineChildren(node, diag, ~strict))

// これは以下と等価:
// | (Tag, Some("strong")) => Strong(buildInlineChildren(node, diag, ~strict))
// | (Tag, Some("b")) => Strong(buildInlineChildren(node, diag, ~strict))
```

### transparent 要素のテスト

```rescript
test("B26: <u> outputs text only (transparent)", () => {
  let doc = buildFromXml("<p><u>underlined</u></p>")
  // <u> は装飾を落としてテキストのみ出力される
  switch doc.children[0] {
  | Some(Paragraph([Text("underlined")])) => expect(true)->toBe(true)
  | _ => expect(true)->toBe(false)
  }
})

test("B29: nested inline", () => {
  let doc = buildFromXml("<p><strong><em>text</em></strong></p>")
  switch doc.children[0] {
  | Some(Paragraph([Strong([Emphasis([Text("text")])])])) => expect(true)->toBe(true)
  | _ => expect(true)->toBe(false)
  }
})
```

## 受け入れ条件

- 4要素の unit test が通る。
- ネストしたインライン（例: strong の内側に em）が壊れない。
