open Lib
open Utils

let delays () = Delay.of_delays_s [ 1.0; 3.0; 2.0 ]

let%expect_test "query a sequence of delays" =
  let start_time = Unix.gettimeofday () in
  Seq.iter (print_delta_t ~round:true start_time) (delays ());
  [%expect {|
    1.
    4.
    6.
    |}]
