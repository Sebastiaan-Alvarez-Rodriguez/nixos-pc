{ inputs, nixpkgs-config }: inputs.nixpkgs.lib.nixosSystem rec {
  system = "x86_64-linux";

  modules = [
    {
      nixpkgs = { inherit system; } // nixpkgs-config;
      nix = import ../../nix-settings.nix { inherit inputs system; };
    }
    # Use the pinned inputs as channels in the final configuration.
    ./configuration.nix
  ];

  specialArgs = { inherit inputs; };
}
