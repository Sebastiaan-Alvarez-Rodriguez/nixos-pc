# Overlay handling
{ self, lib, ... }: let
  default-overlays = import "${self}/overlays";
  additional-overlays = {
    lib = _final: _prev: { inherit (self) lib; }; # Expose custom expanded library
    pkgs = _final: prev: { # Expose custom packages
      custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
    };
  };
in default-overlays // additional-overlays


  # additional-overlays = {
  #   lib = _final: _prev: { inherit (self) lib; }; # Expose custom expanded library

  #   pkgs = _final: prev: { # Expose custom packages
  #     custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
  #   };
  # };
# in {
  # overlays.default = final: prev: (default-overlays inputs) final prev;
