; A raw string marked `/* glsl */` is GLSL: `load_shader(/* glsl */ \`…\`)`.
; The marker is a block comment immediately before the string; tree-sitter puts
; it beside the string itself, or beside the `value` wrapping a call argument.
; Only the content is injected, never the delimiters. A sibling of
; tree-sitter-lyra/queries/injections.scm. Highlighting it needs Zed's GLSL
; extension; without it the content stays unstyled.
(
  (comment) @_marker
  .
  [
    (raw_string_literal (raw_string_content) @injection.content)
    (value (raw_string_literal (raw_string_content) @injection.content))
  ]
  (#match? @_marker "^/\\*\\s*glsl\\s*\\*/$")
  (#set! injection.language "glsl"))
