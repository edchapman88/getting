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

# Microprobe
This repository contains a helper tool to be used as a system probe: parsing and analysing the serial output from the web client in real-time on a microcontroller. The tool is designed specifically for the [BBC microbit](https://microbit.org/), but the source code could be used as inspiration for alternatives.

## Usage
1. Plug the microbit in to a USB port, it will by recognised as a USB storage device.
2. Flash the `.hex` file onto a microbit by copying the file onto the device.
3. Plug the microbit into the device running the web client.
4. Establish the file system path to the microbit device (e.g. `ls /dev/tty.*` or `ls /dev/cu.*`).
5. Pass the file system path to the web client CLI (e.g. with `-p /dev/tty.ACM0`).
6. The microbit LED display is used to show whether `0`s or `1`s are emitted by the web client on the serial port (`0`, request failed, LED off; `1`, request succeeded, LED on).
7. It takes some time (around 10s to 3 minutes depending on the configuration of the probe and the web client request rate) to fill up the evaluation buffer on the microbit, after which there will be a high pitched buzz.
7. Thereafter, if **either**:
    - the proportion of requests that are successful is < some constant `gamma`
    **or:
    - the rate of successful requests is < some constant rate `lambda` 
    then a lower pitched buzzer will sound on the microbit.
8. `gamma` and `lambda` are configured in the source code for the tool, discussed below.

## Configuration and Compiling
`./microprobe.js` is source code that is compiled to the `./microbit_show_serial.hex` file. The source code depends on libraries made available by Microsoft. It is most easily compiling by pasting the code into a new project on the Microsoft Makecode website, [makecode.microbit.org](https://makecode.microbit.org/), after which a `.hex` file can be downloaded or flashed directly onto a microbit that is plugged in.

## Example Scenario
- Web server successfully responding to 80% of the incoming requests, on average.
- Probe configured with `gamma = 0.9` and `lambda = 10`.

Two possible scenarios:
1. **Low Load - judged against the `gamma` criteria**
    - Web client making 5 Queries Per Second (QPS).
    - It takes two minutes to initialise the probe.
    - Neither criteria are met, so the buzzer is on.
    - If the server would instead have to correctly respond to 95% of incoming requests to satisfy the `gamma` criteria and the buzzer would not sound.
2. **High Load - judged against the `lambda` criteria**
    - Web client making 20 Queries Per Second (QPS).
    - It takes 30 seconds to initialise the probe.
    - The `lambda` criteria is met, so the buzzer does not sound.
    - On average the server responds correctly at a rate of 16 Responses Per Second (RPS) (0.8 * 20), and this is above the `lambda` criteria of 10 (RPS).
    - Even if the server only responds to just over 50% of the requests in this high load scenario, the `lambda` criteria is met.

# TLS and Sources for X509 Certificates
The `ca-certs` package is responsible for TLS authentication. [`trust_anchors()`](https://ocaml.org/p/ca-certs/latest/doc/Ca_certs/index.html#val-trust_anchors) "detects the root CAs (trust anchors) in the operating system's trust store". In the case of MacOS, **only the CAs in the 'system roots' keychain are picked up**. This prohibits using the 'login' keychain to add custom CAs to the set of CAs trusted by `ca-certs`. There is an open [PR](https://github.com/mirage/ca-certs/pull/28) addressing this issue. Until merged, the work around is to point the `SSL_CERT_FILE` to a .pem file (a copy of the file that probably already exists at `/etc/ssl/cert.pem`) that includes the addition custom CAs. E.g. in `~/.zshrc`, `export SSL_CERT_FILE=/etc/ssl/cert_extended.pem`.
