/**
 * atlassian-doc-parser（Confluence Storage Format → Markdown 変換ライブラリ）の開発環境設定
 *
 * base + (preset) + この設定 がマージされて
 * .devcontainer/devcontainer.json が生成されます
 */
export const projectConfig = {
  name: "atlassian-doc-parser",
  // VSCode 拡張追加: chenglou92.rescript-vscode (ReScript 言語サポート)
};

/**
 * JSON に含める追加フィールド
 * （DevContainerConfig 型には含まれないが、JSON としては有効）
 */
export const projectConfigMetadata = {
  $comment: "",
};
