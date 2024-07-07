{ self, nixpkgs, system, overlays, ... }: {
  ${system} = import "${self}/pkgs" {
    pkgs = import nixpkgs {
      inherit system overlays;
    };
  };
}
