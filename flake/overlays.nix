{ self, ... }: let
  default-overlays = import "${self}/overlays";

  additional-overlays = {
    lib = _final: _prev: { inherit (self) lib; }; # Expose custom expanded library

    pkgs = _final: prev: { # Expose custom packages
      custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
    };
  };
in {
  flake.overlays = default-overlays // additional-overlays;
}
