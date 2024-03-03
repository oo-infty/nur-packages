{
  description = "My personal NUR repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }@inputs: let
    systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "armv6l-linux" "armv7l-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    legacyPackages = forAllSystems (system: import ./default.nix {
      pkgs = import nixpkgs { inherit system; };
    });
    packages = forAllSystems (system: nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) self.legacyPackages.${system});
    devShells = forAllSystems (system: {
      default = let
        pkgs = import nixpkgs { inherit system; };
      in
        pkgs.mkShell {
          packages = with pkgs; [
            nix-index
          ];
        };
    });
  };
}
