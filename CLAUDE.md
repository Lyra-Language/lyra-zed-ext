# lyra-zed-ext — Project Context

The official Zed extension for the Lyra programming language. Like `lyra-vscode-ext`, it is
a thin LSP client — the language intelligence is all in the `lyra-lsp` binary from the
sibling `lyra/` Go project. Unlike the VS Code extension, it also owns the **syntax
highlighting queries**, because Zed highlights from tree-sitter rather than TextMate.

## Structure

```
extension.toml            — manifest: language server + the pinned grammar commit
Cargo.toml                — cdylib built to wasm32-wasip1
src/lyra.rs               — the entire extension (binary resolution)
languages/lyra/config.toml    — file suffixes, comments, brackets, indent width
languages/lyra/highlights.scm — syntax highlighting
languages/lyra/brackets.scm   — bracket matching
languages/lyra/indents.scm    — auto-indent
languages/lyra/outline.scm    — outline, breadcrumbs, file symbol picker
target/                   — cargo output (gitignored)
```

There is no test suite. The queries are verified with the tree-sitter CLI (below).

## Commands

```bash
cargo build --target wasm32-wasip1 --release   # typecheck the Rust half alone
```

Zed itself builds the extension on **Install Dev Extension** (Extensions page, or
`zed: install dev extension`), and rebuilds on `zed: reload extensions`. It needs `rustup`
on `PATH` and installs the `wasm32-wasip1` target itself. `zed --foreground` shows
INFO-level logs when something fails to load.

## Do not rebuild the extension to pick up a new compiler

The server binary is **external and resolved fresh at every spawn**, so a new `lyra-lsp`
needs the *server* restarted (`editor: restart language server`), never the extension
rebuilt. Rebuilding is both unnecessary and actively harmful: a reload **stops** the
language servers the extension provides and does not reattach them to already-open
buffers, so the server stays dead until Zed is restarted. Read straight off the log
(`~/Library/Logs/Zed/Zed.log`):

```
finished compiling extension in 1.07s
extensions updated. loading 0, reloading 1, unloading 0
stopping language server lyra-lsp          <- and nothing after it
```

Rebuild only when *this repo* changes — `src/lyra.rs`, `extension.toml`, or a query — and
restart Zed afterwards. The trap is that reaching for a rebuild is the natural response to
"the language server seems stale", and it converts a stale server into no server at all.

## A `lyra-lsp` on `PATH` must be a symlink, not a copy

