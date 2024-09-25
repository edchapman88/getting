let select_check () =
  let open Lwt_sys in
  if Bool.not (have `libev) then
    failwith
      "`Lwt` is not compiled with `libev` as a backend. This is not \
       recommended (see README.md for details). Ignore this check with \
       `-allow-select-backend`."

let fd_limit_check () =
  let run_check =
    Sys.command "if [[ $(ulimit -n -S) -lt 20000 ]]; then\n exit 1\n fi"
  in
  match run_check with
  | 0 -> ()
  | _ ->
      failwith
        "The max Unix file descriptors limit for the calling process is < \
         40,000 which is not recommended (see README.md for details). Ignore \
         this check with `-ignore-fd-limit`."
