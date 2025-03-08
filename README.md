Cross-compiling "hello, world" in c and zig. \
See
[flake.nix](./flake.nix)
and
[build.zig](./build.zig)
for build setup.

To reproduce the output,
you need
[zig](https://ziglang.org/download/)
and
[nix](https://github.com/DeterminateSystems/nix-installer)
installed.

Afterwards, run:

```sh
./scripts/build
./scripts/run
```
