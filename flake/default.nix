{ flake-parts, systems, self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, ... } @ inputs: flake-parts.lib.mkFlake { inherit inputs; } {
  systems = import systems;

  imports = [
    ./home-manager.nix
    ./lib.nix
    ./nixos.nix
    ./overlays.nix
    ./packages.nix
  ];
}
