{ self, inputs, lib, ... }:
let
  defaultModules = [
    "${self}/modules/home"
    { programs.home-manager.enable = true; }
  ];

  mkHome = name: system: inputs.home-manager.lib.homeManagerConfiguration {
    # Work-around for home-manager
    # * not letting me set `lib` as an extraSpecialArgs
    # * not respecting `nixpkgs.overlays` [1]
    # [1]: https://github.com/nix-community/home-manager/issues/2954
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = (lib.attrValues self.overlays) ++ [ inputs.nur.overlay ];
    };
    modules = defaultModules ++ [ "${self}/hosts/homes/${name}" ];
    extraSpecialArgs = { inherit inputs; };
  };

  homes = {
    # "rdn@blackberry" = "aarch64-linux";
    # "rdn@neon" = "x86_64-linux";
    # "rdn@polonium" = "x86_64-linux";
    "rdn@radon" = "x86_64-linux"; # seb: Enable others later
    # "rdn@xenon" = "x86_64-linux";
  };
in {
  perSystem = { system, ... }: { # Work-around for https://github.com/nix-community/home-manager/issues/3075
    legacyPackages = {
      homeConfigurations = let
        filteredHomes = lib.filterAttrs (_: v: v == system) homes;
        allHomes = filteredHomes // { # seb: TODO fold into above expression?
          "rdn" = system; # default empty config
        };
      in
        lib.mapAttrs mkHome allHomes;
    };
  };
}
