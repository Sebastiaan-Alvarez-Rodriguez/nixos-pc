{
  description = "Rdn's NixOS confs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
  # Will T nixos flake setup
  # let
  #   system = "x86_64-linux";
  #   pkgs = import inputs.nixpkgs {
  #     inherit system;
  #     config = {
  #       allowUnfree = true;
  #       # https://github.com/nix-community/home-manager/issues/2942#issuecomment-1119760100
  #       allowUnfreePredicate = (pkg: true);
  #     };
  #   };
  #   lib = inputs.nixpkgs.lib;
  # in {
  #   nixosConfigurations.radon = import ./hosts/radon {
  #     inherit inputs pkgs;
  #   };

  #   homeConfigurations.rdn = import ./users/rdn {
  #     inherit inputs pkgs;
  #   };
  # };

  # Robin nixos flake setup
  let
    nixpkgs-config = {
      config = {
        allowUnfree = true;
        # https://github.com/nix-community/home-manager/issues/2942#issuecomment-1119760100
        allowUnfreePredicate = (pkg: true);
      };
    };
  in {
    nixosConfigurations = {
      polonium = import ./hosts/polonium {
        inherit inputs nixpkgs-config;
      };
      radon = import ./hosts/radon {
        inherit inputs nixpkgs-config;
      };
    };

    homeConfigurations.rdn = import ./users/rdn {
      inherit inputs nixpkgs-config;
    };

    packages =
    let
      system = "x86_64-linux";
    in {
      ${system} = import ./packages {
        inherit system inputs nixpkgs-config;
      };
    };
  };
}
