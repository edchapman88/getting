module type S = sig
  val once : (unit -> unit) -> unit
  val reset : unit -> unit
end

module Make () : S = struct
  let doneit = ref false

  let once effect =
    if Bool.not !doneit then (
      effect ();
      doneit := true)

  let reset () = doneit := false
end
