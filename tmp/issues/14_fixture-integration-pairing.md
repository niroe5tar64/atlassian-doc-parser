# Issue 14: fixture 統合テスト（自動ペアリング）

- status: open
- estimate: 75m
- depends_on: 13
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#テスト契約固定`

## 目的

`tests/fixtures/*` を自動走査し、`input.xml` と `expected.md` のペアで統合テストを回す。

## 触るファイル

- `tests/integration/AtlassianDocParser_test.res`
- `tests/fixtures/`（必要な fixture の追加/整理）

## 実装タスク

1. `tests/fixtures/*/input.xml` を列挙する。
2. 同ディレクトリの `expected.md` が存在しない場合は明示的に失敗させる。
3. 各 fixture を parser に通して golden compare する。
4. 初期3 fixture（basic / complex_table_code / mixed_unsupported）を揃える。

## 受け入れ条件

- fixture の silent skip が起きない。
- 3ケース以上で integration test が通る。