`PATH` is checked **before** the `build/lyra-lsp` fallback, so a copy there shadows the
build output and pins the editor to whatever compiler was current when it was copied — the
editor then reports diagnostics the CLI does not, which reads as an LSP bug rather than as
staleness. A copy also lands the [`std/` adjacency](#server-path-resolution-srclyrars)
problem the section below describes: nothing sits beside it, and `LYRA_STD` is normally
unset.

A symlink fixes both at once, because `stdRoot` resolves symlinks before taking the
executable's directory (`lyra/CLAUDE.md`, Building — it exists for exactly this case), so
the prelude is found beside the *target*:

```bash
ln -sf "$PWD/../lyra/build/lyra-lsp" ~/.local/bin/lyra-lsp
```

This is the workspace's own recurring lesson — `build/std` is a symlink rather than a copy
for the same reason — and it cost an evening on 08/14: every staleness failure this project
has hit presented as a *behaviour* difference rather than as staleness.

## Server path resolution (`src/lyra.rs`)

In order: `lsp.lyra-lsp.binary.path` in Zed settings → `lyra-lsp` on `PATH` →
`build/lyra-lsp` or `lyra/build/lyra-lsp` under the worktree root. Two build-output
spellings because either the compiler repo or the whole workspace may be the open
worktree.

The build-output fallback exists for the same reason the VS Code extension defaults to
`${workspaceFolder}/build/lyra-lsp`: `./build.sh` writes the binaries with `std/` symlinked
beside them, and that adjacency is how the standard library is found. A `lyra-lsp` copied
onto `PATH` by itself has no `std/` next to it, so preferring the build output also gets
the prelude right.

The existence probe is `fs::metadata` on an absolute path, from inside the extension's WASI
sandbox. If the sandbox refuses the read it is indistinguishable from a missing file, and
both fall through to the error message — which names every path tried and repeats the
settings snippet, so a wrong guess here costs a sentence rather than a mystery.

## Queries are Zed's vocabulary, not nvim's

`languages/lyra/highlights.scm` is a **sibling** of
`tree-sitter-lyra/queries/highlights.scm`, not a copy. That file targets the
nvim-treesitter capture set; Zed's themes key off a different one:

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

Zed resolves a capture name by walking *up* the dots, so the nvim names would mostly
render — just as their nearest ancestor rather than the intended style, which is a subtle
wrong-color rather than a visible failure. Hence two deliberate files. Both must be updated
when the grammar gains a node.

Zed applies **later** patterns over earlier ones for the same node, so broad rules go first
and context-specific overrides after — the same ordering discipline the grammar's own
query file uses.

## Verify queries against the grammar — every time

A query naming a node type or field that does not exist makes Zed reject **the entire
file**, so a Lyra buffer loses all highlighting at once instead of one rule silently going
missing. Check all four before committing, from a `tree-sitter-lyra` checkout:

```bash
for q in highlights brackets indents outline; do
  npx tree-sitter query ../lyra-zed-ext/languages/lyra/$q.scm sample.lyra
done
```

Compiling is not enough — a pattern that is valid but never matches also "passes". Use a
sample file that exercises every construct and confirm the captures actually fire.

**The two files drift in both directions, and neither drift is visible from one side.**
Checked 08/13 by listing every `*_type` node in `src/node-types.json` and diffing against
both query files: this repo had `(rune_type)` and the grammar's own
`queries/highlights.scm` did not, so `rune` rendered unstyled among highlighted primitives
on the website — which reads that other file. Both were missing `(range_end_operator)`,
which is a node rather than part of the `..` token, so the `<=` of `0..<=9` rendered
unstyled beside a highlighted `..`: half an operator in the operator colour and half in
body text. Both are fixed.

The diff is worth re-running when the grammar gains a node — it takes seconds and finds
what reading does not:

```bash
python3 -c "
import json
nt=json.load(open('src/node-types.json'))
kinds=sorted({n['type'] for n in nt if n.get('named') and n['type'].endswith('_type')})
for f in ['queries/highlights.scm','../lyra-zed-ext/languages/lyra/highlights.scm']:
    q=open(f).read()
    print(f, [k for k in kinds if '('+k+')' not in q and '('+k+' ' not in q])"
```

Read its output with judgement: most composite types (`array_type`, `lambda_type`,
`weak_type`, `parameterized_type`, the `anonymous_*` pair) are structural wrappers whose
*inner* type is the thing to capture, and highlighting the wrapper too would double-paint.
What the list is for is spotting a missing **leaf**, which `rune_type` was.

## Outline: two binding patterns, anchored to different parents

`outline.scm` matches bindings twice, deliberately: `(program (declaration …))` for every
top-level `let`/`var` — the language's equivalent of a Rust `static` or `fn`, which belongs
in the outline whatever its value — and `(block (declaration … value: (lambda_expr)))` for
nested ones, so a function's local variables do not each become an entry. Anchoring them to
different parents is what keeps a top-level function from matching both and appearing
twice; tree-sitter queries cannot express the negation that a single pattern would need.

## Grammar pin

`[grammars.lyra]` in `extension.toml` pins `tree-sitter-lyra` by commit. **Zed clones that
repo and compiles `src/parser.c` itself — it never reads the sibling checkout.** So the
workspace's usual push-ordering rule applies with an extra step: push `tree-sitter-lyra`
first, then bump the `commit` here. A pin to an unpushed commit fails the grammar build
outright.

**A worked example, 08/13:** `highlights.scm` gained `(inner_doc_comment)` — the `//!`
node added with documentation comments — in the same change that bumped the pin to
`a721ede`. Those two edits belong in one commit, and the reason is that splitting them
fails *latently*: the queries validate against the sibling checkout, where the node
exists, and break only in Zed, where the pinned tree would not have it — and then break
the whole file, so every Lyra buffer loses all highlighting rather than losing one rule.

Two properties of this particular grammar matter here:

- **`src/parser.c` is 12.8 MB of ordinary tracked text.** It used to be ~115 MB in Git LFS,
  which made `git-lfs` a prerequisite for Zed's own clone of the grammar: without it the
  clone yielded a pointer file and the grammar build failed on it. The `lambda_expr` rule
  was rebuilt to stop a parser state explosion (62,663 states → 6,475) and the file left
  LFS, so Zed needs nothing special now — **but pinning a commit from before that change
  reintroduces the requirement**, since the pin decides which tree Zed clones.
- **It is comfortably sized.** Roughly a tenth of what it was, and well within what Zed
  loads.

## Relationship to Other Sub-Projects

- **`lyra/`** (Go) — builds the `lyra-lsp` this extension spawns (`./build.sh`). The same
  script produces `lyrac`, the compiler CLI — `check`, `build` (a native executable), and
  `run` (build to a temp location and execute, 08/06). **Neither extension contributes a
  build or run task**: they are language clients, and compiling is a terminal command.
- **`tree-sitter-lyra/`** — the grammar, pinned by commit in `extension.toml`; also the
  home of the nvim-flavored `queries/highlights.scm` that this repo's queries parallel.
- **`lyra-vscode-ext/`** — the same server, a different client. Behavior that should match
  across editors (which binary is chosen, and why) is documented in both.
