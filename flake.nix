{
  description = "NixOS configuration with flakes";
  inputs = {
    agenix = { # basic agenix secret generation
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix-rekey = { # agenix extra features
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = { # util to separate a regular flake definition in multiple sections cleanly
      url = "github:hercules-ci/flake-parts/main";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = { # declarative per-user home management
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland and themes
    hyprland.url = "github:hyprwm/Hyprland";
    end4-illogical = { # an end4 hyprland theme
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nur.follows = "nur";
    };

    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-24_05.url = "nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nur = { # custom non-merged packages
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver = { # mail server implementation (lightweight)
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = { # spotify but better
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = { # uniform styling for many UI components
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default/main";

    # zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = inputs: import ./flake inputs;
}
