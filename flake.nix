{
  description = "harfbuzz";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    freetype2 = {
      url = "github:bflyblue/freetype2";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, freetype2, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forallSystems =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f (rec {
            inherit system;
            pkgs = nixpkgsFor system;
            haskellPackages = hpkgsFor system pkgs;
          })
        );
      nixpkgsFor = system: import nixpkgs { inherit system; };
      hpkgsFor =
        system: pkgs:
        pkgs.haskell.packages.ghc912.override {
          overrides = self: super: {
            freetype2 = pkgs.haskell.lib.dontCheck (self.callCabal2nix "freetype2" freetype2 { });
            storable-offset = pkgs.haskell.lib.doJailbreak (pkgs.haskell.lib.unmarkBroken super.storable-offset);
            harfbuzz = self.callCabal2nix "harfbuzz" ./. { };
          };
        };
    in
    {
      packages = forallSystems (
        {
          system,
          pkgs,
          haskellPackages,
        }:
        {
          harfbuzz = haskellPackages.harfbuzz;
          default = self.packages.${system}.harfbuzz;
        }
      );
      devShells = forallSystems (
        {
          system,
          pkgs,
          haskellPackages,
        }:
        {
          harfbuzz = haskellPackages.shellFor {
            packages = p: [ self.packages.${system}.harfbuzz ];
            buildInputs = with haskellPackages; [
              cabal-install
            ];
          };
          default = self.devShells.${system}.harfbuzz;
        }
      );
    };
}
