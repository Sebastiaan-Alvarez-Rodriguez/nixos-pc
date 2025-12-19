{ self, inputs, ... }: let
  default-overlays = (import "${self}/overlays" { inherit inputs; });

  additional-overlays = {
    lib = _final: _prev: { inherit (self) lib; }; # Expose expanded library

    # Creates package scope named <SOMETHING> for every directory in <repo-root>/pkgs/<SOMETHING>-scope.
    # If `<repo-root/pkgs/<some-dir>` does not end on suffix `-scope`, the function searches down recusively into `<some-dir`.
    # The scope then becomes `<some-dir>.<SOMETHING>`.
    # I.e. you can make nested scopes using directories. This function nests them until it finds a leaf node.
    # Final function output looks like:
    # pkgs = _final: prev {
    #   "some" = {
    #     "hit" = prev.recurseIntoAttrs (import "${self}/pkgs/some/hit-scope" { pkgs = prev; });
    #     "test" = prev.recurseIntoAttrs (import "${self}/pkgs/some/test-scope" { pkgs = prev; });
    #   };
    #   another = prev.recurseIntoAttrs (import "${self}/pkgs/another-scope" { pkgs = prev; });
    # }
    pkgs = _final: prev: let
      mkName = dir: self.lib.removeSuffix "-scope" dir;
      mkScope = dir: item-name: { name = (mkName item-name); value = (prev.lib.recurseIntoAttrs (import "${dir}/${item-name}" { pkgs = prev; })); };
      
      filterDirs = attrs: self.lib.filterAttrs (name: type: type == "directory") attrs;
      getDirs = leaf-func: dir: self.lib.mapAttrs' (name: _: if (self.lib.hasSuffix "-scope" name) then (leaf-func dir name) else {name = name; value = (getDirs leaf-func "${dir}/${name}");}) (filterDirs (builtins.readDir dir));
      scopeDirs = leaf-func: dir: (getDirs leaf-func dir);
    in
      scopeDirs mkScope "${self}/pkgs";
  };

in {
  flake.overlays = default-overlays // additional-overlays;
}
