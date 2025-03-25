# [getting](https://edchapman88.github.io/getting/) : HTTP Loading for the [R<sup>3</sup>ACE](https://github.com/edchapman88/r3ace) Project
**Dispatch _timely_ HTTP loads.** `getting` uses two system threads to:
1. **Synchronously dispatch requests** at time intervals that follow a specifies distribution, immediately handing off the pending (promised) responses to the other thread (via a "single-producer, single-consumer (SPSC) channel).
2. An **asynchronous runtime**, reading promised HTTP responses from the SPSC channel and **chasing the collection of promises to fulfillment**.

Part of the [**R<sup>3</sup>ACE**](https://github.com/edchapman88/r3ace) project: _Replicable_ and _Reproducible_ _Real-World_ Autonomous Cyber Environments, `getting` is used to apply an HTTP load to a web server and broadcast a stream of signals to a system interface (either Serial or UDP), indicating when OK (status code = 200) responses have been received from the web server.

## Find Out More
- Get started **training and evaluating agents** in _Replicable_ and _Reproducible Real-World_ Autonomous Cyber Environments with [**R<sup>3</sup>ACE**](https://github.com/edchapman88/r3ace).
- I know about R<sup>3</sup>ACE, **take me to the [docs](https://edchapman88.github.io/getting/) website for `getting`**.
