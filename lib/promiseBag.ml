type 'a t = 'a Lwt.t list
(** The implementation uses an ['a Lwt.t list] as the representation type. *)

let empty = []
let count bag = List.length bag

(** Cons the new promise onto the list that represents the promise bag. *)
let insert bag promise = promise :: bag

(** Use [List.map]. *)
let map f bag = bag |> List.map f

(** Use [Lwt.all] directly. *)
let all bag = bag |> Lwt.all

let filter_resolved bag =
  (* [check_resolved resl pend ps] recursively matches on the head [p] of the list of promises [ps]. The state of [p] is checked and it is added to either the resolved ([resl]) or pending ([pend]) accumulator. [check_resolved] is then called on the tail of list. *)
  let rec check_resolved resolved pending ps =
    match ps with
    | [] -> (resolved, pending)
    | p :: ps -> (
        match Lwt.state p with
        | Lwt.Return _ -> check_resolved (p :: resolved) pending ps
        | Lwt.Fail _ -> check_resolved (p :: resolved) pending ps
        | Lwt.Sleep -> check_resolved resolved (p :: pending) ps)
  in
  check_resolved [] [] bag

