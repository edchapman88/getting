type t = Resolver_lwt.t

type host = {
  name : string; [@key "hostname"]
  ip : string;
  port : int;
}
[@@deriving of_yaml]

type hosts = host list [@@deriving of_yaml]

let hosts_of_path path =
  let open Core.In_channel in
  let parsed = path |> read_all |> Yaml.of_string in
  match parsed with
  | Error _ -> failwith "Invalid yaml syntax"
  | Ok yaml -> (
      match hosts_of_yaml yaml with
      | Ok hosts -> hosts
      | Error _ -> failwith "Failed parsing hosts from yaml")

type endpt = string * Conduit.endp

let endp_of_host host : (endpt, _) result =
  let ip = Ipaddr.of_string host.ip in
  Result.map (fun ip -> (host.name, `TCP (ip, host.port))) ip

let resolver_of_endps (endps : endpt list) =
  endps |> List.to_seq |> Hashtbl.of_seq |> Resolver_lwt_unix.static

let resolver_of_path path =
  let ( >|= ) a b = Result.map b a in
  path |> hosts_of_path |> List.map endp_of_host |> Core.Result.all
  >|= resolver_of_endps

let resolver = ref None
let get () = !resolver

let parse_resolver path =
  resolver := Some (path |> resolver_of_path |> Result.get_ok)
