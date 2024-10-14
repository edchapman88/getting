type score =
  | Success
  | Fail of string

let string_of_score = function
  | Success -> "1"
  | Fail reason -> "0 : " ^ reason

let score_of_res req : score Lwt.t =
  let score =
    match req with
    | Request.Failed e ->
        Lwt.return (Fail ("Failed to send: " ^ Printexc.to_string e))
    | Request.Sent res ->
        Lwt.try_bind
          (* Function to bind. *)
            (fun () -> res)
          (* On promise fulfilled. *)
            (fun res ->
            let code = Request.code_of_res res in
            match code with
            | 200 -> Lwt.return Success
            | _ -> Lwt.return (Fail (string_of_int code)))
          (* On promise rejected. *)
            (fun e ->
            Lwt.return
              (Fail ("Response promise rejected: " ^ Printexc.to_string e)))
  in
  score
