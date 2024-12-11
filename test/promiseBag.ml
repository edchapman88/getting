open Getting

let never_resolving () = Lwt.wait () |> fst

let partially_resolved_bag () =
  let rec insert bag promises =
    match promises with
    | [] -> bag
    | p :: ps ->
        let bag' = PromiseBag.insert bag p in
        insert bag' ps
  in
  insert PromiseBag.empty
    [
      never_resolving ();
      Lwt.return ();
      never_resolving ();
      Lwt.return ();
      Lwt.return ();
    ]

let%expect_test "filter a bag for resolved promises" =
  let resolved, pending =
    PromiseBag.filter_resolved (partially_resolved_bag ())
  in
  let string_of_count bag = bag |> PromiseBag.count |> string_of_int in
  print_endline (string_of_count resolved ^ " resolved promises");
  print_endline (string_of_count pending ^ " pending promises");
  [%expect {|
    3 resolved promises
    2 pending promises
    |}]
