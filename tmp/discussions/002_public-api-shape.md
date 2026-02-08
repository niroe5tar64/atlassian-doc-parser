# 002: 公開 API の形（ConvertResult 採用）

- **status**: closed
- **date**: 2026-02-07
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: [001_atlassian-doc-parser-spec.md](./001_atlassian-doc-parser-spec.md) の論点 1

## 背景

MVP 段階でも、変換結果の品質を運用で観測できることが必要。
特に `atlassian-doc-parser` は `confluence-mirror` から利用されるため、未対応要素や変換品質低下を呼び出し側で検知できる API 形状が重要。

## ゴール

`atlassian-doc-parser` の公開 API について、入力・出力の最小契約を決める。

## 選択肢

### Option A: 文字列 in / 文字列 out

```ts
convertConfluenceStorageToMarkdown(input: string, options?: ConvertOptions): string
```

- メリット: 呼び出し側の実装が最小
- デメリット: warning や統計値を返せない

### Option B: 結果オブジェクトを返す

```ts
type ConvertResult = {
  markdown: string
  warnings: string[]
  stats?: {
    unsupportedNodeCount: number
    macroCount: number
  }
}

convertConfluenceStorageToMarkdown(
  input: string,
  options?: ConvertOptions
): ConvertResult
```

- メリット: warning と統計値を機械処理しやすい
- デメリット: 呼び出し側で `result.markdown` を扱う必要がある

## 決定

Option B（`ConvertResult`）を採用

## 理由

1. 未対応要素を warning として外部監視できる
2. GAS/CLI でログ収集しやすい
3. 将来の品質指標追加（stats 拡張）と相性が良い

## 未決/リスク

Option A 相当の string 専用ラッパーは初期実装では追加しない（必要になったタイミングで追加検討）

## ステータス

決定済み

---

## MVP の API 契約（確定）

```ts
export type ConvertResult = {
  markdown: string
  warnings: string[]
  stats?: {
    unsupportedNodeCount: number
    macroCount: number
  }
}

export function convertConfluenceStorageToMarkdown(
  input: string,
  options?: ConvertOptions
): ConvertResult
```

## 補足

- `warnings` は人間可読の診断文字列を格納する
- `stats` は任意とし、MVP 後の拡張余地を残す

