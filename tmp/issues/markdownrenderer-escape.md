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

## ReScript コード例

### 文脈依存エスケープの設計

```rescript
// src/MarkdownRenderer.res

// テーブルセル内かどうかでエスケープ対象が変わる
type context = Normal | TableCell

// 通常エスケープ対象: \ * _ [ ] ` < >
// テーブルセル内は上記 + |
let escapeText = (text: string, ctx: context): string => {
  // %re("/.../g") は ReScript の正規表現リテラル（g フラグ = 全置換）
  let escaped = text
    ->String.replaceRegExp(%re("/\\\\/g"), "\\\\\\\\")  // \ → \\（最初に処理）
    ->String.replaceRegExp(%re("/\\*/g"), "\\\\*")
    ->String.replaceRegExp(%re("/_/g"), "\\\\_")
    ->String.replaceRegExp(%re("/\\[/g"), "\\\\[")
    ->String.replaceRegExp(%re("/\\]/g"), "\\\\]")
    ->String.replaceRegExp(%re("/`/g"), "\\\\`")
    ->String.replaceRegExp(%re("/</g"), "\\\\<")
    ->String.replaceRegExp(%re("/>/g"), "\\\\>")

  switch ctx {
  | TableCell => escaped->String.replaceRegExp(%re("/\\|/g"), "\\\\|")
  | Normal => escaped
  }
}
```

### インラインノードをレンダリングする関数

```rescript
// インラインノード → 文字列の変換
let rec renderInline = (node: Types.inlineNode, ctx: context): string => {
  switch node {
  | Text(s) => escapeText(s, ctx)                          // エスケープあり
  | Strong(children) => `**${renderInlines(children, ctx)}**`
  | Emphasis(children) => `*${renderInlines(children, ctx)}*`
  | Strikethrough(children) => `~~${renderInlines(children, ctx)}~~`
  | InlineCode(s) => "`" ++ s ++ "`"                       // エスケープなし
  | Link({href, children}) =>
    `[${renderInlines(children, ctx)}](${href})`           // URL もエスケープなし
  | Image({src, alt}) => {
      let altText = alt->Option.getOr("")
      `![${altText}](${src})`
    }
  | LineBreak =>
    switch ctx {
    | Normal => "  \n"                                     // 末尾2スペース + 改行
    | TableCell => "<br>"                                  // HTML タグ
    }
  | UnsupportedInline(summary) => `<!-- unsupported inline: ${summary} -->`
  }
}

// 複数のインラインノードを連結
and renderInlines = (nodes: array<Types.inlineNode>, ctx: context): string => {
  nodes->Array.map(n => renderInline(n, ctx))->Array.join("")
}
```

### テスト例

```rescript
describe("MarkdownRenderer.escapeText", () => {
  test("escapes special characters in normal context", () => {
    let result = escapeText("a * b _ c", Normal)
    expect(result)->toBe("a \\* b \\_ c")
  })

  test("escapes pipe in table context", () => {
    let result = escapeText("a | b", TableCell)
    expect(result)->toBe("a \\| b")
  })

  test("does not escape inside InlineCode", () => {
    let result = renderInline(InlineCode("a * b"), Normal)
    expect(result)->toBe("`a * b`")
  })
})
```

## 受け入れ条件

- 通常文脈とセル文脈の unit test が通る。
- InlineCode と URL が過剰エスケープされない。
