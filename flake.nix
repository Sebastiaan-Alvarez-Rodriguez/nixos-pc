{
  description = "Rdn's NixOS confs";


  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs_2205.url = "github:nixos/nixpkgs/nixos-22.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.11";
    simple-nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
    # sebas-webserver.url = "path:packages/sebas-webserver";
  };

  outputs = inputs: let
    nixpkgs-config = {
      overlays = [ inputs.self.overlays.default ];
      config = {
        allowUnfree = true;
        # https://github.com/nix-community/home-manager/issues/2942#issuecomment-1119760100
        allowUnfreePredicate = (pkg: true);
      };
    };
  in rec {
    overlays.default = import ./overlays;

    nixosConfigurations = {
      blackberry = import ./hosts/blackberry {
        inherit inputs nixpkgs-config;
      };
      xenon = import ./hosts/xenon {
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
        userModule = ./users/mrs/mrs.nix;
      };
      rdn = mkUser {
        system = "x86_64-linux";
        userModule = ./users/rdn/rdn.nix;
      };
      rdn-blackberry-min = mkUser {
        system = "aarch64-linux";
        userModule = ./users/rdn/rdn-headless.nix;
      };
      rdn-headless = mkUser {
        system = "x86_64-linux";
        userModule = ./users/rdn/rdn-headless.nix;
      };
      mrs-headless = mkUser {
        system = "x86_64-linux";
        userModule = ./users/mrs/mrs-headless.nix;
      };
    };
    packages = let
      system = "x86_64-linux";
    in {
      ${system} = import ./packages {
        inherit system inputs nixpkgs-config;
      };
    };
  };
}
