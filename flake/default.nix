{ flake-parts, systems, self, nixpkgs, nixpkgs-24_05, nixpkgs-unstable, nixpkgs-hydenix, nixos-hardware, ... } @ inputs: flake-parts.lib.mkFlake { inherit inputs; } {
  systems = import systems;

  imports = [
    inputs.agenix-rekey.flakeModule
    ./lib.nix
    ./nixos.nix
    ./overlays.nix
    ./packages.nix

  ];

  perSystem = {config, pkgs, ...}: {
    agenix-rekey.nixosConfigurations = inputs.self.nixosConfigurations;
  };    
}
