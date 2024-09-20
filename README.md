# Installation
This project depends on `Lwt`, which is a library to handle I/O operations with asynchronous promises. `Lwt` has two backend implementations, `libev` and `select`. `select` is limited to supporting only 1024 file descriptors which is a problem for high throughput servers or clients. With a high load, a `Unix.EINVAL` exception is raised, referencing `Unix.select` as the function responsible for the failure.

## Installing and enbaling `libev`.
As described in the 'Lwt scheduler' section of the [Lwt manual](https://ocsigen.org/lwt/latest/manual/manual), there are two prerequisites to meet such that `Lwt` will compile with the non-default (but more performant) `libev` backend:
1. Install `libev` on your system with one of:
    - `brew install libev`
    - `apt-get install libev-dev`
    - The NixPkg [`libev`](https://github.com/NixOS/nixpkgs/tree/nixos-24.05/pkgs/development/libraries/libev)
2. Install `conf-libev` in your opam switch (or add to `dune-project` dependencies, rebuild and re-install dependencies with `opam install --deps-only .`).

### Troubleshooting
You can test the newly compiled `Lwt` with:
```
let () =
  let open Lwt_sys in
  print_endline (string_of_bool (have `libev))
```
If this returns false, `Lwt` may not have recognised `libev`. Try setting the following environment variables and then re-installing `Lwt`:
```
export C_INCLUDE_PATH=<path to where libev installed>
export LIBRARY_PATH=<path to where libev installed>
```

E.g. for `brew` installed `libev` the path would be something like `/opt/homebrew/Cellar`

# High server or client loads
If serving or sending a high volume of requests there are two errors that are likely to occur. The first is discussed above, and is address by ensuring the `libev` backend is being used by `Lwt`. The second is due to the configuration of the file descriptor limit set for the linux user executing the program. Running `ulimit -a` in a shell will show all of the limits for that user. `ulimit -n` shows only the file descriptors limit of interest. The limit can be set high with `ulimit -n 20000`.

The exception caused by a high load when the file descriptor limit is too low is of type `Unix.ENFILE`, for 'Too many open files in the system'.

The full set of `Unix` exception types can be found [here](https://ocaml.org/manual/5.2/api/Unix.html).

