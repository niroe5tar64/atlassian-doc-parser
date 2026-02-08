# Issue: Types.res 実装

- status: open
- estimate: 60m
- depends_on: scaffold.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#ir中間表現`

## 目的

公開 API 型と IR 型を `Types.res` に定義し、以降の実装で共通利用できる状態にする。

## 触るファイル

- `src/Types.res`
- `tests/unit/Types_test.res`

## 実装タスク

1. `convertOptions`, `convertResult`, `convertStats` を定義する。
2. `blockNode` / `inlineNode` / `document` の variant 型を定義する。
3. `types` が参照できることを確認する最小 unit test を作る。

## ReScript コード例

### record 型の定義

```rescript
// record 型: JS のオブジェクトに対応する構造体
type convertStats = {
  unsupportedNodeCount: int,
  macroCount: int,
}

// optional フィールドは ? を付ける
type convertOptions = {
  strict?: bool,  // JS 側では undefined | boolean
}

type convertResult = {
  markdown: string,
  warnings: array<string>,
  stats?: convertStats,
}
```

### variant 型（= 直和型、tagged union）

```rescript
// variant 型: TypeScript の discriminated union に相当。
// 各バリアントは「コンストラクタ」と呼ぶ。
// コンストラクタはデータを持てる: Text(string) や Heading({level: int, ...})

type rec inlineNode =
  | Text(string)                              // 文字列データを1つ持つ
  | Strong(array<inlineNode>)                 // 子ノードの配列を持つ（rec で再帰）
  | Emphasis(array<inlineNode>)
  | Strikethrough(array<inlineNode>)
  | InlineCode(string)
  | Link({href: string, children: array<inlineNode>})  // record データを持つ
  | Image({src: string, alt: option<string>})           // option = None | Some(値)
  | LineBreak                                 // データなし
  | UnsupportedInline(string)

// and キーワードで相互再帰型を定義（blockNode と listItem が互いを参照）
type rec listItem = {children: array<blockNode>}
and tableCell = {children: array<inlineNode>}
and blockNode =
  | Heading({level: int, children: array<inlineNode>})
  | Paragraph(array<inlineNode>)
  | BulletList(array<listItem>)
  | OrderedList(array<listItem>)
  | Table({headers: option<array<tableCell>>, rows: array<array<tableCell>>})
  | CodeBlock({language: option<string>, content: string})
  | HorizontalRule
  | Unsupported(string)

type document = {children: array<blockNode>}
```

### variant 値の生成（テストで使う）

```rescript
// コンストラクタ名(引数) で値を生成
let textNode = Text("hello")
let heading = Heading({level: 1, children: [Text("Title")]})
let doc: document = {children: [heading, Paragraph([textNode])]}

// option 型の値
let withAlt = Image({src: "a.png", alt: Some("logo")})
let noAlt = Image({src: "a.png", alt: None})
```

## 受け入れ条件

- 型定義がコンパイル通過する。
- unit test で主要コンストラクタを1回以上生成できる。
