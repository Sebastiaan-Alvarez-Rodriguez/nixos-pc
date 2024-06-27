{ self, nixpkgs, nixos-hardware, home-manager, ... } @ inputs: let
  lib = import ./lib.nix { inherit self nixpkgs inputs; };
in {
  # seb: This is what an output provides: https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/outputs

  overlays.customlib = _final: _prev: { inherit lib; }; # Expose custom expanded library
  overlays.custompkgs =  _final: prev: { # Expose custom packages
    custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
  };
  # overlays.default = import ./overlays.nix { inherit self lib; };
  overlays.default = import "${self}/overlays";
  # let
  #   default-overlays = import "${self}/overlays";
  #   additional-overlays = {
  #     lib = _final: _prev: { inherit (self) lib; }; # Expose custom expanded library
  #     pkgs = _final: prev: { # Expose custom packages
  #       custompkgs = prev.recurseIntoAttrs (import "${self}/pkgs" { pkgs = prev; });
  #     };
  #   };
  # in self: super: (default-overlays // additional-overlays);
  # in (default-overlays // additional-overlays);

  nixosConfigurations = let
    defaultModules = [
      {
        system.configurationRevision = self.rev or "dirty"; # Let 'nixos-version --json' know about the Git revision
        nixpkgs.overlays = [ inputs.nur.overlay ]; # seb: NOTE used to be: nixpkgs.overlays = (nixpkgs.lib.attrValues self.overlays) ++ [ inputs.nur.overlay ];
      }
      "${self}/modules/nixos" # Include generic settings
    ];
    buildHost = name: system: nixpkgs.lib.nixosSystem {
      inherit system;
      modules = defaultModules ++ [ "${self}/hosts/nixos/${name}" ];
      # pkgs = inputs.nixpkgs.outputs.legacyPackages.${system};
      specialArgs = {
        inherit nixpkgs lib inputs; # Inject inputs to use them in global registry
      };
    };
  in nixpkgs.lib.mapAttrs buildHost {
    # "blackberry" = "aarch64-linux";
    # "neon" = "x86_64-linux";
    "polonium" = "x86_64-linux";
    "radon" = "x86_64-linux";
    # "xenon" = "x86_64-linux";
  };
  packages = let
    system = "x86_64-linux";
  in {
    # ${system} = import ./packages.nix {
    #   inherit self system inputs lib;
    #   pkgs = import nixpkgs {
    #     inherit system;
    #     overlays = [ self.overlays.default ];
    #   };
    # };
    ${system} = import ../pkgs {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default self.overlays.customlib self.overlays.custompkgs ];
      };
    };
  };
}
