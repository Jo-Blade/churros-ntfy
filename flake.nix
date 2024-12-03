{
  description = "An ocaml bridge that relay churros web push notifications to ntfy.sh.";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      # Generate a user-friendly version number.
      version = "v1";

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ (import ./overlay.nix) ]; });

    in
    {

      # enable nix fmt
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {

          churros-ntfy = pkgs.ocamlPackages.buildDunePackage {
            inherit version;
            pname = "churros_ntfy";
            # Tell nix that the source of the content is in the root
            src = ./.;

            nativeBuildInputs = [ pkgs.ocamlPackages.menhir ];
            buildInputs = with pkgs.ocamlPackages; [
              ppx_deriving
              ppxlib
              lwt_ppx
              menhirLib
              sedlex
              cohttp-lwt-unix
              websocket-lwt-unix
              timedesc
              mirage-crypto-rng-lwt
            ];
          };
        });

      # Add dependencies that are only needed for development
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ nixd ocaml dune_3 ocamlformat ocamlPackages.ocaml-lsp ocamlPackages.utop ]
              ++ (with self.packages.${system}.churros-ntfy; nativeBuildInputs ++ buildInputs);
          };
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.churros-ntfy);
    };
}
