{ self, inputs, ... }: let
  default-overlays = (import "${self}/overlays" { inherit inputs; });

  additional-overlays = {
    lib = _final: _prev: { inherit (self) lib; }; # Expose expanded library

    # creates package scope named <SOMETHING> for every directory in <repo-root>/pkgs/<SOMETHING>-scope.
    # Final function output looks like:
    # pkgs = _final: prev: {
    #   SOMETHING = prev.recurseIntoAttrs (import "${self}/pkgs/SOMETHING-scope" { pkgs = prev; });
    #   # ...
    # };
    pkgs = _final: prev: let
      contents = builtins.attrNames (builtins.readDir "${self}/pkgs");
      filterDirs = dirs: builtins.filter (name: (self.lib.hasSuffix "-scope" name)) dirs;
      mkName = self.lib.removeSuffix "-scope";
      mkScope = dir: { name = (mkName dir); value = (prev.recurseIntoAttrs (import "${self}/pkgs/${dir}" { pkgs = prev; })); };
    in
     builtins.listToAttrs (builtins.map (dir: mkScope dir) (filterDirs contents));
  };

in {
  flake.overlays = default-overlays // additional-overlays;
}
