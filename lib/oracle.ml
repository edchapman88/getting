type score =
  | Success
  | Fail of string

(** Serialise [Success] and [Fail] to "1" and "0", respectively. If [debug = true], include a newline character and reason for failure following a semi-colon. *)
let string_of_score ?(debug = false) = function
  | Success -> if debug then "1\n" else "1"
  | Fail reason -> if debug then "0 : " ^ reason ^ "\n" else "0"

(** Implementer's criteria for scoring: [Success] if the status code of the response is 200, [Fail] otherwise. *)
let score_of_req req : score Lwt.t =
  let open Lwt.Infix in
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
            res |> Request.code_of_res >|= fun code ->
            match code with
            | 200 -> Success
            | _ -> Fail (string_of_int code))
          (* On promise rejected. *)
            (fun e ->
            Lwt.return
              (Fail ("Response promise rejected: " ^ Printexc.to_string e)))
  in
  score
