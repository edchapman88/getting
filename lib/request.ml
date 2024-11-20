type res = Cohttp.Response.t * Cohttp_lwt.Body.t

type req_failure =
  | FailedToSend of exn  (**e.g. The connection was refused. *)
  | FailedAfterSend of exn

let string_of_req_failure = function
  | FailedToSend e -> "Request FailedToSend with: " ^ Printexc.to_string e
  | FailedAfterSend e -> "Request FailedAfterSend with: " ^ Printexc.to_string e

type req_inner = (res, req_failure) result
type t = req_inner Lwt.t

type params = {
  src : Uri.t;
  dest : Uri.t;
}

let body_of_res res = res |> snd |> Cohttp_lwt.Body.to_string

(** Module private helper for [meta_of_res]. Drains the response body before returning the response metadata. The body must be consumed otherwise Cohttp leaks connections, resulting in [Unix.Unix_error(EMFILE,"socket","")] errors (each open connection has associated unix file descriptor). *)
let drained_meta_of_res res =
  let open Lwt.Infix in
  let resp, _body = res in
  let drained = Cohttp_lwt.Body.drain_body _body in
  drained >|= fun () -> resp

let code_of_res res =
  let open Lwt.Infix in
  res |> drained_meta_of_res >|= Cohttp.Response.status
  >|= Cohttp.Code.code_of_status

let s_meta_of_res res =
  let open Lwt.Infix in
  res |> drained_meta_of_res >|= Cohttp.Response.sexp_of_t

let meta_of_res res =
  let open Lwt.Infix in
  res |> s_meta_of_res >|= Sexplib0.Sexp.to_string_hum

let send ?(headers = []) params =
  let open Cohttp_lwt_unix in
  let headers = Cohttp.Header.of_list headers in
  try
    let res_promise =
      match Resolver.get () with
      | Some resolver ->
          let ctx = Client.custom_ctx ~resolver () in
          Client.get ~headers ~ctx params.dest
      | None -> Client.get ~headers params.dest
    in
    Lwt.try_bind
      (fun () -> res_promise)
      (fun res -> Lwt.return (Ok res))
      (fun e -> Lwt.return (Error (FailedAfterSend e)))
  with e -> Lwt.return (Error (FailedToSend e))
