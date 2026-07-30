; The outline (and breadcrumbs, and the file symbol picker).
;
; Bindings are split two ways on purpose. At the top level every `let`/`var` is an item —
; it is the language's equivalent of a Rust `static` or `fn`, and belongs in the outline
; whatever its value. Nested inside a block, only lambda-valued bindings are items, so a
; function's local variables do not each become an outline entry. The two patterns are
; anchored to different parents (program vs. block) so nothing matches both and no item
; appears twice.

(module_declaration
  "module" @context
  path: (module_path) @name) @item

(program
  (declaration
    (visibility)? @context
    keyword: _ @context
    modifiers: (fn_modifiers)? @context
    name: (identifier) @name) @item)

(program
  (const_declaration
    (visibility)? @context
    keyword: _ @context
    name: (_) @name) @item)

(block
  (declaration
    keyword: _ @context
    modifiers: (fn_modifiers)? @context
    name: (identifier) @name
    value: (lambda_expr)) @item)

; =============================================================================
; Type declarations
; =============================================================================

(struct_type
  (visibility)? @context
  "struct" @context
  struct_name: (struct_name) @name) @item

(struct_member
  field_name: (field_name) @name) @item

(data_type
  (visibility)? @context
  "data" @context
  (data_type_name) @name) @item

(data_type_constructor
  name: (data_type_constructor_name) @name) @item

(named_tuple_type
  (visibility)? @context
  "tuple" @context
  name: (tuple_type_name) @name) @item

(constrained_type
  (visibility)? @context
  "newtype" @context
  name: (constrained_type_name) @name) @item

; =============================================================================
; Traits and implementations
; =============================================================================

(trait_declaration
  (visibility)? @context
  "trait" @context
  name: (trait_name) @name) @item

(trait_method
  name: (_) @name) @item

(trait_implementation
  "impl" @context
  trait_name: (trait_name) @name
  "for" @context
  type: (_) @name) @item

(trait_method_implementation
  method_name: (method_name) @name) @item
