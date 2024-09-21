type config = {
  baud : int;
  port : string;
}

type t

val write_line : t -> string -> t Lwt.t
val make : config -> t Lwt.t
