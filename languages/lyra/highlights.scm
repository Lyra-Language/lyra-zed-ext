; Highlights for Lyra, in Zed's capture vocabulary.
;
; This is a sibling of tree-sitter-lyra/queries/highlights.scm, not a copy of it: that
; file targets the nvim-treesitter capture set (@variable.member, @string.regexp,
; @keyword.control.conditional), and Zed's themes key off a different one (@property,
; @string.regex, @keyword.control). Zed does fall back along dots, so the nvim names
; would mostly *work* — but they would resolve to the nearest ancestor rather than the
; intended style, so the two files stay separate and deliberate.
;
; Later patterns win over earlier ones for the same node, so the broad rules come first
; and the context-specific overrides follow.

; =============================================================================
; Comments
; =============================================================================

(comment) @comment
(doc_comment) @comment.doc

; =============================================================================
; Keywords
; =============================================================================

[
  "let"
  "var"
  "const"
  "where"
  "import"
  "module"
  "as"
] @keyword

[
  "struct"
  "data"
  "newtype"
  "tuple"
  "trait"
  "impl"
  "fixed"
] @keyword

[
  "if"
  "else"
  "match"
  "for"
  "in"
  "return"
  "break"
  "continue"
  "with"
  "await"
  "yield"
  "from"
] @keyword.control

; Modifiers. "pub", "pure", "det", "noalloc", "async", "gen" and "rec" have no anonymous
; node — they are only reachable through their named wrapper — while the rest do.
(visibility) @keyword
(pure_modifier) @keyword
(det_modifier) @keyword
(noalloc_modifier) @keyword
(async_modifier) @keyword
(gen_modifier) @keyword
(rec_modifier) @keyword
(unsafe_modifier) @keyword
(allocation_modifier) @keyword

[
  "unsafe"
  "weak"
  "readonly"
  "mut"
  "ref"
  "own"
] @keyword

; =============================================================================
; Types
; =============================================================================

[
  (signed_integer_type)
  (unsigned_integer_type)
  (float_type)
  (string_type)
  (boolean_type)
  (rune_type)
  (void_type)
  (self_type)
] @type.builtin

"Self" @type.builtin

; Generic parameters (lowercase — t, a, key) and bare PascalCase names in type or
; expression position.
(generic_type) @type
(user_defined_type_name) @type

; Aliased names for the same PascalCase identifier in specific declaration contexts.
(struct_name) @type
(tuple_type_name) @type
(constrained_type_name) @type
(data_type_name) @type

; A trait is an interface, and Zed themes style it apart from a concrete type.
(trait_name) @type.interface

; =============================================================================
; Constructors
; =============================================================================

; Declared inside a `data` body (Red, Some, None).
(data_type_constructor
  name: (data_type_constructor_name) @constructor)

; Applied — `Some(42)` parses as a named tuple literal.
(tuple_name) @constructor

; Matched in a pattern — `Some x => …`.
(data_pattern
  name: (data_type_name) @constructor)

; =============================================================================
; Variables and constants
; =============================================================================

(identifier) @variable
(const_identifier) @constant

(parameter
  pattern: (identifier) @variable.parameter)

; =============================================================================
; Functions
; =============================================================================

; A binding whose value is a lambda is a function definition, however it is spelled
; (`let add = (a, b) => …` and `let add(a, b) => …` collect identically).
(declaration
  name: (identifier) @function.definition
  value: (lambda_expr))

(call_expr
  function: (identifier) @function)

(call_expr
  function: (member_expr
    property: (identifier) @function.method))

(trait_method
  name: (identifier) @function.definition)

(trait_method_implementation
  method_name: (method_name) @function.definition)

; =============================================================================
; Properties
; =============================================================================

(member_expr
  property: (identifier) @property)

(optional_member_expr
  property: (identifier) @property)

(struct_member
  field_name: (field_name) @property)

(struct_field
  field_name: (field_name) @property)

; =============================================================================
; Modules
; =============================================================================

(module_name) @namespace

; =============================================================================
; Attributes
; =============================================================================

"@sizeof" @function.special

(attribute
  "@" @punctuation.special)

(attribute
  name: (identifier) @attribute)

; =============================================================================
; Literals
; =============================================================================

(boolean_literal) @boolean
(integer_literal) @number
(float_literal) @number
(char_literal) @string.special.symbol

[
  (string_literal)
  (raw_string_literal)
  (string_content)
] @string

(regex_literal) @string.regex

(string_interpolation
  "${" @punctuation.special)

(string_interpolation
  "}" @punctuation.special)

; =============================================================================
; Operators
; =============================================================================

[
  (add_operator)
  (sub_operator)
  (mul_operator)
  (div_operator)
  (mod_operator)
  (remainder_operator)
  (add_assign_operator)
  (sub_assign_operator)
  (mul_assign_operator)
  (div_assign_operator)
  (mod_assign_operator)
  (remainder_assign_operator)
  (equals_operator)
  (not_equals_operator)
  (greater_than_operator)
  (less_than_operator)
  (greater_than_or_equal_operator)
  (less_than_or_equal_operator)
  (spaceship_operator)
  (and)
  (or)
  (not)
  (string_concat_operator)
  (compose_operator)
] @operator

[
  "=>"
  "->"
  ".."
  "..."
  "?"
  "??"
  "?."
  "?["
  "&"
  "^"
  "="
  "|"
  "~"
] @operator

; =============================================================================
; Punctuation
; =============================================================================

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  ","
  ":"
  "::"
  "."
  ".{"
] @punctuation.delimiter

"@" @punctuation.special
