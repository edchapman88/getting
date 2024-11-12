open Lib

let%expect_test "load resolver from yaml file" =
  let path = "./resolver_hosts.yaml" in
  let expected_uri = Uri.of_string "https://serving.local" in
  Resolver.init_from_yaml path;
  let service_promise =
    Resolver.get () |> Option.get |> Resolver_lwt.resolve_uri ~uri:expected_uri
  in
  Lwt_main.run service_promise
  |> Conduit.sexp_of_endp |> Sexplib0.Sexp.to_string |> print_endline;
  [%expect {| (TLS(serving.local(TCP(169.254.220.46 443)))) |}]
