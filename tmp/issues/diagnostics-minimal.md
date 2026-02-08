# Issue: Diagnostics 最小実装

- status: open
- estimate: 60m
- depends_on: types-res.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#テスト戦略`

## 目的

warning の追加と stats 集計の最小機能を提供し、IrBuilder が副作用的に診断情報を貯められるようにする。

## 触るファイル

- `src/Diagnostics.res`
- `tests/unit/Diagnostics_test.res`

## 実装タスク

1. diagnostics state の初期化関数を作る。
2. warning 追加関数を作る（`[CATEGORY] ...` 形式）。
3. `unsupportedNodeCount` / `macroCount` の加算関数を作る。
4. state から `warnings` と `stats` を取り出す関数を作る。

## ReScript コード例

### opaque type + ref で可変コンテナを作る

```rescript
// src/Diagnostics.res

// type t: 外部からは内部構造が見えない「抽象型」
// ref: ReScript の可変参照。{ contents: 値 } で JS オブジェクトになる
type t = {
  warnings: ref<array<string>>,
  unsupportedNodeCount: ref<int>,
  macroCount: ref<int>,
}

// create: unit => t（引数なしで新しいインスタンスを作る）
let create = (): t => {
  warnings: ref([]),
  unsupportedNodeCount: ref(0),
  macroCount: ref(0),
}

// ref の更新: .contents への代入
let addWarning = (diag: t, message: string): unit => {
  diag.warnings.contents = Array.concat(diag.warnings.contents, [message])
}

let incrementUnsupported = (diag: t): unit => {
  diag.unsupportedNodeCount.contents = diag.unsupportedNodeCount.contents + 1
}

let incrementMacro = (diag: t): unit => {
  diag.macroCount.contents = diag.macroCount.contents + 1
}

// ref の読み出し: .contents でアクセス
let getWarnings = (diag: t): array<string> => {
  diag.warnings.contents
}

// stats が全て 0 なら None を返す（正本の ConvertResult.stats?: の仕様に対応）
let getStats = (diag: t): option<Types.convertStats> => {
  let u = diag.unsupportedNodeCount.contents
  let m = diag.macroCount.contents
  if u == 0 && m == 0 {
    None
  } else {
    Some({unsupportedNodeCount: u, macroCount: m})
  }
}
```

### テストの書き方

```rescript
// tests/unit/Diagnostics_test.res

describe("Diagnostics", () => {
  test("addWarning accumulates warnings", () => {
    let d = Diagnostics.create()
    Diagnostics.addWarning(d, "[UNSUPPORTED_ELEMENT] div")
    Diagnostics.addWarning(d, "[UNSUPPORTED_MACRO] toc")
    expect(Array.length(Diagnostics.getWarnings(d)))->toBe(2)
  })

  test("getStats returns None when no events", () => {
    let d = Diagnostics.create()
    expect(Diagnostics.getStats(d))->toBe(None)
  })
})
```

## 受け入れ条件

- warning 追加で配列が増えるテストが通る。
- stats 加算結果が期待値と一致するテストが通る。
