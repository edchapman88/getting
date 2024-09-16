type t = Request.res Lwt.t Seq.t
(** A load is a lazily evaluated sequence of promised responses of type [Request.res]. *)

(** Parameterised probability distrubutions *)
type distr =
  | Point of float
  | Uniform of (float * float)
  | Normal of (float * float)

val of_dest : ?distribution:distr -> Uri.t -> t
(** [of_dest destination] returns a [Load.t] with a default request distribution of [Point 10]: requests made at 10 second intervals with no varience in the interval. An alternative distribution can be passed, e.g. [of_dest ~distr Uniform 1. 10. destination]. *)
