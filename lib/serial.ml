type config = {
  baud : int;
  port : string;
}

type oc_error = string
(** Error type for failed serial connections. *)

type chan = (Lwt_io.output Lwt_io.channel, oc_error) Result.t

type conn = {
  chan : chan;
  config : config;
}
(** A serial output channel. *)

type t = conn
(** A promised result-wrapped serail output channel. The error type of the [Result] is [oc_error]. *)

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

module Warning = Once.Make ()

let write_line (conn : t) ln : t Lwt.t =
  let open Lwt.Infix in
  match conn.chan with
  | Ok oc ->
      Warning.reset ();
      Lwt_io.fprint oc ln >>= fun () -> Lwt.return conn
  | Error reason ->
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
