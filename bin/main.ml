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
  score >>= Oracle.write_score "/dev/stdout"

let () =
  let load = make_load in
  let open Domainslib in
  let main_chan = Chan.make_unbounded () in
  let _ = Domain.spawn (fun _ -> Lwt_main.run (Chan.recv main_chan)) in
  Seq.iter (fun req -> Chan.send main_chan (handle_req req)) load
