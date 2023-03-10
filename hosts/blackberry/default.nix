{ inputs, nixpkgs-config }:
inputs.nixpkgs.lib.nixosSystem rec {
  system = "aarch64-linux";

  modules = [
    {
      nixpkgs = { inherit system; } // nixpkgs-config;
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
