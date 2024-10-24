let usage_msg =
  "\n\
  \ Usage:\n\
  \ getting [-allow-select-backend] [-ignore-fd-limit] [-no-tls] \
   [-serial-debug] [-rect-wave] [-l <log-dir>] [-p <serial-port>] [-h \
   <host-file>] [-i <interval>] <uri> \n\n\
  \ Example:\n\
  \ getting https://serving.local\n\n\
  \ Options:"

let allow_select = ref false
let ignore_fd_limit = ref false
let tls = ref true
let include_debug = ref false
let rect_wave = ref false
let serial_port = ref "/dev/stdout"
let log_dir = ref ""
let host_file = ref ""
let request_interval = ref 1.
let host = ref ""

let speclist =
  [
    ( "-allow-select-backend",
      Arg.Set allow_select,
      ": Allow the program to run with Lwt compiled with the 'select' backend.\n"
    );
    ( "-ignore-fd-limit",
      Arg.Set ignore_fd_limit,
      ": Ignore the Unix file descriptor ulimit set in the calling process. \
       When not ignored, limits <= 20,000 will raise an exception.\n" );
    ( "-no-tls",
      Arg.Bool (fun no_tls -> tls := Bool.not no_tls),
      ": Connect without TLS using the http protocol, the default is to use \
       https with TLS.\n" );
    ( "-serial-debug",
      Arg.Set include_debug,
      ": Include debug information over the serial connection, by default only \
       '0's and '1's are returned to maximise data transfer rate.\n" );
    ( "-rect-wave",
      Arg.Set rect_wave,
      ": Apply a request load with a request rate following a rectangular wave \
       (short pulses at the specified request rate seperated by short delays. \
       In the absence of this flag a load with a constant request rate is \
       applied.\n" );
    ( "-l",
      Arg.Set_string log_dir,
      ": Optionally write a log file in the specified directory with \
       information about the success or failure of each request.\n" );
    ( "-p",
      Arg.Set_string serial_port,
      ": Optionally set serial port to output successful response indicator, \
       defaults to '/dev/stdout'.\n" );
    ( "-h",
      Arg.Set_string host_file,
      ": Optionally include the location of a .yaml file describing a list of \
       hosts for custom DNS resolution.\n" );
    ( "-i",
      Arg.Set_float request_interval,
      ": Optionally set the request interval (delay between requests) in \
       seconds, defaults to 1.0.\n" );
  ]

let serial_debug () = !include_debug
let rectangular_wave () = !rect_wave
let r_interval () = !request_interval
let target_uri () = Uri.of_string !host
let log_path () = if String.length !log_dir == 0 then None else Some !log_dir

let arg_parse () =
  let anon_fun target_host = host := target_host in
  Arg.parse speclist anon_fun usage_msg;
  if String.length !host == 0 then
    failwith
      "The URI of the target must be provided. See --help for usage \
       instructions.";
  let open System_checks in
  if Bool.not !allow_select then select_check ();
  if Bool.not !ignore_fd_limit then fd_limit_check ();
  if String.length !host_file > 0 then Resolver.parse_resolver !host_file
