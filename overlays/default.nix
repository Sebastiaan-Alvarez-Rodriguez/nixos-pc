# Automatically import all overlays in the directory
{ inputs, ... }:
let
  files = builtins.readDir ./.;
  overlays = builtins.removeAttrs files [ "default.nix" ];
in
  builtins.mapAttrs (name: _: import "${./.}/${name}" { inherit inputs; }) overlays
