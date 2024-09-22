let () =
  let open Lib.Serial in
  let open Lwt.Infix in
  let serial_conn = make { baud = 115200; port = "/dev/cu.usbmodem2102" } in
  let serial_conn' = serial_conn >>= fun sc -> write_line sc "1" in
  let _ = Lwt_main.run serial_conn' in
  ()
