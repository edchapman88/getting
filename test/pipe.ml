open Lib

let simulated_promises waits =
  let open Lwt.Infix in
  List.map
    (fun wait -> Lwt_unix.sleep (float_of_int wait) >|= fun () -> wait)
    waits

let producer_delays delays_s =
  Delay.of_delays_s (List.map float_of_int delays_s)

let seq_of delays_and_promises =
  List.split delays_and_promises |> fun (ds, ps) ->
  let promises = ref (simulated_promises ps) in
  let mapper () =
    let t = !promises in
    match t with
    | [] -> failwith "unreachable"
    | p :: rest ->
        promises := rest;
        p
  in
  Seq.map mapper (producer_delays ds)

let out_of_order () = seq_of [ (0, 5); (0, 1); (0, 3); (0, 2) ]
let blocking_channel () = seq_of [ (0, 3); (0, 1); (0, 2); (4, 1) ]

let handle_to_list l promise =
  let open Lwt.Infix in
  promise >|= fun p -> l := p :: !l

let printer l =
  let rec aux n =
    if n > 0 then (
      print_string "@";
      aux (n - 1))
  in
  List.iter
    (fun n ->
      aux n;
      print_string "\n")
    l

let%expect_test "pipe a sequence of promises that resolve out-of-order" =
  let record = ref [] in
  let pipe = Pipe.of_handler (handle_to_list record) in
  Pipe.process pipe (out_of_order ());
  printer (List.rev !record);
  [%expect {|
    @
    @@
    @@@
    @@@@@
    |}]

(* Pipe a sequence of promises that are out of order, immediately followed by delay in the producer thread. The expected behaviour is that the async consumer does not block on the empty channel, and handles the out of order promises promptly, in the order of fulfillment. If the consumer blocks while the channel is empty, all of the out of order promises resolve during the block and they are then handled in order of production (due to the list traversal in the [PromiseBag] implementation). *)
let%expect_test "ensure the async consumer does not block on an empty channel" =
  let record = ref [] in
  let pipe = Pipe.of_handler (handle_to_list record) in
  Pipe.process pipe (blocking_channel ());
  printer (List.rev !record);
  [%expect {|
    @
    @
    @@
    @@@
    |}]
