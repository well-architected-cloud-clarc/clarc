# Build environment shared by CI and the dev shell (shell.nix imports this).
# `nix-shell ci.nix --run 'cargo ...'` for native builds, `nix-shell ci.nix -A windows` to cross-compile the windows exe.
{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/aa290c9891fa4ebe88f8889e59633d20cc06a5f2.tar.gz";
    sha256 = "0l2gcz0wzzcjbvygrgxqf6c9hji9yq1il13779i95i09ijl7q13b";
  }) {} }:

let
  mingw = pkgs.pkgsCross.mingwW64;

  # rustc/cargo built for the mingw target, linked with the mingw-w64 gcc
  windows = pkgs.mkShellNoCC {
    packages = [ mingw.buildPackages.rustc mingw.buildPackages.cargo mingw.stdenv.cc ];
    buildInputs = [ mingw.windows.pthreads ];
    CARGO_BUILD_TARGET = "x86_64-pc-windows-gnu";
    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER = "x86_64-w64-mingw32-gcc";
  };

in pkgs.mkShellNoCC {
  # patchelf resets the nix interpreter/rpath of linux binaries so they run on any distro
  packages = [ pkgs.rustc pkgs.cargo ] ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.patchelf;
  passthru = { inherit windows; };
}
