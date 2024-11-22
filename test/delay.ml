open Lib
open Utils

let delays () = Delay.of_delays_s [ 1.0; 3.0; 2.0 ]

let p_distr_mean result = function
  | Delay.Uniform (start, endd) ->
      Format.sprintf "Uniform [%.2f, %.2f] -> %.2f" start endd result
      |> print_endline
  | Delay.RectWave params ->
      Format.sprintf
        "RectWave [amp=%.2f, period=%.2f, pulse_length=%.2f] -> %.2f"
        params.amplitude params.period params.pulse_length result
      |> print_endline
  | _ -> failwith "unreachable"

let%expect_test "query a sequence of delays" =
  let start_time = Unix.gettimeofday () in
  Seq.iter (print_delta_t ~round:true start_time) (delays ());
  [%expect {|
    1.
    4.
    6.
    |}]

let%expect_test "calculate mean delay length for a [distr]" =
  let open Delay in
  let uniform = Uniform (2.0, 6.0) in
  p_distr_mean (Delay.mean_of_distr uniform) uniform;
  let rectwave =
    RectWave { amplitude = 6.0; period = 1.0; pulse_length = 0.5 }
  in
  p_distr_mean (Delay.mean_of_distr rectwave) rectwave;
  [%expect {|
    Uniform [2.00, 6.00] -> 4.00
    RectWave [amp=6.00, period=1.00, pulse_length=0.50] -> 0.25
    |}]
