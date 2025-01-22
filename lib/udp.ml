let sendto addr msg =
  let open Lwt.Infix in
  let fd = Lwt_unix.socket ~cloexec:true PF_INET SOCK_DGRAM 0 in
  Lwt_unix.sendto fd (String.to_bytes msg) 0 (String.length msg) [] addr
  >|= fun code -> if code = -1 then Error "UDP: failed to send" else Ok ()

module Warning =
Once.Make ()
(** Make a [Once] module (a stateful module for conveniently managing side-effects that should be executed only once). *)

let write_of_score addr score =
  let open Lwt.Infix in
  score >|= Oracle.string_of_score ~debug:false >>= fun str ->
  sendto addr str >>= function
  | Ok () ->
      Warning.reset ();
      Lwt.return ()
  | Error reason ->
      Warning.once (fun () -> print_endline reason);
      Lwt.return ()

let addr_of_string addr_str =
  let handle_err ?msg () =
    match msg with
    | None ->
        failwith
          (Printf.sprintf
             "Failed parsing '%s' as a UDP address and port. Format should \
              match e.g. '192.168.0.0:8081'"
             addr_str)
    | Some msg ->
        failwith
          (Printf.sprintf
             "Failed parsing '%s' as a UDP address and port. Format should \
              match e.g. '192.168.0.0:8081': %s"
             addr_str msg)
  in
  let ip, port =
    match String.split_on_char ':' addr_str with
    | [ ip; port ] -> (ip, port)
    | _ -> handle_err ()
  in
  let addr =
    try Unix.inet_addr_of_string ip with Failure msg -> handle_err ~msg ()
  in
  let port_int =
    try int_of_string port with Failure msg -> handle_err ~msg ()
  in
  Lwt_unix.ADDR_INET (addr, port_int)
