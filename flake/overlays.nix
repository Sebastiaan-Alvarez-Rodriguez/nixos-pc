{ self, ... }:
let
  default-overlays = import "${self}/overlays";

  additional-overlays = {
    # Expose custom expanded library
    lib = _final: _prev: { inherit (self) lib; };

    # Expose custom packages
    pkgs = _final: prev: {
      ambroisie = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
    };
  };
in {
  flake.overlays = default-overlays // additional-overlays;
}
