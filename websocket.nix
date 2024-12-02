{ lib
, buildDunePackage
, fetchFromGitHub
, cohttp-lwt-unix
, lwt_log
, sexplib
}:

rec {
  version = "2.17";

  src = fetchFromGitHub {
    owner = "vbmithr";
    repo = "ocaml-websocket";
    rev = "${version}";
    sha256 = "sha256-LYSnmKbfeCZNUpAIlu0Gc+5KRVDTmGDcryepr5DLtrc=";
  };

  minimalOCamlVersion = "4.06";

  license = lib.licenses.isc;
  maintainers = [ ];

  websocket = buildDunePackage {
    pname = "websocket";

    inherit version;
    inherit src;
    inherit minimalOCamlVersion;

    propagatedBuildInputs = [ cohttp-lwt-unix ];

    doCheck = true;

    meta = {
      description = "Websocket library for OCaml";
      inherit license;
      inherit maintainers;
      homepage = "https://ocaml.org/p/websocket/latest";
    };
  };

  websocket-lwt-unix = buildDunePackage {
    pname = "websocket-lwt-unix";

    inherit version;
    inherit src;
    inherit minimalOCamlVersion;

    propagatedBuildInputs = [ websocket cohttp-lwt-unix lwt_log sexplib ];

    doCheck = true;

    meta = {
      description = "Websocket library for OCaml";
      inherit license;
      inherit maintainers;
      homepage = "https://ocaml.org/p/websocket-lwt-unix/latest";
    };
  };
}
