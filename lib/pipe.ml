open Domainslib
open Lwt.Infix

type 'a handler = 'a Lwt.t -> unit Lwt.t
(** A promise handler, as specified in the interface. *)

type 'a t = 'a handler
(** This implementation defines ['a t] simply as an alias for an ['a handler]. *)

let of_handler (handler : 'a handler) = handler

(** A helper module for working with bags of promises. [PromiseBag.filter_resolved] exposes a function to filter the bag for resolved promises, returning a tuple of: a bag of the resolved promises, and a bag of the promises that are still pending, respectively. *)
module PromiseBag : sig
  type 'a t
  (** A bag of promises, each of type ['a Lwt.t]. *)

  val empty : 'a t
  (** The empty bag. *)

  val insert : 'a t -> 'a Lwt.t -> 'a t
  (** [insert bag p] inserts the promise [p] into the [bag], returning a new bag that contains both [p] and all of the promises that were in [bag]. *)

  val filter_resolved : 'a t -> 'a t * 'a t
  (** [filter_resolved bag] filters the [bag] for all of the promises that are in a resolved state. A tuple of bags is returned, the first containing the promises that are in a resolved state, the second containing all of the other promises that are in a pending state. *)

  val map : ('a Lwt.t -> 'b Lwt.t) -> 'a t -> 'b t
  (** [map f bag] applies [f] to each of the promises in the [bag]. *)

  val all : 'a t -> 'a list Lwt.t
  (** [all bag] behaves like [Lwt.all]. The returned promise resolves once all of the promises in the bag have resolved. The returned promise resolves to a list of the values resolved from the promises in the bag. If at least one of the promises in the bag is rejected, the returned promise is rejected, and none of the fulfilled promises (if any) are available. *)
end = struct
  type 'a t = 'a Lwt.t list
  (** The implementation uses an ['a Lwt.t list] as the representation type. *)

  let empty = []

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
end

(** Helper function to filter a promise bag, handle the resolved promises (awaiting their completion) and return a promised promise bag containing the pending promises. *)
let filter_and_handle (handler : 'a handler) ps =
  let resolved, pending = PromiseBag.filter_resolved ps in
  (* Handle all resolved promises to completion. This blocks until all of the promises returned by the handler are resolved. *)
  resolved |> PromiseBag.map handler |> PromiseBag.all >>= fun _ ->
  Lwt.return pending

(** [async_loop chan handler ps] polls the channel [chan] for the existence of a buffered [Option.t]. If present, [None] signals the end of production by the producer. If present and [Some p], the promise [p] is read from the buffer and inserted into the promise bag [ps]. Only a single promise is read from the channel even if there are several buffered. *)
let rec async_loop chan handler ps =
  let poll = Chan.recv_poll chan in
  if Option.is_some poll then
    match Option.get poll with
    (* [None] signal the end of production by the producer, wait for all pending promises to resolve before returning from the recursive loop. *)
    | None -> PromiseBag.map handler ps |> PromiseBag.all
    | Some promise ->
        let ps' = promise |> PromiseBag.insert ps in
        filter_and_handle handler ps' >>= fun pending ->
        async_loop chan handler pending
  else
    (* The buffered channel [chan] is empty. Handle any resolved promises in the current promise bag [ps] before re-entering the [async_loop] to poll the channel again. *)
    filter_and_handle handler ps >>= fun pending ->
    async_loop chan handler pending

(** [produce chan xs] is the task to be executed by the synchronous producer thread. The sequence [xs] is greedily consumed and the elements immediately sent over the unbounded channel [chan]. Elements of the sequence are wrapped as [Some] values to distinguish them from the [None] value that is written to the channel when the sequence [xs] has terminated. *)
let produce chan xs =
  let seq_map x = x |> Option.some |> Chan.send chan in
  Seq.iter seq_map xs;
  Chan.send chan None

(** [consume chan pipe] is the task to be executed by the asynchronous consumer thread, hence it is a promise. An [async_loop] is set up which reads promises from the channel [chan], maintains a bag of unresolved promises and handles promises as they resolve with [handler]. *)
let consume chan handler = async_loop chan handler PromiseBag.empty

let process pipe xs =
  let main_chan = Chan.make_unbounded () in
  let producer = Domain.spawn (fun () -> produce main_chan xs) in
  let _consumer = Lwt_main.run (consume main_chan pipe) in
  Domain.join producer
