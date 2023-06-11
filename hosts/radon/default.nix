{ inputs, nixpkgsConfig }:
inputs.nixpkgs.lib.nixosSystem rec {
  system = "x86_64-linux";

  modules = [
    {
      nixpkgs = { inherit system; } // nixpkgsConfig;
      nix = import ../../nix-settings.nix { inherit inputs system; };
    }
    ./configuration.nix
    inputs.home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
  ];

  specialArgs = { inherit inputs; };
}
