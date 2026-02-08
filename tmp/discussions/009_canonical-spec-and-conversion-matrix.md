# 009: 正本ドキュメント確定と変換マトリクス固定

- **status**: closed
- **date**: 2026-02-08
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: 実装移行前の設計固定（会話ログ記録）

## 目的

実装移行時に仕様の参照先がぶれないようにし、要素ごとの変換契約を固定する。

## 決定事項

### 1. 仕様の正本

- `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx` を正本（canonical）とする
- 既存の `tmp/discussions/*.md` は決定経緯の記録として扱う
- 矛盾時は正本を優先する

### 2. 変換マトリクス固定

- 正本に「変換マトリクス（固定）」を追記した
- 各入力要素について、以下を 1 つの表で確定した:
  - IR 出力
  - Markdown 出力
  - warning code
  - `strict=false` / `strict=true` の挙動
  - stats 連動
- `ac:link` と `ri:attachment` は warning 対象外で、`confluence-internal://` / `confluence-attachment://` スキームで正常出力する方針を明示した

### 3. Warning/Error 公開契約の検討指針

実装時は以下の優先順位で設計する。

1. **機械判定に使う情報を固定する**
   - `ConvertError` は `name` と `code` を安定契約にする
   - warning は少なくとも `[CATEGORY] ...` の CATEGORY を安定化する
2. **表示文言と機械契約を分離する**
   - 人間向け message は変更可能
   - 機械判定は code/category のみに依存させる
3. **後方互換を先に決める**
   - 既存契約（`warnings: string[]`）を維持しながら拡張する場合は、追加フィールドで段階移行する
   - 破壊的変更が必要なら `0.x` の minor で明示する
4. **strict 判定対象を固定する**
   - warning category と strict 例外化の対応表を 1 対 1 で維持し、実装ごとの裁量を残さない

## 移行時チェック項目（忘れ防止）

1. 実装着手前に `02_design.mdx` の変換マトリクスと実装対象を照合する
2. warning 追加時は CATEGORY の追加可否を先に判断し、無秩序に増やさない
3. `strict=true` のテストを warning category ごとに 1 ケースずつ持つ
4. 仕様更新時は、正本更新と本ディスカッション追記を同一 PR に含める

## ステータス

決定済み
