type res = Cohttp.Response.t * Cohttp_lwt.Body.t
(** A [Cohttp] response. *)

(** A request is either [Sent] and of type [res Lwt.t] (which is a promised response), or [Failed] of type [exn] if the request failed to send (e.g. The connection was refused). *)
type t =
  | Sent of res Lwt.t
  | Failed of exn

type params = {
  src : Uri.t;
  dest : Uri.t;
}
(** Configurable request parameters. *)

val code_of_res : res -> int
(** Convenience function to return the status code of a response as an [int]. *)

val body_of_res : res -> string Lwt.t
(** Convenience function to return a response body as a promised human readable string. *)

val meta_of_res : res -> string
(** Convenience function to return response meta data as a human readable string. Note conversion to an S expression with [s_meta_of_res] may be more appropriate for some use cases. *)

val s_meta_of_res : res -> Sexplib0.Sexp.t
(** Same as [meta_of_res], but return early with a structured S expression. *)

val send : params -> t
(** [send req] sends the request [req], returning an [Lwt.t] promise of a response [res]. *)
