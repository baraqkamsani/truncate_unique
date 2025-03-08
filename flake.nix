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
          devShells.default = pkgs.mkShell {
            packages = config.packages.default.buildInputs ++ [
              pkgs.file
            ];
            env.NIX_CONFIG = "experimental-features = nix-command flakes";
          };

          packages.default = pkgs.stdenv.mkDerivation {
            src = ./.;
            pname = exe_name;
            version = "0.0.1";
            buildInputs = [
              pkgs.zig
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

              cosmocc -o ${exe_name}-cosmo.exe $src/main.c
              objcopy -S -O binary ${exe_name}-cosmo.exe ${exe_name}-cosmo.exe
              chmod +x ${exe_name}-cosmo.exe

              export HOME=$(pwd)
              cp -v $src/build.zig .
              cp -v $src/main.zig .
              ls -ltchS
              zig build >/dev/null 2>&1
            '';

            installPhase = ''
              mkdir -p $out
              cp ${exe_name}* $out
              cp zig-out/bin/* $out
              ls -ltchHS $out >$out/ls.txt
            '';

            meta = {
              description = "-";
              license = pkgs.lib.licenses.mit;
              maintainers = with pkgs.lib.maintainers; [
                "-"
              ];
            };
          };
        };
    };
}
