type config = {
  baud : int;
  port : string;
}

type oc_error = string
(** Error type for failed serial connections. *)

type t = (Lwt_io.output Lwt_io.channel, oc_error) Result.t

(** Set the baud rate on a Unix file *)
let set_baud fd rate =
  let open Lwt.Infix in
  Lwt.bind fd (fun fd ->
      fd |> Lwt_unix.tcgetattr >>= fun attr ->
      Lwt_unix.tcsetattr fd Unix.TCSANOW
        {
          attr with
          c_ibaud = rate;
          c_obaud = rate;
          c_echo = false;
          c_icanon = false;
        })

let serial_conn = ref None

let init () =
  let open Lwt.Infix in
  let config = { baud = 115200; port = !Cli.serial_port } in
  let raw_fd =
    Lwt_unix.openfile config.port [ Unix.O_RDWR; Unix.O_NONBLOCK ] 0o000
  in
  let chan_promise =
    raw_fd >|= Lwt_io.of_fd ~mode:Lwt_io.output |> Utils.result_lwt_of_lwt
  in
  let setup = set_baud raw_fd config.baud |> Utils.result_lwt_of_lwt in
  let conn = setup >>= fun _ -> chan_promise in
  serial_conn := Some conn

module Warning =
Once.Make ()
(** Make a [Once] module (a stateful module for conveniently managing side-effects that should be executed only once). *)

let write_line ln =
  let open Lwt.Infix in
  if Option.is_none !serial_conn then init ();
  let conn = Option.get !serial_conn in
  conn >>= fun chan ->
  match chan with
  | Ok oc ->
      (* In the event of a new connection, reset the [Once] module so that a new error will be displayed (once) if this new connection fails. *)
      Warning.reset ();
      (* This promise is fulfilled even when a write is attempted to a hanging file descriptor, e.g. a file descriptor that was succesfully created but the file no longer exists. *)
      Lwt_io.fprint oc ln
  | Error reason ->
      (* In case of an error when trying to create the file descriptor (e.g. the file does not exist), print an error message only once. *)
      Warning.once (fun () -> print_endline reason);
      (* And try to re-initialise the serial connection. *)
      init ();
      Lwt.return ()

let write_of_score score =
  let open Lwt.Infix in
  let debug = Cli.serial_debug () in
  score >|= Oracle.string_of_score ~debug >>= fun ln -> write_line ln
