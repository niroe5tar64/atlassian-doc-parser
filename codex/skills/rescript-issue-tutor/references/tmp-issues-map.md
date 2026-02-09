# tmp/issues map (learning track)

Use this repo’s `tmp/issues/` as a hands-on curriculum: each file is designed to be 45–90 minutes and end with a green test.

## How to pick the next task

- Canonical order: `tmp/issues/README.md` (dependency order).
- CLI helper: run `scripts/list_tmp_issues.sh --next`.
- Don’t jump ahead unless you understand the dependency chain.

## Definition of done per issue

- Implement the feature described in the issue
- Add/adjust exactly one focused test (unless the issue says otherwise)
- Run `npx rescript` and `bun test` and confirm green

## How to use the issue file as教材

- Reuse the “ReScript コード例” section; it’s intentionally written as a just-in-time snippet.
- Treat “触るファイル” as a guardrail: keep diffs small.
- Timebox: if stuck >10 minutes, stop and ask for help with:
  - the exact file path + line
  - the compiler/test error
  - what you tried

## Coaching vs implementation mode

- Coaching mode (recommended for learning): the agent gives incremental hints, review, and explains ReScript concepts.
- Implementation mode: the agent writes the patch end-to-end; still includes a short “why” explanation.

