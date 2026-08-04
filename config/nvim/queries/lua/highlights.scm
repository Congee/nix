; extends

; LuaJIT syntax extensions. The stock query already covers the new binary and
; unary operators via `operator: _`; only the new node types need patterns.

(lambda_expression
  "->" @keyword.function)

(lambda_expression
  parameters: (identifier) @variable.parameter)

(lambda_parameters
  (identifier) @variable.parameter)

(lambda_parameters
  "|" @punctuation.bracket)

(ternary_expression
  [
    "?"
    ":"
  ] @keyword.conditional.ternary)

(continue_statement) @keyword.repeat

; compound assignment: `+=`, `..=`, `~>>=`, …
(assignment_statement
  operator: _ @operator)

"?." @operator

"const" @keyword

(optional_dot_index_expression
  field: (identifier) @variable.member)
