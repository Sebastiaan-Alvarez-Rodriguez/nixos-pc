{ self, inputs, ... }: let
  default-overlays = (import "${self}/overlays" { inherit inputs; });

  additional-overlays = {
    lib = _final: _prev: { inherit (self) lib; }; # Expose expanded library
    pkgs = _final: prev: { custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; }); }; # Expose custom packages
  };

in {
  flake.overlays = default-overlays // additional-overlays;
}

# { self, inputs, ... }: let
#   default-overlays = (import "${self}/overlays" { inherit inputs; });
#   mkOverlays = system: default-overlays // {
#     lib = _final: _prev: { inherit (self) lib; }; # Expose expanded library
#     pkgs = _final: prev: {
#       custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
#       unstab = import inputs.nixpkgs-unstable { inherit system; }; # seb TODO: should inject unstable packages into pkgs.unstab (much like pkgs.custompkgs found in home modules...). Why is this not available in system modules?
#       # unstab inspired from: https://gitea.krutonium.ca/Krutonium/NixOS/src/commit/c2bbd0b21fd859e7387081b9f13e955484081eab/flake.nix
#     }; # Expose custom packages
#   };

#   # additional-overlays = {
#   #   lib = _final: _prev: { inherit (self) lib; }; # Expose expanded library
#   #   pkgs = _final: prev: { 
#   #     custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
#   #     unstable = import inputs.nixpkgs-unstable { inherit (prev) system; };
#   #   }; # Expose custom packages
#   # };

# in {
#   flake = {
#     perSystem = { system, ... }: {
#       # flake.overlays = default-overlays // additional-overlays;
#       overlays = mkOverlays system;
#     };
#   };
# }

