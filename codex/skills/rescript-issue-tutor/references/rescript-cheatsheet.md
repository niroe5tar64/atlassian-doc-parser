# ReScript quick cheatsheet (for tmp/issues)

Load this file only when the issue needs a syntax reminder, TS→ReScript mapping, FFI, or Bun test bindings.

## Core syntax

- **Value / function**: `let x = 1`, `let add = (a, b) => a + b`
- **Type**: `type user = {id: int, name: string}`
- **Record access**: `user.name`
- **Record update**: `{...user, name: "new"}`
- **Variant (discriminated union)**:
  - `type node = Text(string) | Paragraph(array<node>)`
  - `switch n { | Text(s) => ... | Paragraph(children) => ... }`
- **Option**:
  - `type option<'a> = Some('a) | None`
  - Use `switch opt { | Some(x) => ... | None => ... }`
- **Pipe**: `value->fn` (reads left-to-right)

## Labeled / optional arguments

- **Labeled arg**: `let f = (~x, ~y) => x + y`
- **Optional labeled**: `let f = (~x=?, ()) => switch x { | Some(v) => v | None => 0 }`
- Call optional with `~x=?Some(1)` or omit it.

## Collections

- **array**: `array<'a>` (JS array). Literals: `[|1, 2|]`
- **list**: `list<'a>` (linked list). Literals: `list{1, 2}`
- Common:
  - `Array.map(xs, x => ...)`
  - `List.map(xs, x => ...)`

## Modules and `.resi`

- `.res` = implementation, `.resi` = public interface (similar to `.d.ts`).
- If a type/function is public, declare it in `.resi` too.

## JS / Bun test FFI patterns

- Bind global value: `@val external describe: (string, unit => unit) => unit = "describe"`
- Bind method: `@send external toBe: (expectResult, 'a) => unit = "toBe"`
- Import module:
  - `@module("node:fs") external readFileSync: (string, string) => string = "readFileSync"`

Minimal Bun test binding:

```rescript
@val external describe: (string, unit => unit) => unit = "describe"
@val external test: (string, unit => unit) => unit = "test"
type expectResult
@val external expect: 'a => expectResult = "expect"
@send external toBe: (expectResult, 'a) => unit = "toBe"
```

## Debugging tips

- Use `switch` + exhaustive matches; the compiler error messages are your friend.
- For “this value is a function, not a record” type errors: you likely missed `()` or used a labeled arg wrong.
- For “unbound module” errors: check file/module name casing and whether the file is under `src/`.

