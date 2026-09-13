# lyra-zed-ext

The official [Zed](https://zed.dev) extension for Lyra: syntax highlighting, brackets,
indentation and outline from the
[tree-sitter-lyra](https://github.com/Lyra-Language/tree-sitter-lyra) grammar, plus the
`lyra-lsp` language server (diagnostics, hover, go-to-definition, completion, signature help,
symbols, references, rename, code actions, inlay hints, folding, semantic tokens), built from
the [lyra](https://github.com/Lyra-Language/lyra) repo.

## Installing

Not in the Zed registry yet; install from a checkout:

1. In the `lyra` repo, run `./build.sh` — writes `build/lyra-lsp` and `build/lyrac` with
   `std/` symlinked beside them (where the standard library is found).
2. In Zed's Extensions page, click **Install Dev Extension** (`zed: install dev extension`)
   and select this directory.

Zed compiles the extension to wasm and builds the grammar on install. It needs `rustup` on
`PATH` and adds the `wasm32-wasip1` target itself.

## Finding the language server

1. The path in Zed settings (below).
2. `lyra-lsp` on `PATH` — make it a **symlink** to `build/lyra-lsp`, not a copy (a copy has
   no `std/` beside it and goes stale).
3. `build/lyra-lsp` or `lyra/build/lyra-lsp` under the worktree root.

```json
{
  "lsp": {
    "lyra-lsp": {
      "binary": { "path": "/absolute/path/to/lyra/build/lyra-lsp", "arguments": [] }
    }
  }
}
```

After rebuilding the compiler, run `editor: restart language server` — don't reload the
extension. Server log: `/tmp/lyra-lsp.log`; extension log: launch `zed --foreground`.

## Compiling and running Lyra programs

The extension contributes no build task. Use `lyrac` from a terminal:

```bash
lyrac check prog.lyra   # diagnostics only
lyrac build prog.lyra   # native executable (./prog); needs clang
lyrac run prog.lyra     # build to a temp location and execute
```

`lyrac build --emit-llvm` stops at LLVM IR and needs no C toolchain.

## Development

```bash
cargo build --target wasm32-wasip1 --release   # typecheck the Rust half
```

`zed: reload extensions` rebuilds after editing. Check every query against the grammar from a
`tree-sitter-lyra` checkout — a query naming a nonexistent node makes Zed drop the **whole
file**:

```bash
npx tree-sitter query ../lyra-zed-ext/languages/lyra/highlights.scm some_file.lyra
```

Run it on all four `.scm` files after any grammar change.

## Grammar version

`extension.toml` pins `tree-sitter-lyra` by commit; Zed clones and compiles it itself. A
grammar change reaches Zed only once pushed **and** the pin is bumped. Delete `grammars/`
before reinstalling so the new pin is actually compiled. Pinning a commit from before
`src/parser.c` left Git LFS requires `git-lfs`.

## License

MIT
