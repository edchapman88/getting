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

let arg_parse () =
  let open System_checks in
  Arg.parse speclist (fun _ -> ()) usage_msg;
  if Bool.not !allow_select then select_check ();
  if Bool.not !ignore_fd_limit then fd_limit_check ()
