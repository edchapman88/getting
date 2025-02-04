(** Convenience function to map an ['a lwt.t] to an [('a, string) result lwt.t]. Rejected promises are mapped to [Error]; fulfilled promises to [Ok]. *)
let result_lwt_of_lwt promise =
  Lwt.try_bind
    (fun () -> promise)
    (fun inner -> inner |> Result.ok |> Lwt.return)
    (fun e -> e |> Printexc.to_string |> Result.error |> Lwt.return)
