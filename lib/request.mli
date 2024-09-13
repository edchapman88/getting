type t = {
  src : Uri.t;
  dest : Uri.t;
}
(** Parameterised request, specifying only the properties of the request that are of interest. *)

type res = Cohttp.Response.t * Cohttp_lwt.Body.t
(** A [Cohttp] response. *)

val send : t -> res Lwt.t
(** [send req] sends the request [req], returning an [Lwt.t] promise of a response [res]. *)
