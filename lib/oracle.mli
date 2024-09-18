type score =
  | Success
  | Fail

val write_serial : ?baud:int -> string -> string -> unit Lwt.t
val write_score : ?baud:int -> string -> score -> unit Lwt.t