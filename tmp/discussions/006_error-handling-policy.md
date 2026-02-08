# 006: エラーハンドリング方針（Best Effort / Strict）

- **status**: closed
- **date**: 2026-02-07
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: [001_atlassian-doc-parser-spec.md](./001_atlassian-doc-parser-spec.md) の論点 4

## 背景

`atlassian-doc-parser` は本番同期で使うため、異常入力を含むページが一部にあっても処理全体を止めない運用性が必要。
一方で、開発・テストでは不完全変換を早期に検知できる厳格なモードも必要。

## ゴール

不正入力や変換エラー時の挙動を API 契約として明確化し、運用時と検証時で使い分け可能にする。

## 選択肢

### Option A: Fail Fast のみ

- メリット: 失敗条件が単純で分かりやすい
- デメリット: 一部ページの問題で同期全体が停止しやすい

### Option B: Best Effort のみ

- メリット: 同期継続性が高い
- デメリット: 品質問題の顕在化が遅れる

### Option C: デフォルト Best Effort + `strict` 切り替え

- メリット: 本番運用と開発検証の両要件を両立できる
- デメリット: 契約定義がやや増える

## 決定

Option C を採用する。

1. `ConvertOptions.strict?: boolean` を MVP から公開する（default: `false`）
2. `strict=false` は Best Effort
3. `strict=true` は Fail Fast
4. 例外経路では `ConvertResult` を返さず `ConvertError` を throw する

## 理由

1. 本番では同期継続（可用性）を優先できる
2. 開発・テストでは厳格モードで品質問題を早期検知できる
3. warning と例外の境界を API 契約として明示できる

## 未決/リスク

- warning/エラーコードの粒度は実装時に調整余地がある
- `ConvertError` の詳細フィールド（ノード情報、行番号など）は MVP 後に拡張余地がある

## ステータス

決定済み

---

## 事象別の挙動（MVP）

| 事象 | `strict=false` | `strict=true` |
|------|----------------|---------------|
| 未対応要素（例: 未対応マクロ） | warning を追加し、プレースホルダーを出力して継続 | `ConvertError` を throw |
| ノード単位の変換失敗（部分失敗） | warning を追加し、プレースホルダーを出力して継続 | `ConvertError` を throw |
| 不正 XML（文書全体の解釈不能） | `ConvertError` を throw | `ConvertError` を throw |
| 予期しない内部エラー | `ConvertError` を throw | `ConvertError` を throw |

## API 契約（MVP）

```ts
export type ConvertOptions = {
  strict?: boolean // default: false
}

export type ConvertResult = {
  markdown: string
  warnings: string[]
  stats?: {
    unsupportedNodeCount: number
    macroCount: number
  }
}

export class ConvertError extends Error {
  code: "INVALID_XML" | "STRICT_MODE_VIOLATION" | "INTERNAL_ERROR"
}
```

## 補足

- 本番運用では `strict=false`（Best Effort）を推奨
- 開発・テストでは `strict=true`（Strict Mode）を推奨
