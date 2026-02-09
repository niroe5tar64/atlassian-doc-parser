#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
learning_log.sh <command> [args]

Commands:
  init  --issue <file> --timebox <minutes> --mode <hints|impl>
  add   --type <note|qa|stuck|cmd|result> [--title <t>] (--text <t> | --q <q> --a <a>)
  close
  path

Writes to: tmp/memo/learning-logs/YYYY-MM-DD.md (repo-relative)

Examples:
  scripts/learning_log.sh init --issue tmp/issues/scaffold.md --timebox 60 --mode hints
  scripts/learning_log.sh add --type qa --q "What is .resi?" --a ".d.ts のような公開API宣言"
  scripts/learning_log.sh add --type cmd --title "compile+test" --text "npx rescript && bun test"
  scripts/learning_log.sh close
EOF
}

cmd="${1:-}"
if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
  usage
  exit 0
fi
shift || true

repo_root="$PWD"
if command -v git >/dev/null 2>&1; then
  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    repo_root="$git_root"
  fi
fi

log_dir="$repo_root/tmp/memo/learning-logs"
date_ymd="$(date +%F)"
log_path="$log_dir/$date_ymd.md"

ensure_header() {
  mkdir -p "$log_dir"
  if [[ -f "$log_path" ]]; then
    return 0
  fi

  {
    printf '# 学習ログ (%s)\n\n' "$date_ymd"
    printf -- '- repo: %s\n' "$(basename "$repo_root")"
    printf -- '- started_at: %s\n' "$(date +%H:%M)"
    printf '\n'
    printf '## 今日のゴール\n'
    printf -- '- [ ] (issueの目的をここに)\n'
    printf '\n'
    printf '## タイムライン\n'
  } >"$log_path"
}

append_entry() {
  local heading="$1"
  local body="$2"
  ensure_header
  {
    printf '\n### %s\n' "$heading"
    printf '%s\n' "$body"
  } >>"$log_path"
}

case "$cmd" in
  path)
    echo "$log_path"
    ;;

  init)
    issue=""
    timebox=""
    mode=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --issue) issue="${2:-}"; shift 2 ;;
        --timebox) timebox="${2:-}"; shift 2 ;;
        --mode) mode="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
      esac
    done

    if [[ -z "$issue" || -z "$timebox" || -z "$mode" ]]; then
      echo "init requires: --issue, --timebox, --mode" >&2
      exit 2
    fi

    mkdir -p "$log_dir"
    if [[ ! -f "$log_path" ]]; then
      {
        printf '# 学習ログ (%s)\n\n' "$date_ymd"
        printf -- '- repo: %s\n' "$(basename "$repo_root")"
        printf -- '- issue: %s\n' "$issue"
        printf -- '- timebox_min: %s\n' "$timebox"
        printf -- '- mode: %s\n' "$mode"
        printf -- '- started_at: %s\n' "$(date +%H:%M)"
        printf '\n'
        printf '## 今日のゴール\n'
        printf -- '- [ ] (issueの目的をここに)\n'
        printf '\n'
        printf '## タイムライン\n'
      } >"$log_path"
    fi

    append_entry "$(date +%H:%M) init" "- issue: $issue"$'\n'"- timebox: ${timebox}m"$'\n'"- mode: $mode"
    echo "$log_path"
    ;;

  add)
    entry_type=""
    title=""
    text=""
    q=""
    a=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --type) entry_type="${2:-}"; shift 2 ;;
        --title) title="${2:-}"; shift 2 ;;
        --text) text="${2:-}"; shift 2 ;;
        --q) q="${2:-}"; shift 2 ;;
        --a) a="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
      esac
    done

    if [[ -z "$entry_type" ]]; then
      echo "add requires: --type" >&2
      exit 2
    fi

    ts="$(date +%H:%M)"
    heading="$ts $entry_type"
    if [[ -n "$title" ]]; then
      heading="$heading: $title"
    fi

    case "$entry_type" in
      qa)
        if [[ -z "$q" || -z "$a" ]]; then
          echo "add --type qa requires: --q and --a" >&2
          exit 2
        fi
        append_entry "$heading" "Q: $q"$'\n'"A: $a"
        ;;
      note|stuck|cmd|result)
        if [[ -z "$text" ]]; then
          echo "add --type $entry_type requires: --text" >&2
          exit 2
        fi
        append_entry "$heading" "$text"
        ;;
      *)
        echo "Unknown --type: $entry_type (use note|qa|stuck|cmd|result)" >&2
        exit 2
        ;;
    esac
    echo "$log_path"
    ;;

  close)
    ensure_header

    if command -v rg >/dev/null 2>&1; then
      if rg -n '^## まとめ$' "$log_path" >/dev/null 2>&1; then
        echo "$log_path"
        exit 0
      fi
    else
      if grep -nE '^## まとめ$' "$log_path" >/dev/null 2>&1; then
        echo "$log_path"
        exit 0
      fi
    fi

    qa_block="$(
      awk '
        /^Q: / {q=$0; if (getline && $0 ~ /^A: /) {print "- " q "\n  - " $0 "\n"}}
      ' "$log_path" || true
    )"

    {
      printf '\n## まとめ\n'
      printf '### 学んだこと\n'
      printf -- '- (例) `.resi` は公開APIを固定する\n'
      printf '\n### 詰まったところ → 解決\n'
      printf -- '- (例) Bun test FFI の import 形式を修正\n'
      printf '\n### Q&A（自動抽出）\n'
      if [[ -n "$qa_block" ]]; then
        printf '%s\n' "$qa_block"
      else
        printf -- '- (Q&Aのログがまだありません)\n'
      fi
      printf '\n### 次回の最初の一手\n'
      printf -- '- (例) `npx rescript && bun test` の状態確認\n'
    } >>"$log_path"

    echo "$log_path"
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac
