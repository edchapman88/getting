open Lwt
open Cohttp
open Cohttp_lwt_unix

let body = 
  Client.get (Uri.of_string "http://169.254.220.46:3000") >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    Printf.printf "Response code: %d\n" code;
    Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
    body |> Cohttp_lwt.Body.to_string

let () =
  let body = Lwt_main.run body in
  print_endline ("received body:\n" ^ body)
