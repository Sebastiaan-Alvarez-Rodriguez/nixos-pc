{
  description = "Rdn's NixOS confs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
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
  in rec {
    nixosConfigurations = {
      blackberry = import ./hosts/blackberry {
        inherit inputs nixpkgs-config;
      };
      polonium = import ./hosts/polonium {
        inherit inputs nixpkgs-config;
      };
      radon = import ./hosts/radon {
        inherit inputs nixpkgs-config;
      };
    };

    # Define a flake image from each of the host nixosConfigurations.
    # images = nixpkgs-config.lib.genAttrs hosts
    #   (host: nixosConfigurations."${host}".config.system.build.sdImage);

    images = {
      "blackberry" = nixosConfigurations."blackberry".config.system.build.sdImage;
    };
    
    homeConfigurations = let
      mkUser = { system, userModule }: inputs.home-manager.lib.homeManagerConfiguration {
        modules = [
          { nixpkgs = nixpkgs-config; }
          userModule
        ];
        pkgs = inputs.nixpkgs.outputs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs; };
      };
    in {
      mrs = mkUser {
        system = "x86_64-linux";
        userModule = ./users/mrs.nix;
      };
      rdn = mkUser {
        system = "x86_64-linux";
        userModule = ./users/rdn.nix;
      };
      rdn-blackberry-min = mkUser {
        system = "aarch64-linux";
        userModule = ./users/rdn-blackberry-min.nix;
      };
    };
  };
}
