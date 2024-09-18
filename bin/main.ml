(* hilbert = 169.254.220.46 *)
module Serial0 = Serial.Make (struct
  let port = "/dev/cu.usbmodem2102"
  let baud_rate = 115200
end)

let make_load =
  let open Lib.Load in
  of_dest ~distribution:(Point 3.) (Uri.of_string "http://localhost:3000")

let handle_req req =
  let open Lib in
  let open Lwt.Infix in
  let score =
    match req with
    | Request.Failed e ->
        print_endline (Printexc.to_string e);
        Lwt.return Oracle.Success
    | Request.Sent res ->
        Lwt.try_bind
          (* Function to bind. *)
            (fun () -> res)
          (* On promise fulfilled. *)
            (fun res ->
            match Request.code_of_res res with
            | 200 -> Lwt.return Oracle.Success
            | _ -> Lwt.return Oracle.Fail)
          (* On promise rejected. *)
            (fun _ -> Lwt.return Oracle.Fail)
  in
  score >|= Oracle.string_of_score >>= Serial0.write_line

let rec listen chan =
  let open Domainslib in
  let open Lwt.Infix in
  let promised_write = Chan.recv chan |> handle_req in
  promised_write >>= fun () -> listen chan

let () =
  let load = make_load in
  let open Domainslib in
  (* Create a new OS thread channel to pass messages between this OS thread and any others spawned with [Domain.spawn]. *)
  let main_chan = Chan.make_unbounded () in

  (* Spawn a new OS thread running a synchronous function that makes requests at the required intervals. *)
  let requester = Domain.spawn (fun _ -> Seq.iter (Chan.send main_chan) load) in

  (* Use the main OS thread as an asynchronous runtime, handling promised responses that are received over the channel from the [requester] OS thread. *)
  let _ = Lwt_main.run (listen main_chan) in

  (* Await the termination of the requester thread (which will not terminate for never-ending request loads (that are infitite sequences). *)
  Domain.join requester
