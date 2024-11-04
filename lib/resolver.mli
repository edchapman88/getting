(** [Resolver] is a stateful module for parsing and serving a custom DNS resolver from a yaml file that contains an array of DNS hosts. [get] returns a [Resolver.t option], which is [Some] if [init_from_yaml] has been called with a correctly formatted host file, and [None] otherwise. *)

type t = Resolver_lwt.t
(** [Resolver.t] is a custom DNS resolver. It is an alias for [Resolver_lwt.t]. *)

type host = {
  name : string; [@key "hostname"]
  ip : string;
  port : int;
}
[@@deriving of_yaml]
(** A yaml-derivable representation of a DNS host. *)

type hosts = host list [@@deriving of_yaml]
(** A yaml-derivable list of hosts, each of type [host]. [hosts] is derived from an anonymous yaml array. *)

val init_from_yaml : string -> unit
(** [init_from_yaml path_to_hostfile] attempts to parse a yaml file at [path_to_hostfile] for an array of DNS hosts (of type [hosts]). If successful, the state of the module is updated with the new resolver, and subsequent calls to [get] return the new resolver. *)

val get : unit -> t option
(** A getter for the state of this stateful [Resolver] module. Returning [Some Resolver.t] if a resolver has been initialised with an earlier (successful) call to [init_from_yaml], and [None] otherwise. *)
