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

   This writes `build/lyra-lsp` with `std/` symlinked beside it, which is where `lyrac`
   looks for the standard library.

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

`src/parser.c` is a ~115 MB file stored in Git LFS, so **git-lfs must be installed** for
the clone to produce a real parser rather than an LFS pointer file. It compiles to roughly
20 MB of object code, which is large for a tree-sitter grammar but well within what Zed
loads.

## License

MIT
