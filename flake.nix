{
  description = "Rdn's NixOS confs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
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
    homeConfigurations.mrs = import ./users/mrs {
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
