open Getting

let make_load () =
  let interval = Cli.r_interval () in
  if Cli.rectangular_wave () then
    let rate = 1. /. interval in
    let rect_wave : Delay.rect_wave =
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

let handler req_inner =
  let open Lwt.Infix in
  let score = Oracle.score_of_req_inner req_inner in
  let log =
    match Cli.log_path () with
    | None -> Lwt.return ()
    | Some path -> score >|= fun s -> Log.write_of_score path s
  in
  let serial = log >>= fun () -> Serial.write_of_score score in
  match Cli.udp_unix_addr () with
  | None -> serial
  | Some udp_addr -> serial >>= fun () -> Udp.write_of_score udp_addr score

let () =
  Cli.arg_parse ();
  let load = make_load () in
  Serial.init ();
  let pipe = Pipe.of_handler handler in
  Pipe.process pipe load
