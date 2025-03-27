{ flake-parts, systems, self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, ... } @ inputs: flake-parts.lib.mkFlake { inherit inputs; } {
  systems = import systems;

  imports = [
    ./home-manager.nix
    ./lib.nix
    ./nixos.nix
    ./overlays.nix
    ./packages.nix
  ];

  # perSystem = { lib, pkgs, system, ... }: {
  #   _module.args.pkgs = import self.inputs.nixpkgs { # seb TODO: as taken from https://flake.parts/overlays#consuming-an-overlay, does not work, i.e. does not expose added 'unstab' in system.
  #     inherit system;
  #     overlays = [ (_final: prev: { unstab = prev.recurseIntoAttrs (import inputs.nixpkgs-unstable { inherit system; }); }) ];
  #     config.allowUnfree = true;
  #   };
  # };
}
