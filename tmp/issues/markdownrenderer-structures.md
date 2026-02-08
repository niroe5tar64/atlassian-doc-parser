# Issue: MarkdownRenderer（list/table/code fence）

- status: open
- estimate: 90m
- depends_on: markdownrenderer-escape.md
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

## ReScript コード例

### ネストリストのインデント（マーカー幅ベース）

```rescript
// 正本の規約: `- ` → 2 スペース、`N. ` → digits(N)+2 スペース
// 例: `1. ` → 3、`10. ` → 4

let rec renderBlock = (node: Types.blockNode, indent: string): string => {
  switch node {
  | BulletList(items) =>
    items
    ->Array.mapWithIndex((item, _i) => {
        let marker = "- "
        let childIndent = indent ++ String.repeat(" ", String.length(marker))
        renderListItem(item, indent ++ marker, childIndent)
      })
    ->Array.join("\n")

  | OrderedList(items) =>
    items
    ->Array.mapWithIndex((item, i) => {
        let num = Int.toString(i + 1)
        let marker = `${num}. `
        let childIndent = indent ++ String.repeat(" ", String.length(marker))
        renderListItem(item, indent ++ marker, childIndent)
      })
    ->Array.join("\n")
  // ...
  }
}
```

### ヘッダーなしテーブルの空ヘッダー合成

```rescript
// headers: None の場合、rows の最大列数に合わせて空ヘッダーを生成
let renderTable = (
  headers: option<array<Types.tableCell>>,
  rows: array<array<Types.tableCell>>,
): string => {
  let maxCols = switch headers {
  | Some(h) => Array.length(h)
  | None => rows->Array.reduce(0, (max, row) => Math.Int.max(max, Array.length(row)))
  }

  // ヘッダー行
  let headerRow = switch headers {
  | Some(cells) => renderTableRow(cells)
  | None => "| " ++ Array.make(~length=maxCols, " ")->Array.join(" | ") ++ " |"
  }

  // 区切り行
  let separator = "| " ++ Array.make(~length=maxCols, "---")->Array.join(" | ") ++ " |"

  // データ行
  let dataRows = rows->Array.map(renderTableRow)->Array.join("\n")

  headerRow ++ "\n" ++ separator ++ "\n" ++ dataRows
}
```

### Code fence 衝突回避

```rescript
// コード本文中の連続バッククォートの最大長を調べ、それ + 1 の fence を使う
let codeFenceLength = (content: string): int => {
  // 正規表現で連続バッククォートを探す
  let maxLen = ref(0)
  let re = %re("/`+/g")
  let rec findAll = () => {
    switch re->RegExp.exec(content) {
    | Some(result) => {
        let len = String.length(RegExp.Result.fullMatch(result))
        if len > maxLen.contents {
          maxLen := len
        }
        findAll()
      }
    | None => ()
    }
  }
  findAll()
  Math.Int.max(3, maxLen.contents + 1)  // 最低 3
}

// 使い方:
// content = "const s = \"```\";"
// codeFenceLength(content) => 4
// fence = String.repeat("`", 4) => "````"
```

### テスト例

```rescript
test("C05: nested bullet list indentation", () => {
  let ir: Types.document = {
    children: [
      BulletList([
        {children: [Paragraph([Text("A")]), BulletList([{children: [Paragraph([Text("B")])]}])]},
      ]),
    ],
  }
  let md = MarkdownRenderer.render(ir)
  expect(md)->toBe("- A\n  - B")
})

test("code fence avoids backtick collision", () => {
  let ir: Types.document = {
    children: [CodeBlock({language: None, content: "use ``` here"})],
  }
  let md = MarkdownRenderer.render(ir)
  // 4 つのバッククォートで囲まれることを確認
  expect(String.startsWith(md, "````"))->toBe(true)
})
```

## 受け入れ条件

- list/table/codeblock の unit test が通る。
- `10. item` ネストと fence 衝突ケースのテストがある。
