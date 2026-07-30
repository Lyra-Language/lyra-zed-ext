("(" @open
  ")" @close)

("[" @open
  "]" @close)

("{" @open
  "}" @close)

; `<`/`>` are only ever generic delimiters as anonymous tokens — comparison operators
; are their own named nodes (less_than_operator, greater_than_operator), and turbofish
; opens with the single atomic token "::<".
("<" @open
  ">" @close)

; The interpolation braces inside a string.
("${" @open
  "}" @close)
