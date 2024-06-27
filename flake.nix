{
  description = "NixOS configuration with flakes";
  inputs = {
    # agenix = {
    #   type = "github";
    #   owner = "ryantm";
    #   repo = "agenix";
    #   ref = "main";
    #   inputs = {
    #     home-manager.follows = "home-manager";
    #     nixpkgs.follows = "nixpkgs";
    #     systems.follows = "systems";
    #   };
    # };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "nixpkgs/nixos-24.05";
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
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Can't eta-reduce a flake outputs...
  outputs = inputs: import ./flake inputs;
}
