; From Zed's GLSL extension (zed-industries/zed, extensions/glsl/languages/glsl),
; Apache-2.0 — see LICENSE-GLSL. Bundled so Lyra's /* glsl */ raw strings highlight
; with nothing else installed. Keep in step with the pinned tree-sitter-glsl commit.

("[" @open
  "]" @close)

("{" @open
  "}" @close)

("(" @open
  ")" @close)
