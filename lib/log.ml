let file_of_path (path : string) =
  let path = if String.ends_with ~suffix:"/" path then path else path ^ "/" in
  (try (* Read and write for all users.*)
       Unix.mkdir path 0o777
   with Unix.Unix_error (Unix.EEXIST, _, _) -> ());
  let open Core.Time_float in
  open_out (path ^ to_filename_string ~zone:Zone.utc (now ()) ^ ".txt")

let oc = ref None
let init_oc path = oc := Some (file_of_path path)

let rec write_of_score path score =
  match !oc with
  | None ->
      init_oc path;
      write_of_score path score
  | Some chan ->
      let open Core.Time_ns in
      Printf.fprintf chan "[%d] %s%!"
        (to_int_ns_since_epoch (now ()))
        (Oracle.string_of_score ~debug:true score)
