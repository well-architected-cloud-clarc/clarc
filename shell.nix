{ pkgs ? import <nixpkgs> {} }:

let

  moth = (builtins.getFlake "github:tailoredshapes/moth")
      .packages.${pkgs.system}.default;

in pkgs.mkShellNoCC {

  # rust toolchain comes from ci.nix, the same environment CI builds with
  inputsFrom = [ (import ./ci.nix { inherit pkgs; }) ];

  buildInputs = [
    pkgs.drawio-headless  # scripts/render.sh
    moth
  ];

}
