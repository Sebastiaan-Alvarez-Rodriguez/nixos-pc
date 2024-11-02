{ self, inputs, ... }: let
  default-overlays = import "${self}/overlays";

  additional-overlays = {
    lib = _final: _prev: { inherit (self) lib; }; # Expose expanded library
    pkgs = _final: prev: { custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; }); }; # Expose custom packages
  };

  ha-overlay = {
    home-assistant = final: prev: { 
      home-assistant = inputs.nixos-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.home-assistant;
    };
  };
in {
  flake.overlays = default-overlays // additional-overlays // ha-overlay;
}
