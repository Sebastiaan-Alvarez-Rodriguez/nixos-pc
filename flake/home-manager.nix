# user-home definitions for flake.
{ self, inputs, lib, nixpkgs, ... }: let
  mkHome = { system, userModule }: inputs.home-manager.lib.homeManagerConfiguration {
    modules = [
      "${self}/modules/home"
      {
        nixpkgs = {
          overlays = [ self.overlays.default self.overlays.customlib self.overlays.custompkgs ];
          config = {
            allowUnfree = true;
            allowUnfreePredicate = (pkg: true);
          };
        };
      }
      userModule
    ];
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = (lib.attrValues self.overlays) ++ [ inputs.nur.overlay ];
    };
    extraSpecialArgs = { inherit inputs; };
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
