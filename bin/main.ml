(* hilbert = 169.254.220.46 *)

let make_load dest = Lib.Load.of_dest dest

let () =
  let load = make_load (Uri.of_string "http://localhost:3000") in
  let handle_res promised_res =
    let open Lwt.Infix in
    promised_res >>= Lib.Request.body_of_res >|= print_endline |> Lwt_main.run
  in
  Seq.iter handle_res load
