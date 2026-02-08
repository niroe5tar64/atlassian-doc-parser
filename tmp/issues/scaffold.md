# Issue: scaffold 作成

- status: open
- estimate: 45m
- depends_on: なし
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx`
  - `tmp/discussions/007_rescript-directory-structure.md`

## 目的

実装を始める前に、`src/` と `tests/` の最小構成を作り、コンパイルとテスト実行の土台を固定する。

## 触るファイル

- `src/AtlassianDocParser.res`
- `src/AtlassianDocParser.resi`
- `tests/integration/AtlassianDocParser_test.res`

## 実装タスク

1. 仕様で定義された公開関数シグネチャだけを持つ最小 stub を作る。
2. `tests/integration/` に最小テストファイルを作り、テスト検出を確認する。
3. `bun test` が実行できることを確認する。

## ReScript コード例

### .resi（インターフェースファイル）で公開 API を宣言する

```rescript
// src/AtlassianDocParser.resi
// .resi は TypeScript の .d.ts に相当。外部に公開する型と関数を宣言する。

// 型は .resi にも書く必要がある（公開する型のみ）
type convertOptions = {strict?: bool}
type convertStats = {unsupportedNodeCount: int, macroCount: int}
type convertResult = {markdown: string, warnings: array<string>, stats?: convertStats}

// 公開する関数のシグネチャ
// ~options は「ラベル付き引数」、=? は「省略可能」の意味
let convertConfluenceStorageToMarkdown: (string, ~options: convertOptions=?) => convertResult
```

### .res（実装ファイル）に stub を書く

```rescript
// src/AtlassianDocParser.res
// scaffold 段階では最小限の stub だけ。後続 issue で本体を実装する。

type convertOptions = {strict?: bool}
type convertStats = {unsupportedNodeCount: int, macroCount: int}
type convertResult = {markdown: string, warnings: array<string>, stats?: convertStats}

let convertConfluenceStorageToMarkdown = (
  _input: string,    // _ プレフィックスで「未使用」を明示（コンパイル警告を抑制）
  ~options as _options: convertOptions=?,
) => {
  // stub: 空の結果を返す（後続 issue で実装）
  {markdown: "", warnings: [], stats: ?None}
}
```

### Bun Test を ReScript から呼ぶ

```rescript
// tests/integration/AtlassianDocParser_test.res

// Bun のテスト API は @module で FFI バインディングする。
// プロジェクトに既存の tests/unit/toolchain.smoke.test.js を参考に、
// describe / test / expect を使う。
//
// ReScript から Bun Test を呼ぶ最小パターン:
@val external describe: (string, unit => unit) => unit = "describe"
@val external test: (string, unit => unit) => unit = "test"

// expect は「任意の値を受け取り、matcher オブジェクトを返す」関数
type expectResult
@val external expect: 'a => expectResult = "expect"
@send external toBe: (expectResult, 'a) => unit = "toBe"

describe("AtlassianDocParser", () => {
  test("stub returns empty markdown", () => {
    let result = AtlassianDocParser.convertConfluenceStorageToMarkdown("")
    expect(result.markdown)->toBe("")
  })
})
```

### ビルドと実行

```bash
# ReScript コンパイル → JS 生成 → テスト実行
npx rescript && bun test
```

## 受け入れ条件

- `bun test` が失敗せず完走する。
- 新規ディレクトリとファイルが意図通りに作成される。
