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

  hasprefix-any = patterns: string: lib.any (pattern: lib.hasPrefix pattern string) patterns;

  # translates nix dicts to valid LibConfig Syntax. Similar to nix's toJSON function.
  toLibConfig = d: let
    # Escape strings for libconfig syntax
    escapeString = s: ''"${builtins.replaceStrings ["\"" "\\"] ["\\\"" "\\\\"] s}"'';

    # Determine if a Nix list should be a libconfig Array [...] or List (...)
    # Arrays are ONLY for scalar values of the exact same type (e.g. integer list).
    # Lists of dicts/mixed types MUST use parentheses (...).
    formatList = l:
      if l == [] then "[ ]"
      else if builtins.isAttrs (builtins.head l) then 
        "(\n" + (builtins.concatStringsSep ",\n" (builtins.map formatValue l)) + "\n)"
      else 
        "[ " + (builtins.concatStringsSep ", " (builtins.map formatValue l)) + " ]";
    # Format individual values based on their Nix type
    formatValue = v:
      if builtins.isAttrs v  then "{\n" + (toLibConfig v) + "}"
      else if builtins.isList v   then formatList v
      else if builtins.isString v then escapeString v
      else if builtins.isInt v    then builtins.toString v
      else if builtins.isFloat v  then builtins.toString v
      else if builtins.isBool v   then (if v then "true" else "false")
      else throw "Unsupported data type for libconfig serialization";

    # Process each key-value pair in the attribute set
    formatPair = name: value: "${name}: ${formatValue value};";
  in builtins.concatStringsSep "\n" (lib.mapAttrsToList formatPair d) + "\n";
}
