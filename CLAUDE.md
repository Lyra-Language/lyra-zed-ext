# lyra-zed-ext — Project Context

Zed extension for Lyra: a thin LSP client for `lyra-lsp` (from `lyra/`). Unlike the VS Code
extension it owns the **syntax highlighting queries**, since Zed highlights from tree-sitter.

## Structure

```
extension.toml                — manifest: language server + pinned grammar commit
Cargo.toml                    — cdylib built to wasm32-wasip1
src/lyra.rs                   — the entire extension (binary resolution)
languages/lyra/config.toml    — suffixes, comments, brackets, indent width
languages/lyra/highlights.scm — highlighting
languages/lyra/brackets.scm   — bracket matching
languages/lyra/indents.scm    — auto-indent
languages/lyra/outline.scm    — outline, breadcrumbs, symbol picker
target/                       — cargo output (gitignored)
```

No test suite; queries are verified with the tree-sitter CLI (below).

## Commands

```bash
cargo build --target wasm32-wasip1 --release   # typecheck the Rust half alone
```

Zed builds the extension on **Install Dev Extension** (`zed: install dev extension`) and
rebuilds on `zed: reload extensions`. Needs `rustup` on `PATH` (installs `wasm32-wasip1`
itself). `zed --foreground` shows INFO logs; Zed's log is `~/Library/Logs/Zed/Zed.log`.

## Do not rebuild the extension to pick up a new compiler

The server binary is resolved fresh at every spawn, so a new `lyra-lsp` needs only
`editor: restart language server`. A reload **stops** the extension's language servers and
does not reattach them to open buffers — the server stays dead until Zed restarts (log ends
at `stopping language server lyra-lsp`). Rebuild only when this repo changes (`src/lyra.rs`,
`extension.toml`, a query), then restart Zed.

## A `lyra-lsp` on `PATH` must be a symlink, not a copy

`PATH` is checked before the `build/lyra-lsp` fallback, so a copy shadows the build output
and pins a stale compiler (reads as an LSP bug), and has no `std/` beside it (`LYRA_STD` is
normally unset). A symlink fixes both — `stdRoot` resolves symlinks first:

```bash
ln -sf "$PWD/../lyra/build/lyra-lsp" ~/.local/bin/lyra-lsp
```

## Server path resolution (`src/lyra.rs`)

`lsp.lyra-lsp.binary.path` in Zed settings → `lyra-lsp` on `PATH` → `build/lyra-lsp` or
`lyra/build/lyra-lsp` under the worktree root (compiler repo or whole workspace open).
`./build.sh` puts `std/` beside the binaries, which is how the prelude is found.

The existence probe is `fs::metadata` inside the WASI sandbox; a refused read looks like a
missing file. The error message names every path tried and repeats the settings snippet.

## Queries use Zed's capture vocabulary, not nvim's

`languages/lyra/highlights.scm` is a deliberate **sibling** of
`tree-sitter-lyra/queries/highlights.scm` (nvim-treesitter names), not a copy. Update both
when the grammar gains a node.

| nvim-treesitter | Zed |
|---|---|
| `@variable.member` | `@property` |
| `@string.regexp` | `@string.regex` |
| `@keyword.control.conditional` | `@keyword.control` |
| `@comment.documentation` | `@comment.doc` |
| `@module` | `@namespace` |
| `@type.definition` | `@type` / `@type.interface` |
| `@function.call` | `@function` |
| `@function.method.call` | `@function.method` |
| `@number.float` | `@number` |

Zed falls back up the dots, so nvim names render in the wrong style rather than failing.

**Later patterns win** for the same node: broad rules first, narrower overrides after — even
if that splits a topical section. A rule whose matches are a subset of a later rule's is
dead, and `tree-sitter query` still lists its matches (it doesn't resolve precedence).
Example: `@function.method` filed before the `member_expr` property rules painted `n.weak()`
as a field.

## Verify queries against the grammar — every time

A query naming a nonexistent node type or field makes Zed reject **the whole file** — all
highlighting lost. From a `tree-sitter-lyra` checkout, with a sample exercising every
construct (compiling isn't enough; confirm captures fire):

```bash
for q in highlights brackets indents outline; do
  npx tree-sitter query ../lyra-zed-ext/languages/lyra/$q.scm sample.lyra
done
```

The two highlight files drift both ways: a node only this repo captures renders unstyled on
the website (which uses the grammar's file); a node neither captures (e.g.
`range_end_operator`) paints half an operator. Diff them when the grammar gains a node:

```bash
python3 -c "
import json
nt=json.load(open('src/node-types.json'))
kinds=sorted({n['type'] for n in nt if n.get('named') and n['type'].endswith('_type')})
for f in ['queries/highlights.scm','../lyra-zed-ext/languages/lyra/highlights.scm']:
    q=open(f).read()
    print(f, [k for k in kinds if '('+k+')' not in q and '('+k+' ' not in q])"
```

Composite wrappers (`array_type`, `lambda_type`, `weak_type`, `parameterized_type`,
`anonymous_*`) are expected in the output — capture their inner type. Look for missing
**leaves** (as `rune_type` was).

## Outline: two binding patterns

`outline.scm` matches `(program (declaration …))` for every top-level `let`/`var`, and
`(block (declaration … value: (lambda_expr)))` for nested functions only. Anchoring to
different parents keeps a top-level function from appearing twice (queries can't negate).

## Grammar pin

`[grammars.lyra]` in `extension.toml` pins `tree-sitter-lyra` by commit; Zed clones that repo
and compiles `src/parser.c` itself, never the sibling checkout.

- Push `tree-sitter-lyra` first, then bump `commit`. A pin to an unpushed commit fails the build.
- **A query edit and its pin bump go in one commit** — otherwise queries validate locally and
  break the whole file in Zed.
- After bumping, `rm -rf grammars` (gitignored cache) before Install Dev Extension, or Zed
  logs "skipping compilation of lyra parser" and keeps the old grammar.
- Pinning a commit from before `parser.c` left Git LFS makes `git-lfs` a prerequisite again.

## Relationship to Other Sub-Projects

- **`lyra/`** — `./build.sh` builds `lyra-lsp` and `lyrac`. Neither extension contributes a
  build or run task; compiling is a terminal command.
- **`tree-sitter-lyra/`** — the pinned grammar; home of the nvim-flavored `queries/highlights.scm`.
- **`lyra-vscode-ext/`** — same server, different client; binary-selection behavior is documented in both.
