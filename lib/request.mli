type t = {
  src : Uri.t;
  dest : Uri.t;
}
(** Parameterised request, specifying only the properties of the request that are of interest. *)

type res = Cohttp.Response.t * Cohttp_lwt.Body.t
(** A [Cohttp] response. *)

val body_of_res : res -> string Lwt.t
(** Convenience function to return a response body as a promised human readable string. *)

val meta_of_res : res -> string
(** Convenience function to return response meta data as a human readable string. Note conversion to an S expression with [s_meta_of_res] may be more appropriate for some use cases. *)

val s_meta_of_res : res -> Sexplib0.Sexp.t
(** Same as [meta_of_res], but return early with a structured S expression. *)

val send : t -> res Lwt.t
(** [send req] sends the request [req], returning an [Lwt.t] promise of a response [res]. *)
