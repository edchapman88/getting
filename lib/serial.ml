type config = {
  baud : int;
  port : string;
}

type oc_error = string
(** Error type for failed serial connections. *)

type chan = (Lwt_io.output Lwt_io.channel, oc_error) Result.t

type t = {
  chan : chan;
  config : config;
}
(** A serial connection is an output channel and the config required to (re-)create it. *)

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

(** Convenience function to map an ['a lwt.t] to an [('a, string) result lwt.t]. Rejected promises are mapped to [Error]; fulfilled promises to [Ok]. *)
let result_lwt_of_lwt promise =
  Lwt.try_bind
    (fun () -> promise)
    (fun inner -> inner |> Result.ok |> Lwt.return)
    (fun e -> e |> Printexc.to_string |> Result.error |> Lwt.return)

let make config : t Lwt.t =
  let open Lwt.Infix in
  let raw_fd =
    Lwt_unix.openfile config.port [ Unix.O_RDWR; Unix.O_NONBLOCK ] 0o000
  in
  let chan_promise =
    raw_fd >|= Lwt_io.of_fd ~mode:Lwt_io.output |> result_lwt_of_lwt
  in
  let setup = set_baud raw_fd config.baud |> result_lwt_of_lwt in
  setup >>= fun _ ->
  chan_promise >>= fun chan -> Lwt.return { chan; config }

module Warning =
Once.Make ()
(** Make a [Once] module (a stateful module for conveniently managing side-effects that should be executed only once). *)

let write_line (conn : t) ln : t Lwt.t =
  let open Lwt.Infix in
  match conn.chan with
  | Ok oc ->
      (* In the event of a new connection, reset the [Once] module so that a new error will be displayed (once) if this new connection fails. *)
      Warning.reset ();
      Lwt_io.fprint oc ln >>= fun () -> Lwt.return conn
  | Error reason ->
      (* In case of an error, print an error message only once. *)
      Warning.once (fun () -> print_endline reason);
      let new_conn = make conn.config in
      new_conn

let write_of_score serial_conn score =
  let open Lwt.Infix in
  let debug = Cli.serial_debug () in
  let serial' =
    score >|= Oracle.string_of_score ~debug >>= fun ln ->
    write_line serial_conn ln
  in
  serial'
