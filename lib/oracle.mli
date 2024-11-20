(** Parsing and scoring [Request.t] according to a criteria specified by the module implementer. *)

(** A binary score for the success or failure of a request. *)
type score =
  | Success
  | Fail of string

val string_of_score : ?debug:bool -> score -> string
(** Serialiser for [score]. *)

val score_of_req_inner : Request.req_inner -> score Lwt.t
(** Score a [Request.req_inner], returning a promise to facilitate asynchronous parsing of the request (e.g. with [Request.body_of_res] or [Request.code_of_res]). *)
