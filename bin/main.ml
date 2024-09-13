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

let () =
  match Lwt_main.run res_parts with
  | code, hd, body ->
      if code = 200 then print_endline (hd ^ "\n" ^ body)
      else failwith (Printf.sprintf "Request failed with [%d]" code)
