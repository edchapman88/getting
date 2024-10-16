type t = Request.t Seq.t
(** A load is a lazily evaluated sequence of requests of type [Request.t]. *)

type rect_wave = {
  amplitude : float;  (** The request rate (requests/second) during bursts. **)
  period : float;  (** The delay in seconds between request bursts. **)
  pulse_length : float;  (** The duration of request bursts in seconds. **)
}
(** Parameters for request load where the request rate follows a Rectangular Wave. **)

(** Parameterised probability distrubutions for request loads. *)
type distr =
  | Point of float  (** A fixed time interval between requests in seconds. **)
  | Uniform of (float * float)
      (** The time interval between requests is uniformly distributed within the range [(start, end)], where the minimum and maximum interval times are measured in seconds. **)
  | Normal of (float * float)
      (** A normally distributed time interval between requests, in seconds. Parameterised by [(mean, std)]. **)
  | RectWave of rect_wave
      (** An extension of the [Point] distribution, where the time interval between requests is fixed (and characterised by [rect_wave.amplitude]) during bursts of requests, between which there are delays when no requests are sent. The request rate follows a rectangular wave. **)

val of_dest : ?distribution:distr -> Uri.t -> t
(** [of_dest destination] returns a [Load.t] with a default request distribution of [Point 10]: requests made at 10 second intervals with no varience in the interval. An alternative distribution can be passed, e.g. [of_dest ~distr Uniform 1. 10. destination]. *)
