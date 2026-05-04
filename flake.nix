{
  description = "Run Tracker";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, ... }:
        let
          ruby = pkgs.ruby_3_4;
          gems = pkgs.bundlerEnv {
            name = "run-tracker";
            inherit ruby;
            gemdir = ./.;
          };
        in
        {
          devShells.default = pkgs.mkShell {
            RACK_ENV = "development";

            packages = [
              pkgs.bundix
              gems
              gems.wrappedRuby
            ];
          };
        };
    };
}
