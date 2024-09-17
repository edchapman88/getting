type t = {
  src : Uri.t;
  dest : Uri.t;
}

type res = Cohttp.Response.t * Cohttp_lwt.Body.t

let body_of_res res = res |> snd |> Cohttp_lwt.Body.to_string
let s_meta_of_res res = res |> fst |> Cohttp_lwt.Response.sexp_of_t
let meta_of_res res = res |> s_meta_of_res |> Sexplib0.Sexp.to_string_hum

let send req =
  let open Cohttp_lwt_unix in
  Client.get req.dest
