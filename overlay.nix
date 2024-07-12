# overlay.nix
final: prev:
{
  ocamlPackages = prev.ocamlPackages.overrideScope (final-ocaml: prev-ocaml:
    let
      websocketPackages = final-ocaml.callPackage ./websocket.nix { };
    in
    {
      websocket = websocketPackages.websocket;
      websocket-lwt-unix = websocketPackages.websocket-lwt-unix;
    });
}
