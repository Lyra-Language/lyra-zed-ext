; `.lui` markup (lyra/tools/lui). A sibling of tree-sitter-lyra/lui/queries/highlights.scm,
; in the opposite order: later patterns win in Zed, so the broad rules come first here and
; the narrow tag rules after them.

(comment) @comment

; A tag: a capitalized one is an element of bindings.imgui.ui, a lowercase one a component
; of the same file, and these few are the format's own.
(tag_name) @tag
((tag_name) @function
  (#match? @function "^[a-z]"))
((tag_name) @type
  (#match? @type "^[A-Z]"))
((tag_name) @keyword
  (#match? @keyword "^(if|else|for)$"))
((tag_name) @keyword
  (#match? @keyword "^(component|script|style)$"))

(attribute_name) @attribute
(quoted_attribute_value) @string
(entity) @string.escape

[
  "<"
  ">"
  "</"
  "/>"
] @punctuation.bracket

"=" @operator

(code
  [
    "{"
    "}"
  ] @punctuation.special)

; A component's props: each name a parameter, its type a type.
(prop name: (prop_name) @variable.parameter)
(prop type: (prop_type) @type)
(props
  [
    "{{"
    "}}"
  ] @punctuation.special)
(props
  [
    ","
  ] @punctuation.delimiter)
(prop
  ":" @punctuation.delimiter)
