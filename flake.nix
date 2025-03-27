{
  description = "NixOS configuration with flakes";
  inputs = {
    agenix = {
      url = "github:ryantm/agenix/main";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts/main";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nur = {
      type = "github";
      owner = "nix-community";
      repo = "NUR";
      ref = "master";
    };

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      # url = "github:the-argus/spicetify-nix"; # produces build errors
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default/main";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = inputs: import ./flake inputs;
}
