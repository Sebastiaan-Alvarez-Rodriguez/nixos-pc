{ self, inputs, ... }: let
  default-overlays = (import "${self}/overlays" { inherit inputs; });

  additional-overlays = {
    lib = _final: _prev: { inherit (self) lib; }; # Expose expanded library
    pkgs = _final: prev: { custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; }); }; # Expose custom packages
  };

in {
  flake.overlays = default-overlays // additional-overlays;
}
