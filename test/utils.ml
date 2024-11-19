(*let delta_t _start () = Unix.gettimeofday ()*)

let delta_t ?(round = false) start () =
  let delta = Unix.gettimeofday () -. start in
  if round then Float.round delta else delta

let string_of_delta_t ?(round = false) start () =
  delta_t ~round start () |> string_of_float

let print_delta_t ?(round = false) start () =
  string_of_delta_t ~round start () |> print_endline
