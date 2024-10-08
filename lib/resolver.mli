type t = Resolver_lwt.t

type host = {
  name : string; [@key "hostname"]
  ip : string;
  port : int;
}
[@@deriving of_yaml]

type hosts = host list [@@deriving of_yaml]

val parse_resolver : string -> unit
val get : unit -> t option
