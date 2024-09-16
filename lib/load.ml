(** Parameterised probability distrubutions *)
type distr =
  | Point of float
  | Uniform of (float * float)
  | Normal of (float * float)

type t = Request.res Lwt.t Seq.t
(** Representation type for a request load. *)

type params = {
  interval_sec : distr;
  dest : Uri.t;
}
(** Parameters for a request load. The load is modelled by the probability over the interval (in seconds) between requests. *)

(** [delay secs] is a thread blocking delay of [secs] seconds. *)
let delay = Unix.sleepf

(** [req_of_params p] returns a [Request.t] from the parameters [p]. *)
let req_of_params p =
  let req : Request.t = { src = Uri.of_string "todo"; dest = p.dest } in
  req

(** [of_params p] returns a request load of type [Load.t] parameterised by [p] of type [params]. *)
let of_params p =
  Seq.forever (fun () ->
      (match p.interval_sec with
      | Point secs -> delay secs
      | _ -> failwith "todo");
      Request.send (req_of_params p))

(** [of_dest d] returns a request load configured for the destination [d] with a default request interval that is constant and 10 seconds. *)
let of_dest ?(distribution = Point 10.) destination =
  let p = { interval_sec = distribution; dest = destination } in
  of_params p
