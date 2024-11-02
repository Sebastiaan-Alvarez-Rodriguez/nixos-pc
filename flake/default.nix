{ flake-parts, systems, self, nixpkgs, nixos-hardware, nixos-unstable, home-manager, ... } @ inputs: flake-parts.lib.mkFlake { inherit inputs; } {
  systems = import systems;

  imports = [
    ./apps.nix
    ./home-manager.nix
    ./lib.nix
    ./nixos.nix
    ./overlays.nix
    ./packages.nix
  ];
}
