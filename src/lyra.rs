//! The Lyra extension for Zed.
//!
//! Like the VS Code extension, this is a thin LSP client wrapper: all the language
//! intelligence lives in the `lyra-lsp` binary built from the sibling `lyra/` Go project.
//! The extension's only real job is deciding *which* `lyra-lsp` to spawn.

use std::fs;

use zed_extension_api::{
    self as zed, serde_json, settings::LspSettings, LanguageServerId, Result,
};

/// Must match the `[language_servers.…]` key in extension.toml — it is also the key
/// users write under `"lsp"` in their Zed settings.
const SERVER_NAME: &str = "lyra-lsp";

/// Where `lyra/build.sh` puts the binary, relative to a worktree root. Two spellings
/// because either the compiler repo or the whole workspace may be the open worktree.
const BUILD_OUTPUT_PATHS: &[&str] = &["build/lyra-lsp", "lyra/build/lyra-lsp"];

struct LyraExtension;

impl LyraExtension {
    /// Resolve the server binary, in order of how explicit the user was about it:
    ///
    /// 1. `lsp.lyra-lsp.binary.path` in Zed settings — an explicit answer wins outright.
    /// 2. `lyra-lsp` on `$PATH`.
    /// 3. `build/lyra-lsp` under the worktree root, which is what `./build.sh` produces.
    ///
    /// Step 3 is the one worth keeping: this project's `build.sh` deliberately writes the
    /// binaries with `std/` symlinked beside them, because that is how `lyrac` finds the
    /// standard library. A `lyra-lsp` copied onto `$PATH` on its own has no `std/` next to
    /// it, so preferring the build output over nothing at all also gets the prelude right.
    fn language_server_binary(&self, worktree: &zed::Worktree) -> Result<zed::Command> {
        // The server is spawned from Zed, which does not inherit a login shell, so PATH
        // and LYRA_STD would otherwise be missing. `shell_env` is not implemented on
        // Windows in the extension API, so it is only requested where it means something.
        let env = match zed::current_platform().0 {
            zed::Os::Mac | zed::Os::Linux => worktree.shell_env(),
            zed::Os::Windows => Vec::new(),
        };

        let binary = LspSettings::for_worktree(SERVER_NAME, worktree)
            .ok()
            .and_then(|settings| settings.binary);
        let args = binary
            .as_ref()
            .and_then(|binary| binary.arguments.clone())
            .unwrap_or_default();

        if let Some(path) = binary.and_then(|binary| binary.path) {
            return Ok(zed::Command {
                command: path,
                args,
                env,
            });
        }

        if let Some(path) = worktree.which(SERVER_NAME) {
            return Ok(zed::Command {
                command: path,
                args,
                env,
            });
        }

        let root = worktree.root_path();
        let candidates: Vec<String> = BUILD_OUTPUT_PATHS
            .iter()
            .map(|relative| format!("{root}/{relative}"))
            .collect();

        for candidate in &candidates {
            // An Err here means either "no such file" or "the extension sandbox would not
            // let us look"; both are answered the same way — fall through to the message
            // below, which tells the user how to say it explicitly.
            if fs::metadata(candidate).is_ok_and(|stat| stat.is_file()) {
                return Ok(zed::Command {
                    command: candidate.clone(),
                    args,
                    env,
                });
            }
        }

        Err(format!(
            "Could not find the `{SERVER_NAME}` binary.\n\n\
             Build it by running `./build.sh` in the lyra repo, then either put \
             `build/lyra-lsp` on your PATH or point Zed at it directly in settings.json:\n\n\
             \"lsp\": {{\n  \"{SERVER_NAME}\": {{\n    \"binary\": {{\n      \
             \"path\": \"/absolute/path/to/build/lyra-lsp\"\n    }}\n  }}\n}}\n\n\
             Looked on PATH, and at: {}",
            candidates.join(", ")
        ))
    }
}

impl zed::Extension for LyraExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        self.language_server_binary(worktree)
    }

    /// Forwards whatever the user puts under `lsp.lyra-lsp.settings` to the server.
    /// `lyra-lsp` ignores configuration today; this costs nothing and means a setting can
    /// be added server-side without also shipping a new extension.
    fn language_server_workspace_configuration(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>> {
        let settings = LspSettings::for_worktree(SERVER_NAME, worktree)
            .ok()
            .and_then(|settings| settings.settings.clone())
            .unwrap_or_default();
        Ok(Some(settings))
    }
}

zed::register_extension!(LyraExtension);
