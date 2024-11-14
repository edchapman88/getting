open Domainslib

type 'a handler = 'a -> unit Lwt.t
type 'a t = 'a handler

let of_handler (handler : 'a handler) = handler

let rec async_loop chan (handler : 'a -> unit Lwt.t) =
  let open Lwt.Infix in
  match Chan.recv chan with
  | None -> Lwt.return ()
  | Some promise -> promise >>= handler >>= fun () -> async_loop chan handler

let produce chan xs =
  let seq_map x = x |> Option.some |> Chan.send chan in
  Seq.iter seq_map xs;
  Chan.send chan None

let process pipe xs =
  let main_chan = Chan.make_unbounded () in
  let producer = Domain.spawn (fun () -> produce main_chan xs) in
  let _consumer = Lwt_main.run (async_loop main_chan pipe) in
  Domain.join producer
