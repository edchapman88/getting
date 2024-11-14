open Lib

let out_of_order =
  let open Lwt_unix in
  let open Lwt.Infix in
  let delays = [ 5; 1; 3; 1 ] in
  let sleeps =
    List.map
      (fun delay -> sleep (float_of_int delay) >|= fun () -> delay)
      delays
  in
  List.to_seq sleeps

let handle_to_list l payload =
  l := payload :: !l;
  Lwt.return ()

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
  Pipe.process pipe out_of_order;
  printer (List.rev !record);
  [%expect {| |}]
