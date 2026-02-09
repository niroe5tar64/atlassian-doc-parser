#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
list_tmp_issues.sh [--next] [--files]

Reads tmp/issues/README.md and prints issues in dependency order, including each
issue's "- status:" from tmp/issues/<file>. Use --next to print only the first
issue whose status is "open".
EOF
}

want_next=0
want_files=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --next) want_next=1 ;;
    --files) want_files=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

repo_root="$PWD"
if command -v git >/dev/null 2>&1; then
  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    repo_root="$git_root"
  fi
fi

readme="$repo_root/tmp/issues/README.md"
issues_dir="$repo_root/tmp/issues"

if [[ ! -f "$readme" ]]; then
  echo "Not found: $readme" >&2
  exit 1
fi
if [[ ! -d "$issues_dir" ]]; then
  echo "Not found: $issues_dir" >&2
  exit 1
fi

# Extract (title, file) pairs from the markdown table.
mapfile -t rows < <(
  awk -F'\\|' '
    $0 ~ /^\| title \| depends_on \| file \| jump \|/ {in_table=1; next}
    in_table && $0 ~ /^\|---/ {next}
    in_table && $0 ~ /^\|/ {
      title=$2
      file=$4
      gsub(/^[ \t]+|[ \t]+$/, "", title)
      gsub(/^[ \t]+|[ \t]+$/, "", file)
      gsub(/`/, "", file)
      if (title != "" && file != "") print title "\t" file
    }
  ' "$readme"
)

idx=0
for row in "${rows[@]}"; do
  idx=$((idx + 1))
  title="${row%%$'\t'*}"
  file="${row#*$'\t'}"

  issue_path="$issues_dir/$file"
  status="unknown"
  if [[ -f "$issue_path" ]]; then
    status="$(awk -F': ' '/^- status:/ {print $2; exit}' "$issue_path" | tr -d '\r')"
    status="${status:-unknown}"
  else
    status="missing"
  fi

  if [[ "$want_next" -eq 1 ]]; then
    if [[ "$status" == "open" ]]; then
      if [[ "$want_files" -eq 1 ]]; then
        printf '%s\n' "$file"
      else
        printf '%02d  [%s]  %s  (%s)\n' "$idx" "$status" "$file" "$title"
      fi
      exit 0
    fi
    continue
  fi

  if [[ "$want_files" -eq 1 ]]; then
    printf '%s\n' "$file"
  else
    printf '%02d  [%s]  %s  (%s)\n' "$idx" "$status" "$file" "$title"
  fi
done

if [[ "$want_next" -eq 1 ]]; then
  echo "No issue with status: open" >&2
  exit 1
fi
