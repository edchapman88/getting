open Domainslib
open Lwt.Infix

type 'a handler = 'a Lwt.t -> unit Lwt.t
(** A promise handler, as specified in the interface. *)

type 'a t = 'a handler
(** This implementation defines ['a t] simply as an alias for an ['a handler]. *)

let of_handler (handler : 'a handler) = handler

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
