# user-home definitions for flake.
{ self, inputs, lib, nixpkgs, ... }: let
  mkHome = { system, userModule }: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = (lib.attrValues self.overlays) ++ [ inputs.nur.overlays.default ];
    };
    modules = [
      "${self}/modules/home"
      userModule
    ];
    extraSpecialArgs = {
      inherit inputs;
    };
  };
in {
  perSystem = { system, ... }: {
    legacyPackages.homeConfigurations = {
      headless = mkHome {
        system = "x86_64-linux";
        userModule = ../hosts/homes/headless.nix;
      };
    };
  };
}
