open Domainslib
open Lwt.Infix

type 'a handler = 'a -> unit Lwt.t
(** A promise handler, as specified in the interface. *)

type 'a t = 'a handler
(** This implementation defines ['a t] simply as an alias for an ['a handler]. *)

let of_handler (handler : 'a handler) = handler

(** A varient to capture the possible return types from the main [async_loop] carried out by the async-consumer. *)
type 'a async_event =
  | NewMsg of 'a Lwt.t option
      (** A new message received on the channel from the sync-producer. *)
  | Timeout
      (** A timeout, used to re-enter the [async_loop] periodically to re-poll the channel. *)

(** [poll_chan chan] is one of the three tasks to be carried out concurrently by the async-consumer in the main [async_loop]. The channel [chan] is polled and if there is least one message then an immediatley fulfilled promise is returned, containing the (first) message. If the channel is currently empty then a cancellable, but infinitely pending promise is returned. *)
let poll_chan chan =
  match Chan.recv_poll chan with
  | None -> Lwt.task () |> fst
  | Some msg -> Lwt.return (NewMsg msg)

(** [timeout secs] is another of the three tasks to be carried out concurrently by the async-consumer in the main [async_loop]. The promise returned will resolve after [secs] seconds. *)
let timeout secs = secs |> Lwt_unix.sleep >|= fun () -> Timeout

(** [resolve_bag bag] is another of the three tasks to be carried out concurrently by the async-consumer in the main [async_loop]. The [PromiseBag.t] [bag] is 'awaited' until all of the promises within are resolved. This occurs if the async-consumer processes promises faster than the sync-producer writes them to the channel. The async-consumer must continue listening on the channel, so a cancellable, but infinitely pending promise is returned. *)
let resolve_bag bag = PromiseBag.all bag >>= fun _bag -> Lwt.task () |> fst

(** [async_loop chan handler ps] is the main recursive loop carried out by the async-consumer. Three tasks are carried out concurrently: polling the channel for new promises sent by the sync-producer, 'awaiting' the resolution of the promises accumulated in a [PromiseBag.t], and awaiting the resolution of a timeout - at which point the [async_loop] is re-entered. A [None] message on the channel signals the end of production by the producer and this is the only event that causes an exit from the recursion of [async_loop]. [Lwt.pick] is used to orchestrate the concurrency of the three tasks. Lwt attempts to cancel all pending promises when the promise returned by [Lwt.pick] resolves. This is desirable because the infinitely pending tasks that are possibly returned by [poll_chan] and [resolve_bag] are cancelled after each recursion of [async_loop]. The promises maintained in the promise bag are protected from cancellation with [Lwt.no_cancel]. *)
let rec async_loop chan handler ps =
  (* Prune the promise bag discarding resolved promises. This would be a memory leak. *)
  let _resolved, ps = PromiseBag.filter_resolved ps in
  let event_promise =
    Lwt.pick [ poll_chan chan; resolve_bag ps; timeout 1.0 ]
  in
  event_promise >>= fun event ->
  match event with
  | NewMsg msg -> (
      match msg with
      | None ->
          PromiseBag.all ps >|= fun _bag ->
          () (* The result from Promise.all is not meaningful to return. *)
      | Some promise ->
          let ps' =
            promise |> Lwt.no_cancel >>= handler |> PromiseBag.insert ps
          in
          async_loop chan handler ps')
  | Timeout -> async_loop chan handler ps

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
