{ inputs, ... }:
self: prev: { # use unstable package
  home-assistant = inputs.nixos-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.home-assistant;
}

# disabledModules = [
#   "services/home-automation/home-assistant.nix"
# ];

# imports = [
#   <nixos-unstable/nixos/modules/services/home-automation/home-assistant.nix>
# ];
