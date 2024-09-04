(lang dune 3.16)

(name getting)

(generate_opam_files true)

(source
 (github edchapman88/getting))

(authors "Ed Chapman")

(maintainers "Ed Chapman")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name getting)
 (synopsis "Simulate an HTTP(S) load.")
 (description "A longer description")
 (depends
   ocaml
   dune
   cohttp
   cohttp-lwt-unix
   tls
   tls-lwt)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
