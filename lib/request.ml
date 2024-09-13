type t = {
  src : Uri.t;
  dest : Uri.t;
}

type res = Cohttp.Response.t * Cohttp_lwt.Body.t

let send req =
  let open Cohttp_lwt_unix in
  Client.get req.dest
