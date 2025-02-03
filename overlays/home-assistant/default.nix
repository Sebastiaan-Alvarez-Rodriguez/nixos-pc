{ inputs, ... }:
self: prev: { # use unstable package
  home-assistant = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.home-assistant;
}
# NOTE: also requires configurations:
# disabledModules = [
#   "services/home-automation/home-assistant.nix"
# ];

# imports = [
#   <nixpkgs-unstable/nixos/modules/services/home-automation/home-assistant.nix>
# ];
