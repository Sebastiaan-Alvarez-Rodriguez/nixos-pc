{ lib, ... }: let
  inherit (lib) filterAttrs file foldl listToAttrs mapAttrs' nameValuePair recursiveUpdate;
in rec {
  # rename = { file, name }: builtins.runCommand "rename-${name}" { } ''
  #   cp ${file} $out/${name}
  # '';
  # fetchurl = {url, sha256, name ? null}: if name == null then (builtins.fetchurl { inherit url sha256; }) else rename {
  #   file = (builtins.fetchurl { inherit url sha256; });
  #   name = name;
  # };
  power = base: exp: lib.foldl (x: _: x * base) 1 (lib.range 1 exp);
}
