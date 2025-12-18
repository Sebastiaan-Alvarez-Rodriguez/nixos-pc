{ flake-parts, systems, self, nixpkgs, nixpkgs-24_05, nixpkgs-unstable, nixos-hardware, home-manager, ... } @ inputs: flake-parts.lib.mkFlake { inherit inputs; } {
  systems = import systems;

  imports = [
    inputs.agenix-rekey.flakeModule
    ./home-manager.nix
    ./lib.nix
    ./nixos.nix
    ./overlays.nix
    ./packages.nix

  ];

  perSystem = {config, pkgs, ...}: {
    agenix-rekey.nixosConfigurations = inputs.self.nixosConfigurations;
  };    
}
