(** A module for working with bags of promises. [PromiseBag.filter_resolved] exposes a function to filter the bag for resolved promises, returning a tuple of: a bag of the resolved promises, and a bag of the promises that are still pending, respectively. *)
type 'a t
(** A bag of promises, each of type ['a Lwt.t]. *)

val empty : 'a t
(** The empty bag. *)

val count : 'a t -> int
(** Returns the number of promises currently in the bag. *)

val insert : 'a t -> 'a Lwt.t -> 'a t
(** [insert bag p] inserts the promise [p] into the [bag], returning a new bag that contains both [p] and all of the promises that were in [bag]. *)

val filter_resolved : 'a t -> 'a t * 'a t
(** [filter_resolved bag] filters the [bag] for all of the promises that are in a resolved state. A tuple of bags is returned, the first containing the promises that are in a resolved state, the second containing all of the other promises that are in a pending state. *)

val all : 'a t -> 'a t Lwt.t
(** [all bag] behaves like [Lwt.all]. The returned promise resolves once all of the promises in the bag have resolved. The returned promise resolves to a bag of promises, each in a fulfilled state. If at least one of the promises in the bag is rejected, the returned promise is rejected, and none of the fulfilled promises (if any) are available. *)
