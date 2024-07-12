{ lib
, buildDunePackage
, fetchFromGitHub
, cohttp-lwt-unix
, lwt_log
}:

rec {
  version = "2.16";

  src = fetchFromGitHub {
    owner = "vbmithr";
    repo = "ocaml-websocket";
    rev = "${version}";
    sha256 = "sha256-AdL5ze5CcSrkAhQlOnKkqCUk76sJagfkH3IB8CBR6wk=";
  };

  minimalOCamlVersion = "4.06";

  license = lib.licenses.isc;
  maintainers = [ ];

  websocket = buildDunePackage rec {
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

  websocket-lwt-unix = buildDunePackage rec {
    pname = "websocket-lwt-unix";

    inherit version;
    inherit src;
    inherit minimalOCamlVersion;

    propagatedBuildInputs = [ websocket cohttp-lwt-unix lwt_log ];

    doCheck = true;

    meta = {
      description = "Websocket library for OCaml";
      inherit license;
      inherit maintainers;
      homepage = "https://ocaml.org/p/websocket-lwt-unix/latest";
    };
  };
}
