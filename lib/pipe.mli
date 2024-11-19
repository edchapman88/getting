(** Abstract interface for an encapsulated, double-threaded sync-producer-async-consumer. [pipe] takes as input a sequence of promises. The sequence is eagerly processed by the synchronous producer thread, and the promises obtained are written to an unbounded channel. The async-consumer thread receives the promises over the channel and handles them asynchronously (plausibly out-of-order). *)

type 'a t
(** ['a Pipe.t] is an encapsulated, double-threaded sync-producer-async-consumer of a promise sequence. The promises are of type ['a Lwt.t]. *)

type 'a handler = 'a -> unit Lwt.t
(** ['a handler] is a function to handle promises of type ['a Lwt.t]. It is possibe to define a function to act as a handler that retains the ['a] values that the promises resolve to, e.g. [f : 'a list ref -> 'a -> unit Lwt.t] when partially applied to an ['a list ref] is of type [handler]. *)

val of_handler : 'a handler -> 'a t
(** [of_handler handler] creates a [Pipe.t] that processes promise sequences of type ['a Lwt.t Seq.t]  with the handler function [handler]. *)

val process : 'a t -> 'a Lwt.t Seq.t -> unit
(** [process pipe xs] processes the sequence of promises, [xs], using the [pipe]. *)
