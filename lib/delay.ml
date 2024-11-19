type t = unit Seq.t

(** [delay secs] is a thread blocking delay of [secs] seconds. *)
let delay = Unix.sleepf

let rec of_delays_s ds =
  match ds with
  | [] -> Seq.empty
  | d :: ds ->
      fun () ->
        delay d;
        Seq.Cons ((), of_delays_s ds)

type rect_wave = {
  amplitude : float;  (** The delay frequency (delays/second) during bursts. *)
  period : float;
      (** The total duration in seconds of one 'burst' of delays and one long delay. I.e. the period of the rectangular wave. *)
  pulse_length : float;
      (** The total duration of a sinlge 'burst' of delays (the up-time of the rectangular wave), in seconds. *)
}

type distr =
  | Point of float
  | Uniform of (float * float)
  | Normal of (float * float)
  | RectWave of rect_wave

(** Given the parameter (a [float]) of a [distr.Point] distribution, return a [Delay.t]. *)
let of_point interval_secs = Seq.forever (fun () -> delay interval_secs)

(** Given the parameters of a [distr.RectWave] distribution, return a [Delay.t]. *)
let of_rect_wave params =
  let n_in_pulse =
    params.pulse_length *. params.amplitude |> Float.round |> int_of_float
  in
  let real_pulse_length = float_of_int n_in_pulse /. params.amplitude in
  let down_time = params.period -. real_pulse_length in
  let pulse = 1. /. params.amplitude |> of_point |> Seq.take n_in_pulse in
  (* Construct a sequence (of type [unit Seq.t]) manually as a function of type [unit -> unit Seq.node] *)
  let period () =
    (* Include the delay which will occur when the sequence is called for this element. *)
    delay down_time;
    Seq.Cons ((), pulse)
  in
  Seq.cycle period

let of_distr = function
  | Point interval -> of_point interval
  | RectWave params -> of_rect_wave params
  | _ -> failwith "todo"
