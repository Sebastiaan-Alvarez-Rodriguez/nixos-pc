# Overlay handling
{ self, inputs, lib, ... }: let
  default-overlays = import "${self}/overlays";
  # additional-overlays = {
  #   lib = _final: _prev: { inherit (self) lib; }; # Expose custom expanded library
  #   pkgs = _final: prev: { # Expose custom packages
  #     custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
  #   };
  # };
  additional-overlays = final: prev: {
    # pkgs = {
    #   custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" prev);
    # };
  };
in
  final: prev: ((default-overlays inputs) final prev) // (additional-overlays final prev) 
