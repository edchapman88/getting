(** A module type and functor to create a stateful module that provides the functionality to carry out a side effect once (only). The module can be reset to allow the side effect to be carried out once, again. *)

module type S = sig
  val once : (unit -> unit) -> unit
  (** [once eff] will execute the side effect on the first call on only, until [reset] is called after which the side effect is executed on the subsequent call, only. *)

  val reset : unit -> unit
  (** Reset the internal state such that a subsequent call to [once] does execute the provided side effect. *)
end

(** [Make] returns a new, stateful module of type [Once.S]. *)
module Make () : S = struct
  let doneit = ref false

  let once eff =
    if Bool.not !doneit then (
      eff ();
      doneit := true)

  let reset () = doneit := false
end
