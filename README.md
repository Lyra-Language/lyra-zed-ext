# lyra-zed-ext

The official [Zed](https://zed.dev) extension for Lyra: syntax highlighting, brackets,
indentation and outline from the
[tree-sitter-lyra](https://github.com/Lyra-Language/tree-sitter-lyra) grammar, plus the
`lyra-lsp` language server (diagnostics, hover, go-to-definition, completion, signature help,
symbols, references, rename, code actions, inlay hints, folding, semantic tokens, and
**formatting**), built from the [lyra](https://github.com/Lyra-Language/lyra) repo.

A raw string marked `/* glsl */` is highlighted as GLSL, with no GLSL extension needed — the
GLSL grammar and queries are bundled (queries from Zed's GLSL extension, Apache-2.0; see
`LICENSE-GLSL`).

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

## Formatting

`format` and format-on-save go through the language server, which runs **lyrafmt** — the
formatter written in Lyra. Nothing is configured here: `./build.sh` in the compiler repo
puts `build/lyrafmt` beside `build/lyra-lsp` when the machine can build it (a C compiler,
`libtree-sitter`, and the `tree-sitter-lyra` checkout), and the server looks for it at
`$LYRA_FMT`, then on `PATH`, then beside itself.

```json
{
  "languages": {
    "Lyra": { "formatter": "language_server", "format_on_save": "on" }
  }
}
```

With no `lyrafmt` on the machine, formatting does nothing rather than reporting an error —
the buffer is never half-formatted.

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
