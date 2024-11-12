let make_load () =
  let open Lib in
  let interval = Cli.r_interval () in
  if Cli.rectangular_wave () then
    let rate = 1. /. interval in
    let rect_wave : Load.rect_wave =
      {
        (*Request rate (requests/second) during each pulse. *)
        amplitude = rate;
        (* Pulse length of 90ms. *)
        pulse_length = 90. /. 1000.;
        (* Rectangular wave period of 1s. *)
        period = 1.;
      }
    in
    Load.of_dest ~distribution:(RectWave rect_wave) (Cli.target_uri ())
  else Load.of_dest ~distribution:(Point interval) (Cli.target_uri ())

(** An asynchronous recursive listening loop. Receiving promised responses over a channel (sent by a seperate thread), and processing them to obtain a score which is written to a serial connection and optionally a log file. *)
let rec listen serial_conn chan =
  let open Lib in
  let open Domainslib in
  let open Lwt.Infix in
  let request = Chan.recv chan in
  let score = Oracle.score_of_req request in
  let log =
    match Cli.log_path () with
    | None -> Lwt.return ()
    | Some path -> score >|= fun s -> Log.write_of_score path s
  in
  let serial_conn' = serial_conn >>= fun sc -> Serial.write_of_score sc score in
  log >>= fun () ->
  serial_conn' >>= fun _ -> listen serial_conn' chan

let () =
  let open Lib in
  Cli.arg_parse ();
  let serial_conn = Serial.make { baud = 115200; port = !Cli.serial_port } in
  let load = make_load () in
  let open Domainslib in
  (* Create a new OS thread channel to pass messages between this OS thread and any others spawned with [Domain.spawn]. *)
  let main_chan = Chan.make_unbounded () in

  (* Spawn a new OS thread running a synchronous function that makes requests at the required intervals. *)
  let requester = Domain.spawn (fun _ -> Seq.iter (Chan.send main_chan) load) in

  (* Use the main OS thread as an asynchronous runtime, handling promised responses that are received over the channel from the [requester] OS thread. *)
  let _ = Lwt_main.run (listen serial_conn main_chan) in

  (* Await the termination of the requester thread (which will not terminate for never-ending request loads (that are infitite sequences). *)
  Domain.join requester
