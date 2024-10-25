type res = Cohttp.Response.t * Cohttp_lwt.Body.t

type t =
  | Sent of res Lwt.t
  | Failed of exn

type params = {
  src : Uri.t;
  dest : Uri.t;
}

let resp_of_res res =
  let open Lwt.Infix in
  let resp, _body = res in
  (* The body must be consumed otherwise Cohttp leaks connections, resulting in [Unix.Unix_error(EMFILE,"socket","")] errors (each open connection has associated unix file descriptor). *)
  let drained = Cohttp_lwt.Body.drain_body _body in
  drained >|= fun () -> resp

let code_of_res res =
  let open Lwt.Infix in
  res |> resp_of_res >|= Cohttp.Response.status >|= Cohttp.Code.code_of_status

let body_of_res res = res |> snd |> Cohttp_lwt.Body.to_string

let s_meta_of_res res =
  let open Lwt.Infix in
  res |> resp_of_res >|= Cohttp.Response.sexp_of_t

let meta_of_res res =
  let open Lwt.Infix in
  res |> s_meta_of_res >|= Sexplib0.Sexp.to_string_hum

let send params =
  let open Cohttp_lwt_unix in
  try
    Sent
      (match Resolver.get () with
      | Some resolver ->
          let ctx = Client.custom_ctx ~resolver () in
          Client.get ~ctx params.dest
      | None -> Client.get params.dest)
  with e -> Failed e
