(** Parsing and scoring [Request.t] according to a criteria specified by the module implementer. *)

(** A binary score for the success or failure of a request. *)
type score =
  | Success
  | Fail of string

val string_of_score : ?debug:bool -> score -> string
(** Serialiser for [score]. *)

val score_of_req : Request.t -> score Lwt.t
(** Score a [Request.t], returning a promise to facilitate asynchronous parsing of the request (e.g. with [Request.body_of_res] or [Request.code_of_res]). *)
