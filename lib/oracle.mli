type score =
  | Success
  | Fail of string

val string_of_score : ?debug:bool -> score -> string
val score_of_res : Request.t -> score Lwt.t
