open Domainslib
open Lwt.Infix

type 'a handler = 'a Lwt.t -> unit Lwt.t
type 'a t = 'a handler

let of_handler (handler : 'a handler) = handler

module PromiseBag : sig
  type 'a t

  val insert : 'a t -> 'a Lwt.t -> 'a t
  val filter_resolved : 'a t -> 'a t * 'a t
  val map : ('a Lwt.t -> 'b Lwt.t) -> 'a t -> 'b t
  val to_list : 'a t -> 'a Lwt.t list
  val of_list : 'a Lwt.t list -> 'a t
end = struct
  type 'a t = 'a Lwt.t list

  let insert bag promise = promise :: bag
  let of_list l = l
  let to_list bag = bag
  let map f bag = bag |> List.map f |> of_list

  let filter_resolved bag =
    let rec check_resolved (resolved : 'a Lwt.t list) (pending : 'a Lwt.t list)
        (ps : 'a Lwt.t list) =
      match ps with
      | [] -> (resolved, pending)
      | p :: ps -> (
          match Lwt.state p with
          | Lwt.Return _ -> check_resolved (p :: resolved) pending ps
          | Lwt.Fail _ -> check_resolved (p :: resolved) pending ps
          | Lwt.Sleep -> check_resolved resolved (p :: pending) ps)
    in
    check_resolved [] [] bag
end

let rec async_loop (chan : 'a Lwt.t option Chan.t)
    (handler : 'a Lwt.t -> unit Lwt.t) (ps : 'a PromiseBag.t) =
  match Chan.recv chan with
  | None -> PromiseBag.map handler ps |> PromiseBag.to_list |> Lwt.all
  | Some promise ->
      let resolved, pending =
        promise |> PromiseBag.insert ps |> PromiseBag.filter_resolved
      in
      resolved |> PromiseBag.map handler |> PromiseBag.to_list |> Lwt.all
      >>= fun _ -> async_loop chan handler pending

let produce chan xs =
  let seq_map x = x |> Option.some |> Chan.send chan in
  Seq.iter seq_map xs;
  Chan.send chan None

let process pipe xs =
  let main_chan = Chan.make_unbounded () in
  let producer = Domain.spawn (fun () -> produce main_chan xs) in
  let _consumer =
    Lwt_main.run (async_loop main_chan pipe (PromiseBag.of_list []))
  in
  Domain.join producer
