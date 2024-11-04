type t = Request.t Seq.t

type rect_wave = {
  amplitude : float;  (** The request rate (requests/second) during bursts. *)
  period : float;  (** The delay in seconds between request bursts. *)
  pulse_length : float;  (** The duration of request bursts in seconds. *)
}

type distr =
  | Point of float
  | Uniform of (float * float)
  | Normal of (float * float)
  | RectWave of rect_wave

type params = {
  distribution : distr;
  destination : Uri.t;
}

(** Private module for (optionally infinite) sequences of thread blocking delays, parameterised by a [Load.distr]. The delays can by mapped or interleaved with other sequences. *)
module Delay : sig
  type t = unit Seq.t
  (** [Delay.t] is a sequence [xs] that when called ([xs()]) produces an element of type [unit] after a desired delay. *)

  val of_distr : distr -> t
  (** [of_distr distr] returns a [Delay.t] with the properites described in the distribution [distr]. *)
end = struct
  type t = unit Seq.t

  (** [delay secs] is a thread blocking delay of [secs] seconds. *)
  let delay = Unix.sleepf

  (** Given the inter-request interval that parameterises a [Load.distr.Point] distribution, return a [Delay.t]. *)
  let of_point interval_secs = Seq.forever (fun () -> delay interval_secs)

  (** Given the parameters of a [Load.distr.RectWave] distribution, return a [Delay.t]. *)
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
end

(** [req_params_of_params p] returns [Request.params] from the load parameters [p]. *)
let req_params_of_params p =
  let req_params : Request.params =
    { src = Uri.of_string "todo"; dest = p.destination }
  in
  req_params

(** [of_params p] returns a request load of type [Load.t] parameterised by [p] of type [params]. *)
let of_params p =
  let delays = Delay.of_distr p.distribution in
  let make_request () = Request.send (req_params_of_params p) in
  Seq.map make_request delays

let of_dest ?(distribution = Point 10.) destination =
  let p = { distribution; destination } in
  of_params p
