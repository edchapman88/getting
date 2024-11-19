type t = Request.t Seq.t

type params = {
  distribution : Delay.distr;
  destination : Uri.t;
}

(** [req_params_of_params p] returns [Request.params] from the load parameters [p]. *)
let req_params_of_params p =
  let req_params : Request.params =
    { src = Uri.of_string "todo"; dest = p.destination }
  in
  req_params

(** [of_params p] returns a request load of type [Load.t] parameterised by [p] of type [params]. *)
let of_params p =
  let headers = [ ("connection", "close") ] in
  let delays = Delay.of_distr p.distribution in
  let make_request () = Request.send ~headers (req_params_of_params p) in
  Seq.map make_request delays

let of_dest ?(distribution = Delay.Point 10.) destination =
  let p = { distribution; destination } in
  of_params p
