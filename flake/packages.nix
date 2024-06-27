{ self, nixpkgs, system, ... }: {
  ${system} = import ../pkgs {
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };
  };
}
