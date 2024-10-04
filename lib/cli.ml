let usage_msg =
  "\n\
  \ getting [-allow-select-backend] [-ignore-fd-limit] [-no-tls] [-p <port>] \
   [-r <rate>] <uri> \n\n\
  \ Example: getting https://serving.local\n"

let allow_select = ref false
let ignore_fd_limit = ref false
let tls = ref true
let serial_port = ref "/dev/stdout"
let request_rate = ref 3.
let host = ref ""

let speclist =
  [
    ( "-allow-select-backend",
      Arg.Set allow_select,
      "Allow the program to run with Lwt compiled with the 'select' backend" );
    ( "-ignore-fd-limit",
      Arg.Set ignore_fd_limit,
      "Ignore the Unix file descriptor ulimit set in the calling process. When \
       not ignored, limits <= 20,000 will raise an exception" );
    ( "-no-tls",
      Arg.Bool (fun no_tls -> tls := Bool.not no_tls),
      "Connect without TLS using the http protocol, the default is to use \
       https with TLS." );
    ( "-p",
      Arg.Set_string serial_port,
      "Optionally set serial port to output successful response indicator, \
       defaults to '/dev/stdout'" );
    ( "-r",
      Arg.Set_float request_rate,
      "Optionally set the request rate in requests-per-second (rps), defaults \
       to 3. rps." );
  ]

let rps () = !request_rate
let target_uri () = Uri.of_string !host

let arg_parse () =
  let open System_checks in
  let anon_fun target_host = host := target_host in
  Arg.parse speclist anon_fun usage_msg;
  print_endline (Uri.to_string (target_uri ()));
  if Bool.not !allow_select then select_check ();
  if Bool.not !ignore_fd_limit then fd_limit_check ()
