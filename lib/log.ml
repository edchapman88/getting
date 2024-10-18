let oc = ref None
let init_oc path = oc := Some (open_out path)

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
