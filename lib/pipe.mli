(** Abstract interface for an encapsulated, double-threaded sync-producer-async-consumer. [pipe] takes as input a sequence of promises. The sequence is greedily processes by the synchronous producer thread, and the promises obtained are written to an unbounded channel. The async-consumer thread receives promises over the channel and handles them asynchronously (plausibly out-of-order). *)

type 'a t
(** [Pipe.t] is an encapsulated, double-threaded sync-producer-async-consumer of a promise sequence. *)

val of_handler : ('a -> unit Lwt.t) -> 'a t
(** [of_handler handler] creates a [Pipe.t] that handles promises of type ['a Lwt.t]  with the function [handler : 'a -> 'b]. *)

val process : 'a t -> 'a Lwt.t Seq.t -> unit
(** [process pipe xs] processes the sequence of promises, [xs], using the [pipe]. *)
