open Lib
open! Sexplib0

(** [print_s_server port] returns a promised http server on port [port] that handles requests by echoing an s expression of the request data. *)
let print_s_server port =
  let open Cohttp_lwt_unix in
  let callback _conn req _body =
    let s_txt = req |> Request.sexp_of_t |> Sexp.to_string in
    Server.respond_string ~status:`OK ~body:s_txt ()
  in
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback ())

let%expect_test "construct and send a request" =
  let port = 8081 in
  let server = print_s_server port in
  let params : Request.params =
    {
      src = Uri.of_string "";
      dest = Uri.of_string ("http://localhost:" ^ string_of_int port);
    }
  in
  let open Lwt.Infix in
  let headers = [ ("user-agent", "unit_tester") ] in
  let request =
    ( Lwt_unix.sleep 2.0 >>= fun () ->
      match Request.send ~headers params with
      | Request.Sent res -> res
      | Request.Failed e -> raise e )
    >>= fun res -> Request.body_of_res res >|= print_endline
  in
  Lwt_main.run (Lwt.pick [ server; request ]);
  [%expect
    {| ((headers((user-agent unit_tester)(host localhost:8081)))(meth GET)(scheme())(resource /)(version HTTP_1_1)(encoding Unknown)) |}]
