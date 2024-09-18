type score =
  | Success
  | Fail

let write_serial ?(baud = 115200) port =
  let module Serial0 = Serial.Make (struct
    let port = port
    let baud_rate = baud
  end) in
  Serial0.write_line

let write_score ?(baud = 115200) port score =
  let repr =
    match score with
    | Success -> "1"
    | Fail -> "0"
  in
  write_serial ~baud port repr
