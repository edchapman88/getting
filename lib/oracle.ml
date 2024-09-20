type score =
  | Success
  | Fail of string

let string_of_score = function
  | Success -> "1"
  | Fail reason -> "0 : " ^ reason
