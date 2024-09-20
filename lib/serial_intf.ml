(** Configuration for opening a Serial connection *)
module type Serial_config_type = sig
  val port : string
  (** Location of serial port to be opened *)

  val baud_rate : int
  (** Connection Baud rate *)
end

(** Main module *)
module type Serial_type = sig
  val port : string
  (** Location of opened serial port *)

  (** Submodule for values that should not be used externally *)
  module Private : sig
    val fd : Lwt_unix.file_descr
    (** File descriptor for the opened serial port *)

    val in_channel : Lwt_io.input Lwt_io.channel
    (** Channel for reading lines from the device *)

    val out_channel : Lwt_io.output Lwt_io.channel
    (** Channel for writing lines to the device *)
  end

  val set_baud_rate : int -> unit Lwt.t
  val read_line : unit -> string Lwt.t
  val write_line : string -> unit Lwt.t

  val wait_for_line : string -> unit Lwt.t
  (** Wait for the specified string to be received.
	{b Warning:} currently waits indefinitely. *)

  val io_loop : string option -> unit Lwt.t
  (** Open two-way communication between std(i/o) and the Serial device.

	Supply [Some "$KEYWORD"] to exit the loop upon entering the specified
	line in stdin. Supplying [None] causes this function to loop indefinitely. *)
end
