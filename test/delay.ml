open Lib

let delays () = Delay.of_delays_s [ 1.0; 3.0; 2.0 ]

let print_time start () =
  Unix.time () -. start |> string_of_float |> print_endline

let%expect_test "query a sequence of delays" =
  let start_time = Unix.time () in
  Seq.iter (print_time start_time) (delays ());
  [%expect {|
    1.
    4.
    6.
    |}]
