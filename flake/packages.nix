{ self, inputs, ... }: {
  perSystem = { system, ... }: {
    legacyPackages = inputs.nixpkgs.outputs.legacyPackages.${system};
    packages = let
      inherit (inputs.futils.lib) filterPackages flattenTree;
      
      # custom-pkgs = import "${self}/pkgs" { inherit pkgs; };
      # custom-pkgs = import "${self}/pkgs" { pkgs = inputs.nixpkgs.outputs.legacyPackages.${system}; };
      custom-pkgs = import "${self}/pkgs" {
        pkgs = import inputs.nixpkgs {
          inherit system;
        };
      };
    in
      filterPackages system (flattenTree custom-pkgs);
  };
}
