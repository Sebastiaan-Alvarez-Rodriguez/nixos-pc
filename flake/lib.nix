{ self, inputs, ... }: {
  flake.lib = inputs.nixpkgs.lib.extend (final: _: {
    my = import "${self}/lib" { inherit inputs; pkgs = inputs.nixpkgs; lib = final; };
  });
}
