{ self, inputs, ... }: {
  perSystem = { pkgs, system, ... }: {
    # adds packages in the 'main-scope' folder as base packages
    # i.e. so you can reference to `pkgs.<name>` for each package definition in `../pkgs/main-scope`
    # instead of having to type `pkgs.main-scope.<name`. Of course, this longer version works as well.
    packages = import "${self}/pkgs/main-scope" { inherit pkgs; };
  };
}
