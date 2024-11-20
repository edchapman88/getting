type res = Cohttp.Response.t * Cohttp_lwt.Body.t
(** A [Cohttp] response. *)

type req_failure =
  | FailedToSend of exn  (**e.g. The connection was refused. *)
  | FailedAfterSend of exn

val string_of_req_failure : req_failure -> string
(** Returns a string representation of [req_failure]. For both [FailedToSend] and [FailedAfterSend] the inner exception is printed, prepended by the name of the constructor. E.g. ["Request FailedToSend with: <string repr of inner exn>"]. *)

type req_inner = (res, req_failure) result
(** [req_inner] is the type that a [Request.t] resolves to. *)

type t = req_inner Lwt.t
(** A request is a promise. The promise is immediately fulfilled with [Error of FailedToSend] if the request failed to send. Otherwise the request will resolve to either [Error of FailedAfterSend] or [Ok of res]. It is guranteed that [Request.t] will resolve fulfilled. *)

type params = {
  src : Uri.t;
  dest : Uri.t;
}
(** Configurable request parameters. *)

val code_of_res : res -> int Lwt.t
(** Convenience function to return the status code of a response as a promised [int]. *)

val body_of_res : res -> string Lwt.t
(** Convenience function to return a response body as a promised human readable string. *)

val meta_of_res : res -> string Lwt.t
(** Convenience function to return response meta data as a human readable string. See [s_meta_of_res] for a conversion to a structured S expression. *)

val s_meta_of_res : res -> Sexplib0.Sexp.t Lwt.t
(** Same as [meta_of_res], but return early with a structured S expression. *)

val send : ?headers:(string * string) list -> params -> t
(** [send params] sends a request with parameters [params], returning a [Request.t], which is a promise that is guranteed to resolve fulfilled to [req_inner]. Request failures are represented by the [Error of req_failur] varient of [req_inner]. Additional http headers are optionally attached to the request by passing a [(string * string) list]. *)
