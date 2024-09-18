(* hilbert = 169.254.220.46 *)

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
  let module Serial0 = Serial.Make (struct
    let port = "/dev/stdout"
    let baud_rate = 115200
  end) in
  score >|= Oracle.string_of_score >>= Serial0.write_line

let rec listen chan =
  let open Domainslib in
  let open Lwt.Infix in
  let promised_write = Chan.recv chan |> handle_req in
  promised_write >>= fun () -> listen chan

let () =
  let load = make_load in
  let open Domainslib in
  let main_chan = Chan.make_unbounded () in
  let _req_handler =
    let top_promise : 'a Lwt.t = listen main_chan in
    Domain.spawn (fun _ -> Lwt_main.run top_promise)
  in
  Seq.iter (Chan.send main_chan) load
