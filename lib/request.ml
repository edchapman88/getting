type res = Cohttp.Response.t * Cohttp_lwt.Body.t

type t =
  | Sent of res Lwt.t
  | Failed of exn

type params = {
  src : Uri.t;
  dest : Uri.t;
}

let code_of_res res =
  res |> fst |> Cohttp.Response.status |> Cohttp.Code.code_of_status

let body_of_res res = res |> snd |> Cohttp_lwt.Body.to_string
let s_meta_of_res res = res |> fst |> Cohttp.Response.sexp_of_t
let meta_of_res res = res |> s_meta_of_res |> Sexplib0.Sexp.to_string_hum

let send params =
  let open Cohttp_lwt_unix in
  let ip =
    match Ipaddr.of_string "169.254.220.46" with
    | Ok ip -> ip
    | Error _ -> failwith "failed to parse IP address"
  in
  let ctx =
    let resolver =
      let h = Hashtbl.create 1 in
      Hashtbl.add h "serving.local" (`TCP (ip, 443));
      Resolver_lwt_unix.static h
    in
    Cohttp_lwt_unix.Client.custom_ctx ~resolver ()
  in
  try Sent (Client.get ~ctx params.dest) with e -> Failed e
