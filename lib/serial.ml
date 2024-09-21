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

let chan_promise_of_oc_promise (oc_promise : Lwt_io.output Lwt_io.channel Lwt.t)
    : chan Lwt.t =
  Lwt.try_bind
    (fun () -> oc_promise)
    (fun oc -> oc |> Result.ok |> Lwt.return)
    (fun e -> e |> Printexc.to_string |> Result.error |> Lwt.return)

let make config : t Lwt.t =
  let open Lwt.Infix in
  let fd =
    Lwt_unix.openfile config.port [ Unix.O_RDWR; Unix.O_NONBLOCK ] 0o000
  in
  let oc_promise = fd >|= Lwt_io.of_fd ~mode:Lwt_io.output in
  let setup = set_baud fd config.baud in
  let chan_promise : chan Lwt.t =
    setup >>= fun () -> chan_promise_of_oc_promise oc_promise
  in
  chan_promise >>= fun chan -> Lwt.return { chan; config }

let warned_once = ref false

let write_line (conn : t) ln : t Lwt.t =
  let open Lwt.Infix in
  match conn.chan with
  | Ok oc ->
      warned_once := false;
      Lwt_io.fprintl oc ln >>= fun () -> Lwt.return conn
  | Error reason ->
      if Bool.not !warned_once then Printf.eprintf "%s" reason;
      warned_once := true;
      let new_conn = make conn.config in
      new_conn
