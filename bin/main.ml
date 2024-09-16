(* hilbert = 169.254.220.46 *)
let res_parts =
  let open Lib.Request in
  let open Lwt in
  let open Cohttp in
  let req =
    {
      src = Uri.of_string "_dummy";
      dest = Uri.of_string "https://www.google.com";
    }
  in
  send req >>= fun (res, body) ->
  let code = res |> Response.status |> Code.code_of_status in
  let headers = res |> Response.headers |> Header.to_string in
  (* Inject [code:int] and [headers:string] into the [string Lwt.t] promise returned by [Cohttp_lwt.Body.to_string] to return [(int * string * string) Lwt.t] *)
  body |> Cohttp_lwt.Body.to_string >|= fun body -> (code, headers, body)

let _run_res_parts =
  match Lwt_main.run res_parts with
  | code, hd, body ->
      if code = 200 then print_endline (hd ^ "\n" ^ body)
      else failwith (Printf.sprintf "Request failed with [%d]" code)

let make_load dest = Lib.Load.of_dest dest

let body_of_res (res : Lib.Request.res) =
  res |> snd |> Cohttp_lwt.Body.to_string

let () =
  let load = make_load (Uri.of_string "//localhost:3000") in
  let handle_res promised_res =
    let open Lwt.Infix in
    promised_res >>= body_of_res >|= print_endline |> Lwt_main.run
  in
  Seq.iter handle_res load
