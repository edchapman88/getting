(** Create (optionally infinite) sequences of thread blocking delays. Either specifying the delays explicitely or by passing a parameterised distribution of type [distr]. The delays can by mapped or interleaved with other sequences. E.g. [Seq.map get_random delays], where [get_random: unit -> int] is a function that returns a random integer, and [delays] is of type [Delay.t]. This would create a sequence that lazily evaluates a random integer after a delay. *)

type t = unit Seq.t
(** [Delay.t] is a sequence [xs] that when queried produces an element of type [unit] after a desired delay. *)

val of_delays_s : float list -> t
(** [of_delays_s ds] returns a sequence of type [Delay.t]. Each float in the list [d] maps one-to-one to an element in the sequence, which when queried, will return [unit] following a [d]-second delay. The delays occur in the same order as they appear in the list. *)

type rect_wave = {
  amplitude : float;  (** The delay frequency (delays/second) during bursts. *)
  period : float;
      (** The total duration in seconds of one 'burst' of delays followed by one long delay. I.e. the period of the rectangular wave. *)
  pulse_length : float;
      (** The total duration of a single 'burst' of delays (the up-time of the rectangular wave), in seconds. *)
}
(** Parameters for a delay sequence that resembles a rectangular wave. Used to construct a ([RectWave]). *)

(** Parameterised distrubutions for sequences of time delays. *)
type distr =
  | Point of float  (** A delay length in seconds. *)
  | Uniform of (float * float)
      (** The length of each delay is uniformly distributed within the range [(start, end)], where the minimum and maximum delay times are measured in seconds. *)
  | Normal of (float * float)
      (** The length of each delay is normally distributed. Parameterised by [(mean, std)]. *)
  | RectWave of rect_wave
      (** An extension of the [Point] distribution, where the length of delays is fixed (and characterised by [rect_wave.amplitude]) during the up-time of rectangular wave. Between these 'bursts' of short delays there is a single, longer delay (the down-time of the rectangular wave). *)

val mean_of_distr : distr -> float
(** [mean_of_distr distr] returns the mean delay length for the distribution [distr]. *)

val of_distr : distr -> t
(** [of_distr distr] returns a [Delay.t] with the properites described in the distribution [distr]. *)
