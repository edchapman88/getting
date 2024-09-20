(* hilbert = 169.254.220.46 *)
let usage_msg =
  "getting [-allow-select-backend] [-ignore-fd-limit] -p /dev/ttyACM0"

let allow_select = ref false
let ignore_fd_limit = ref false
let serial_port = ref "/dev/stdout"

let speclist =
  [
    ( "-allow-select-backend",
      Arg.Set allow_select,
      "Allow the program to run with Lwt compiled with the 'select' backend" );
    ( "-ignore-fd-limit",
      Arg.Set ignore_fd_limit,
      "Ignore the Unix file descriptor ulimit set in the calling process. When \
       not ignored, limits <= 40,000 will raise an exception" );
    ( "-p",
      Arg.Set_string serial_port,
      "Set serial port to output successful response indicator, defaults to \
       '/dev/stdout'" );
  ]

let select_check () =
  let open Lwt_sys in
  if Bool.not (have `libev) then
    failwith
      "`Lwt` is not compiled with `libev` as a backend. This is not \
       recommended (see README.md for details). Ignore this check with \
       `-allow-select-backend`."

let fd_limit_check () =
  let run_check =
    Sys.command "if [[ $(ulimit -n -S) -lt 40000 ]]; then\n exit 1\n fi"
  in
  match run_check with
  | 0 -> ()
  | _ ->
      failwith
        "The max Unix file descriptors limit for the calling process is < \
         40,000 which is not recommended (see README.md for details). Ignore \
         this check with `-ignore-fd-limit`."

let make_load =
  let open Lib.Load in
  (*of_dest ~distribution:(Point 0.01) (Uri.of_string "http://169.254.220.46:80")*)
  of_dest ~distribution:(Point 1.) (Uri.of_string "http://127.0.0.1:3000")

let handle_req (serial_mod : (module Lib.Serial_intf.Serial_type)) req =
  let open Lib in
  let open Lwt.Infix in
  (* Unpack the module. *)
  let module Serial' = (val serial_mod : Serial_intf.Serial_type) in
  let score =
    match req with
    | Request.Failed e -> Lwt.return (Oracle.Fail (Printexc.to_string e))
    | Request.Sent res ->
        Lwt.try_bind
          (* Function to bind. *)
            (fun () -> res)
          (* On promise fulfilled. *)
            (fun res ->
            let code = Request.code_of_res res in
            match code with
            | 200 -> Lwt.return Oracle.Success
            | _ -> Lwt.return (Oracle.Fail (string_of_int code)))
          (* On promise rejected. *)
            (fun e -> Lwt.return (Oracle.Fail (Printexc.to_string e)))
  in
  score >|= Oracle.string_of_score >>= Serial'.write_line

let rec listen chan serial_mod =
  let open Domainslib in
  let open Lwt.Infix in
  let promised_write = Chan.recv chan |> handle_req serial_mod in
  promised_write >>= fun () -> listen chan serial_mod

let () =
  Arg.parse speclist (fun _ -> ()) usage_msg;
  if Bool.not !allow_select then select_check ();
  if Bool.not !ignore_fd_limit then fd_limit_check ();

  let module Serial' = Lib.Serial.Make (struct
    let port = !serial_port
    let baud_rate = 115200
  end) in
  (* 'Pack' the module as a first-class module. *)
  let serial_mod = (module Serial' : Lib.Serial_intf.Serial_type) in

  let load = make_load in
  let open Domainslib in
  (* Create a new OS thread channel to pass messages between this OS thread and any others spawned with [Domain.spawn]. *)
  let main_chan = Chan.make_unbounded () in

  (* Spawn a new OS thread running a synchronous function that makes requests at the required intervals. *)
  let requester = Domain.spawn (fun _ -> Seq.iter (Chan.send main_chan) load) in

  (* Use the main OS thread as an asynchronous runtime, handling promised responses that are received over the channel from the [requester] OS thread. *)
  let _ = Lwt_main.run (listen main_chan serial_mod) in

  (* Await the termination of the requester thread (which will not terminate for never-ending request loads (that are infitite sequences). *)
  Domain.join requester
