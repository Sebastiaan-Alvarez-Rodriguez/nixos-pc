{ self, nixpkgs, nixos-hardware, home-manager, ... } @ inputs: let
  lib = import ./lib.nix { inherit self nixpkgs inputs; };
in {
  # seb: This is what an output provides: https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/outputs

  nixosModules = import ./modules/nixos;

  homeConfigurations = import ./home-manager.nix { inherit self inputs lib nixpkgs; };

  nixosConfigurations = import ./nixos.nix { inherit self inputs lib nixpkgs; };

  overlays.default = import ./overlays.nix { inherit self inputs lib; };

  packages = let
    system = "x86_64-linux";
    # overlays = builtins.attrValues self.overlays;
    overlays = [ self.overlays.default ];
  in import ./packages.nix { inherit self nixpkgs system overlays; };
}
