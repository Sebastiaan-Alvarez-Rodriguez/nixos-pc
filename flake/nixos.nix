{ self, inputs, lib, ... }: let
  defaultModules = [
    {
      system.configurationRevision = self.rev or "dirty"; # Let 'nixos-version --json' know about the Git revision
      nixpkgs.overlays = (lib.attrValues self.overlays) ++ [ inputs.nur.overlay ];
    }
    "${self}/modules/nixos" # Include generic settings
  ];

  buildHost = name: system: lib.nixosSystem {
    inherit system;
    modules = defaultModules ++ [ "${self}/hosts/nixos/${name}" ];
    specialArgs = {
      inherit (self) lib; # use custom lib when configuring.
      inherit inputs system;
    };
  };
in {
  flake.nixosConfigurations = lib.mapAttrs buildHost {
  "helium" = "x86_64-linux";
  "polonium" = "x86_64-linux";
  "radon" = "x86_64-linux";
  "xenon" = "x86_64-linux";
  };
}
