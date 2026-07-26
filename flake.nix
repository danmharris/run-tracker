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

            # Shared use for devShell only. DO NOT use in production
            SECRET_KEY = "76f1f55c927976960b98e01e42bad136f9dea46b8f9428657d247154f3339f6b";
            ADMIN_PASSWORD = "test123";

            packages = [
              pkgs.bundix
              gems
              gems.wrappedRuby
              pkgs.sqlite
            ];
          };
        };
    };
}
