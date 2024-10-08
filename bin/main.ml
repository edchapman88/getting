(* hilbert = 169.254.220.46 *)
let make_load () =
  let open Lib in
  let rps = Cli.rps () in
  Load.of_dest ~distribution:(Point rps) (Cli.target_uri ())

let rec listen serial_conn chan =
  let open Lib in
  let open Domainslib in
  let open Lwt.Infix in
  let response = Chan.recv chan in
  let score = Oracle.score_of_res response in
  let serial_conn' = serial_conn >>= fun sc -> Serial.write_of_score sc score in
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
