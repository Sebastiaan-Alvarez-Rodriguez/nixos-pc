self: prev: { # Patch foot with an option that allows per-monitor scaling, so that DPI and stuff isn't so horrible.
  # inherit (nixpkgs-unstable) home-assistant;
}

# disabledModules = [
#   "services/home-automation/home-assistant.nix"
# ];

# imports = [
#   <nixos-unstable/nixos/modules/services/home-automation/home-assistant.nix>
# ];
