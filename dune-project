(lang dune 3.10)

(name churros_ntfy)

(using menhir 2.1)

(generate_opam_files true)

(source
  (github inp-net/churros-ntfy)
)

(authors "INP-net")

(maintainers "Theo Bessel" "Teo Pisenti")

(license LICENSE)

(documentation https://url/to/documentation)

(package
  (name churros_ntfy)
  (synopsis "A program to relay churros notification to ntfy.sh compatible server.")
  (description "This program fetches churros API notifications and relay them to a ntfy.sh endpoint (compatible UnifiedPush open source server).")
  (depends (ocaml (>= 5.1)) dune)
  (tags
    (churros ntfy unifiedpush webpush)
  )
)
