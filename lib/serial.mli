(** A stateful module, initialised with [init ()]. The serial port address is configured (optionally at runtime) in the [Cli] module. A serial connection of type [t] is maintained as mutable state and written to by calls to [write_line] or [write_score]. **)

type t
(** A serial connection. *)

type config = {
  baud : int;  (** Baude rate. *)
  port : string;
      (** File system address of the serial device, e.g. "/dev/tty0". *)
}
(** Configuration for a connection of type [Serial.t]. *)

val init : unit -> unit
(** [init ()] initialises the module, using the serial port address configured at run-time by the [Cli] module. *)

val write_line : string -> unit Lwt.t
(** [write_line message] writes [message] to the configured serial connection ([init ()] must be called first). If a the write fails becuase the connection could not be established, the connection setup is re-tried. If a write fails because a successfully estabilshed connection is dropped, then the function fails silently and cannont re-estabilish the connection. (For the current implementation, this is because [Lwt_io.fprint out_chan] returns a fulfilled promise if [out_chan] is associated with a hanging file descriptor.) *)

val write_of_score : Oracle.score Lwt.t -> unit Lwt.t
(** Convenience function to write an [Oracle.score] to a serial connection. *)
