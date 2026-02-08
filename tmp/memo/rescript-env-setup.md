# ReScript 環境構築メモ

## 概要

ReScript v12 ベースのライブラリ開発環境を構築した。

## 判断事項

### package.json

- **htmlparser2**: 設計ドキュメント（02_design.mdx）で XML パーサーとして決定済み
- **@rescript/core 不要**: v12 ではコンパイラにバンドル済み
- **@rescript/runtime 不要**: `rescript` インストール時に自動で入る
- **vitest**: テストランナーとして採用（rescript-vitest バインディングは実装フェーズで追加検討）
- **main フィールド**: `./src/AtlassianDocParser.res.mjs` — namespace 有効時のエントリポイント

### rescript.json

- **namespace: true**: ライブラリ公開時のモジュール名衝突回避のため必須
- **in-source: true**: `.res` の隣に `.res.mjs` を生成（npm publish 時に両方含める）
- **suffix: ".res.mjs"**: ESM 出力で ReScript 由来であることが明確
- **tests/ は type: "dev"**: 消費者側のビルドに含まれない

### .gitignore

- `*.res.mjs` 等: `in-source: true` で生成されるビルド成果物は git 管理しない
- `lib/`: ReScript コンパイラの中間ファイル
- npm publish 時は `files` フィールドで `src/` を指定しているので `.npmignore` は不要（`files` が `.gitignore` より優先される）

### devcontainer

- `chenglou92.rescript-vscode`: ReScript 言語サポート拡張を追加
