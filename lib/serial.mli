type config = {
  baud : int;
  port : string;
}

type t

val make : config -> t Lwt.t
val write_line : t -> string -> t Lwt.t
val write_of_score : t -> Oracle.score Lwt.t -> t Lwt.t
