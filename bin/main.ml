(* hilbert = 169.254.220.46 *)
let make_load =
  let open Lib.Load in
  (*of_dest ~distribution:(Point 0.01) (Uri.of_string "http://169.254.220.46:80")*)
  of_dest ~distribution:(Point 1.) (Uri.of_string "http://127.0.0.1:3000")

let handle_req serial_conn req : Lib.Serial.t Lwt.t =
  let open Lib in
  let open Lwt.Infix in
  let score =
    match req with
    | Request.Failed e -> Lwt.return (Oracle.Fail (Printexc.to_string e))
    | Request.Sent res ->
        Lwt.try_bind
          (* Function to bind. *)
            (fun () -> res)
          (* On promise fulfilled. *)
            (fun res ->
            let code = Request.code_of_res res in
            match code with
            | 200 -> Lwt.return Oracle.Success
            | _ -> Lwt.return (Oracle.Fail (string_of_int code)))
          (* On promise rejected. *)
            (fun e -> Lwt.return (Oracle.Fail (Printexc.to_string e)))
  in
  let serial' =
    score >|= Oracle.string_of_score >>= fun ln ->
    Lib.Serial.write_line serial_conn ln
  in
  serial'

let rec listen serial_conn chan =
  let open Domainslib in
  let open Lwt.Infix in
  let serial_conn' = serial_conn >>= fun sc -> handle_req sc (Chan.recv chan) in
  serial_conn' >>= fun _ -> listen serial_conn' chan

let () =
  let open Lib in
  Cli.arg_parse ();
  let serial_conn = Serial.make { baud = 115200; port = !Cli.serial_port } in
  let load = make_load in
  let open Domainslib in
  (* Create a new OS thread channel to pass messages between this OS thread and any others spawned with [Domain.spawn]. *)
  let main_chan = Chan.make_unbounded () in

  (* Spawn a new OS thread running a synchronous function that makes requests at the required intervals. *)
  let requester = Domain.spawn (fun _ -> Seq.iter (Chan.send main_chan) load) in

  (* Use the main OS thread as an asynchronous runtime, handling promised responses that are received over the channel from the [requester] OS thread. *)
  let _ = Lwt_main.run (listen serial_conn main_chan) in

  (* Await the termination of the requester thread (which will not terminate for never-ending request loads (that are infitite sequences). *)
  Domain.join requester
