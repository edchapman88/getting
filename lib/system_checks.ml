(** [select_check()] raises an exception if [Unix.select] is being used as a back end for [Lwt]. The preferred alternative is to have [Lwt] compilied with [libev] as a backend. Refer to the {i Lwt Scheduler} section in the {{:https://ocsigen.org/lwt/latest/manual/manual} lwt docs}. Pass the [-allow-select-backend] flag to the cli to suppress this check. *)
let select_check () =
  let open Lwt_sys in
  if Bool.not (have `libev) then
    failwith
      "`Lwt` is not compiled with `libev` as a backend. This is not \
       recommended (see README.md for details). Ignore this check with \
       `-allow-select-backend`."

(** [fd_limit_check()] raises an exception if the calling process has not been configured with a maximum unix file descriptor limit > 20,000. The default can be as low as 256 which will cause [Unix.EMFILE] exceptions to be raised with high request rates. The limit can be increases for a given process by calling [ulimit -n <new limit>]. Pass [-ignore-fd-limit] to the cli to suppress this check. *)
let fd_limit_check () =
  let run_check =
    Sys.command "if [[ $(ulimit -n -S) -lt 20000 ]]; then\n exit 1\n fi"
  in
  match run_check with
  | 0 -> ()
  | _ ->
      failwith
        "The max Unix file descriptors limit for the calling process is < \
         20,000 which is not recommended (see README.md for details). Ignore \
         this check with `-ignore-fd-limit`."
