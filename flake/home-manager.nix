# host definitions for flake.
{ self, inputs, lib, nixpkgs, ... }: let
  mkHome = { system, userModule }: home-manager.lib.homeManagerConfiguration {
    modules = [
      userModule
      {
        nixpkgs = {
          overlays = [ self.overlays.default self.overlays.customlib self.overlays.custompkgs ];
          config = {
            allowUnfree = true;
            # https://github.com/nix-community/home-manager/issues/2942#issuecomment-1119760100
            allowUnfreePredicate = (pkg: true);
          };
        };
      }
    ];
    pkgs = nixpkgs.outputs.legacyPackages.${system};
    extraSpecialArgs = { inherit inputs; };
  };
in {
  headless = mkHome {
    system = "x86_64-linux";
    userModule = ${self}/hosts/homes/headless.nix;
  };
};
