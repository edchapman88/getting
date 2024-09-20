type score =
  | Success
  | Fail of string

val string_of_score : score -> string
