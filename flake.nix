{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];
      perSystem =
        {
          lib,
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          exe_name = "hello_world";
        in
        {
          packages = {
            default = pkgs.stdenv.mkDerivation {
              pname = exe_name;
              version = "0.0.1";

              src = ./.;

              buildInputs = [
                pkgs.libgcc
                pkgs.glibc
                pkgs.glibc.static
                pkgs.cosmopolitan
                pkgs.cosmocc
                pkgs.binutils # bin/objcopy
              ];

              phases = [
                "buildPhase"
                "installPhase"
              ];

              buildPhase = ''
                # gcc builds for comparison
                gcc -o ${exe_name}-gcc-dynamic $src/main.c
                gcc -static -o ${exe_name}-gcc-static $src/main.c

                cosmocc -o ${exe_name}.exe $src/main.c
                objcopy -S -O binary ${exe_name}.exe ${exe_name}.exe
                chmod +x ${exe_name}.exe
              '';

              installPhase = ''
                mkdir -p $out
                cp ${exe_name}* $out
              '';

              meta = {
                description = "";
                license = pkgs.lib.licenses.mit;
                maintainers = with pkgs.lib.maintainers; [ ];
              };
            };
          };

          devShells = {
            default = pkgs.mkShell {
              packages = config.packages.default.buildInputs;
              env = {
                NIX_CONFIG = "experimental-features = nix-command flakes";
              };
            };
          };
        };
    };
}
