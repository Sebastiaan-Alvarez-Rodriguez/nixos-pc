{ lib, ... }: let
  inherit (lib) filterAttrs foldl listToAttrs mapAttrs' nameValuePair recursiveUpdate;
in {
  power = base: exp: lib.foldl (x: _: x * base) 1 (lib.range 1 exp);
}
