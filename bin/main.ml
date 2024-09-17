(* hilbert = 169.254.220.46 *)

let make_load =
  let open Lib.Load in
  of_dest ~distribution:(Point 3.) (Uri.of_string "http://localhost:3000")

let () =
  let load = make_load in
  let handle_res promised_res =
    let open Lwt.Infix in
    promised_res >>= Lib.Request.body_of_res >|= print_endline |> Lwt_main.run
  in
  Seq.iter handle_res load
