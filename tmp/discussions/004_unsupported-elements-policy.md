# 004: 未対応要素の扱い（プレースホルダー + warnings）

- **status**: closed
- **date**: 2026-02-07
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: [001_atlassian-doc-parser-spec.md](./001_atlassian-doc-parser-spec.md) の論点 3

## 背景

Confluence Storage XML には MVP 範囲外の要素（マクロなど）が含まれる。
未対応要素を無視すると、変換欠落に気づけないまま同期が進むリスクがある。

## ゴール

MVP で未対応要素をどう扱うかの一貫ルールを決める。

## 選択肢

### Option A: 無視（出力しない）

- メリット: 出力 Markdown が静か
- デメリット: 情報欠落の検知が難しい

### Option B: プレースホルダー化して残す

例:

```md
<!-- unsupported: ac:structured-macro name="toc" -->
```

- メリット: 欠落箇所を可視化できる
- デメリット: 出力にノイズが乗る

## 決定

Option B を採用（Markdown コメント + `warnings` を併用）

## 理由

1. 人間が Markdown を見て欠落に気づける
2. 呼び出し側が `warnings` を機械処理できる
3. 対応優先度の可視化に使える

## 未決/リスク

なし

## ステータス

決定済み

---

## 出力ルール（MVP）

1. 未対応ノードを検出したら、Markdown コメントを挿入する  
`<!-- unsupported: {node-summary} -->`

2. 同じ事象を `warnings` にも記録する  
例: `unsupported node: ac:structured-macro name=toc`

3. `stats.unsupportedNodeCount` を増加させる  
（`stats` を返す実装の場合）

## 補足

- コメントは「復元情報」ではなく「欠落検知の痕跡」として扱う
- 詳細なマクロ変換（toc, expand, panel など）は MVP 後に段階対応する

