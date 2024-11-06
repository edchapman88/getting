type t
(** A serial connection. *)

type config = {
  baud : int;  (** Baude rate. *)
  port : string;
      (** File system address of the serial device, e.g. "/dev/tty0". *)
}
(** Configuration for a connection of type [Serial.t]. *)

val make : config -> t Lwt.t
(** [make conf] returns a promised [Serial.t] connection, configured by [conf] (of type [config]). *)

val write_line : t -> string -> t Lwt.t
(** [write_line serial message] writes [message] to the connection [serial], asynchronously, returning the promise of a new connection ([t Lwt.t]). If a write fails, an attempt is made to establish a new connection which is returned in place of the old connection. *)

val write_of_score : t -> Oracle.score Lwt.t -> t Lwt.t
(** Convenience function to write an [Oracle.score] to a serial connection. *)
