{ inputs, system, nixpkgs-config }:
let
  pkgs = import inputs.nixpkgs ({ inherit system; } // nixpkgs-config );
in {
  breeze-obsidian-cursor-theme = pkgs.callPackage ./breeze-obsidian-cursor-theme.nix { };
  ruckus_cp210x = pkgs.callPackage ./ruckus_cp210x { };
  spotify-adblock = pkgs.callPackage ./spotify-adblock.nix { };
  inherit (pkgs) qemu;
}
