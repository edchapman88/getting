(** Parameterised probability distrubutions *)
type distr =
  | Point of float
  | Uniform of (float * float)
  | Normal of (float * float)

type t = {
  interval_sec : distr;
  dest : Uri.t;
}
(** The representation type for a request load. The load is modelled by the probability over the interval (in seconds) between requests. *)

let of_dest ?(distribution = Point 10.) destination =
  { interval_sec = distribution; dest = destination }

let delay = Unix.sleepf

let req_of_load load =
  let req : Request.t = { src = Uri.of_string "todo"; dest = load.dest } in
  req

let run load =
  Seq.forever (fun () ->
      (match load.interval_sec with
      | Point secs -> delay secs
      | _ -> failwith "todo");

      Request.send (req_of_load load))
