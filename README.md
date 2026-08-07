# lyra-zed-ext

The official [Zed](https://zed.dev) extension for the Lyra programming language.

It provides syntax highlighting, brackets, indentation and the code outline from the
[tree-sitter-lyra](https://github.com/Lyra-Language/tree-sitter-lyra) grammar, and starts
the `lyra-lsp` language server for diagnostics, hover, go-to-definition, completion,
signature help, document symbols, references, rename, code actions, inlay hints, folding
ranges and semantic tokens.

Like its VS Code counterpart, the extension is a thin client — all the language
intelligence lives in `lyra-lsp`, built from the [lyra](https://github.com/Lyra-Language/lyra)
repo.

## Installing

The extension is not in the Zed extension registry yet, so install it from a checkout:

1. Build the language server, from the `lyra` repo:

   ```bash
   ./build.sh
   ```

   This writes `build/lyra-lsp` and `build/lyrac` with `std/` symlinked beside them,
   which is where both look for the standard library.

2. In Zed, open the Extensions page and click **Install Dev Extension**, then select this
   directory. (The command palette equivalent is `zed: install dev extension`.)

Zed compiles the extension to WebAssembly and clones and builds the grammar on install.
It needs `rustup` on your `PATH`; it adds the `wasm32-wasip1` target itself if missing.

## Finding the language server

The extension looks for `lyra-lsp` in this order:

1. An explicit path in your Zed settings (below).
2. `lyra-lsp` on your `PATH`.
3. `build/lyra-lsp` or `lyra/build/lyra-lsp` under the worktree root — what `./build.sh`
   produces, whether you opened the compiler repo or the whole workspace.

If none of those find it, the extension says so and repeats the settings snippet.

## Settings

```json
{
  "lsp": {
    "lyra-lsp": {
      "binary": {
        "path": "/absolute/path/to/lyra/build/lyra-lsp",
        "arguments": []
      }
    }
  }
}
```

Prefer pointing at `build/lyra-lsp` over copying the binary somewhere on `PATH`: a
`lyra-lsp` on its own, without `std/` next to it, cannot resolve the prelude.

The server logs to `/tmp/lyra-lsp.log`. For extension-side problems, relaunch Zed from a
terminal with `zed --foreground` to see INFO-level logs.

## Compiling and running Lyra programs

The extension is an editor client only — it reports diagnostics as you type but contributes
no build task. Use the compiler CLI, `lyrac`, from a terminal:

```bash
lyrac check prog.lyra   # diagnostics only, no output file
lyrac build prog.lyra   # compile to a native executable (./prog)
lyrac run prog.lyra     # build to a temp location and execute it
```

`lyrac build` links with `clang`, so a C toolchain must be installed; `lyrac build
--emit-llvm` stops at the LLVM IR and needs none.

## Development

```bash
cargo build --target wasm32-wasip1 --release   # typecheck the Rust half on its own
```

After editing anything, use **zed: reload extensions** — Zed rebuilds the wasm and
reloads the queries in place.

The tree-sitter queries in `languages/lyra/` are checked against the grammar with the
tree-sitter CLI, from a `tree-sitter-lyra` checkout:

```bash
npx tree-sitter query ../lyra-zed-ext/languages/lyra/highlights.scm some_file.lyra
```

A query naming a node or field that does not exist makes Zed drop the **whole file**, so
a Lyra buffer loses all highlighting at once rather than one rule quietly going missing.
Run the command above on all four `.scm` files after any grammar change.

## Grammar version

`extension.toml` pins `tree-sitter-lyra` by commit. Zed clones that repo and compiles
`src/parser.c` itself — it never reads the sibling checkout — so a grammar change reaches
Zed only after it is pushed **and** the pin here is bumped to the new commit.

`src/parser.c` is 12.8 MB of ordinary tracked text, so the clone needs nothing special. It
used to be ~115 MB in Git LFS, which made **git-lfs** a prerequisite: without it the clone
produced a pointer file and the grammar build failed on it. Rebuilding the `lambda_expr`
rule stopped a parser state explosion (62,663 states → 6,475) and the file left LFS.

**Pinning a commit from before that change brings the requirement back**, since the pin
decides which tree Zed clones.

## License

MIT
