type t = Request.t Seq.t
(** A [Load.t] is a lazily evaluated (and optionally infinite) sequence of requests, each of type [Request.t]. When a [Load.t] is eagerly consumed by a singe thread, one request is sent between each blocking delay that is built in to generator functions that return each element of the sequence. These delays are parameterised by the distribution of the load, [Delay.distr]. All requests in a [Load.t] sequence have a [Connection: close] HTTP header attached to ensure that server-client connections are closed immediately after the response has been received by the client. *)

val of_dest : ?distribution:Delay.distr -> Uri.t -> t
(** [of_dest destination] returns a [Load.t] with a default delay distribution of [Delay.distr.Point 10]: requests made at 10 second intervals with no varience in the interval. Optionally, an alternative distribution may be passed, e.g. [of_dest ~distr Delay.distr.Uniform 1. 10. destination]. *)
