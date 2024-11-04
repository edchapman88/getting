type t = Resolver_lwt.t

(** Module-private state. A [ref] to a [Resolver.t option]. *)
let resolver : t option ref = ref None

(** Public getter for a [Resolver.t option] that is maintained as module-private state. *)
let get () = !resolver

type host = {
  name : string; [@key "hostname"]
  ip : string;
  port : int;
}
[@@deriving of_yaml]

type hosts = host list [@@deriving of_yaml]

(** Read and parse a file for an anonymous array of DNS hosts, of type [hosts]. *)
let hosts_of_path path =
  let open Core.In_channel in
  let parsed = path |> read_all |> Yaml.of_string in
  match parsed with
  | Error _ -> failwith "Invalid yaml syntax"
  | Ok yaml -> (
      match hosts_of_yaml yaml with
      | Ok hosts -> hosts
      | Error _ -> failwith "Failed parsing hosts from yaml")

type endpt = {
  hostname : string;
  t : Conduit.endp;
}
(** A DNS endpoint. An alias for a [Conduit.endp] with the extension of the hostname. *)

let endp_of_host host : (endpt, _) result =
  let ip = Ipaddr.of_string host.ip in
  Result.map (fun ip -> { hostname = host.name; t = `TCP (ip, host.port) }) ip

let resolver_of_endps (endps : endpt list) =
  endps
  |> List.map (fun endpt -> (endpt.hostname, endpt.t))
  |> List.to_seq |> Hashtbl.of_seq |> Resolver_lwt_unix.static

let resolver_of_path path =
  let ( >|= ) a b = Result.map b a in
  path |> hosts_of_path |> List.map endp_of_host |> Core.Result.all
  >|= resolver_of_endps

let init_from_yaml path =
  resolver := Some (path |> resolver_of_path |> Result.get_ok)
