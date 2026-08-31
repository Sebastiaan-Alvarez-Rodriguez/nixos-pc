{ inputs, ... }:
# NOTE: only need this because of recently added option `api_key_path`
self: prev: { # use unstable package
  headplane = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.headplane;
}
# NOTE: also requires configurations:
# disabledModules = [
#   "services/networking/headplane.nix"
# ];

# imports = [
#   <nixpkgs-unstable/nixos/modules/services/networking/headplane.nix>
# ];
