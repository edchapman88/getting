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
let s_meta_of_res res = res |> fst |> Cohttp_lwt.Response.sexp_of_t
let meta_of_res res = res |> s_meta_of_res |> Sexplib0.Sexp.to_string_hum

let send params =
  let open Cohttp_lwt_unix in
  try Sent (Client.get params.dest) with e -> Failed e
