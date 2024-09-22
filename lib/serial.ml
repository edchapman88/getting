type config = {
  baud : int;
  port : string;
}

type oc_error = string
(** Error type for failed serial connections. *)

type fd = (Lwt_unix.file_descr, oc_error) Result.t
type chan = (Lwt_io.output Lwt_io.channel, oc_error) Result.t

type conn = {
  fd : fd;
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
  let fd_promise = raw_fd |> result_lwt_of_lwt in
  setup >>= fun _ ->
  fd_promise >>= fun fd ->
  chan_promise >>= fun chan -> Lwt.return { chan; config; fd }

module Once = struct
  let once = ref false
  let _get () = !once

  let run f =
    if Bool.not !once then (
      f ();
      once := true)

  let reset () = once := false
end

let write_line (conn : t) ln : t Lwt.t =
  let open Lwt.Infix in
  match conn.chan with
  | Ok oc ->
      Once.reset ();
      let fd_inner =
        match conn.fd with
        | Ok inner -> inner
        | Error _ -> failwith "handle later"
      in
      (match Lwt_unix.state fd_inner with
      | Lwt_unix.Opened -> print_endline "open"
      | Lwt_unix.Closed -> print_endline "closed"
      | Lwt_unix.Aborted _ -> print_endline "aborted");
      Lwt_io.fprintl oc ln >>= fun () -> Lwt.return conn
  | Error reason -> (
      Once.run (fun () -> print_endline reason);
      let new_conn = make conn.config in
      new_conn >>= fun nc ->
      match nc.chan with
      | Ok _ ->
          print_endline "fixed";
          Lwt.return nc
      | Error _ ->
          print_endline "still broken";
          Lwt.return nc)
(*new_conn*)
