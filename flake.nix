{
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "opam-nix/nixpkgs";
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs }@inputs:
    # Don't forget to put the package name instead of `throw':
    let package = "getting";
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        scope =
          on.buildDuneProject { pkgs = pkgs.pkgsStatic; } package ./. { ocaml-base-compiler = "*"; };
        overlay = final: prev:
          {
              postInstall = ''
                mkdir -p "$OCAMLFIND_DESTDIR/stublibs"
                ln -s "$OCAMLFIND_DESTDIR"/${final.pname}/dll*.so "$OCAMLFIND_DESTDIR"/stublibs/
              '';

          };
      in {
        legacyPackages = scope.overrideScope' overlay;

        packages.default = self.legacyPackages.${system}.${package};
      });
}
