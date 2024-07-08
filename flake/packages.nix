{ self, inputs, ... }: {
  perSystem = { pkgs, system, ... }: {
    packages = import "${self}/pkgs" { inherit pkgs; };
  };
}
