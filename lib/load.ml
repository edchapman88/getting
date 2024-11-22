type t = Request.t Seq.t

type params = {
  distribution : Delay.distr;
  destination : Uri.t;
}

(** Helper function to evaluate an appropriate request timeout such that the expected maximum number of pending requests is 1,000. *)
let timeout_of_distr distr =
  let mean_req_period = Delay.mean_of_distr distr in
  let mean_req_rate = 1.0 /. mean_req_period in
  1000.0 /. mean_req_rate

(** [req_params_of_params p] returns [Request.params] from the load parameters [p]. *)
let req_params_of_params p =
  let req_params : Request.params =
    { src = Uri.of_string "todo"; dest = p.destination }
  in
  req_params

(** [of_params p] returns a request load of type [Load.t] parameterised by [p] of type [params]. *)
let of_params p =
  let headers = [ ("connection", "close") ] in
  let timeout = timeout_of_distr p.distribution in
  let delays = Delay.of_distr p.distribution in
  let make_request () =
    Request.send ~timeout ~headers (req_params_of_params p)
  in
  Seq.map make_request delays

let of_dest ?(distribution = Delay.Point 10.) destination =
  let p = { distribution; destination } in
  of_params p
