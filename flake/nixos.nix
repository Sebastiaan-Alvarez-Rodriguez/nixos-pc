{ self, inputs, lib, ... }:
let
  defaultModules = [
    {
      # Let 'nixos-version --json' know about the Git revision
      system.configurationRevision = self.rev or "dirty";
    }
    {
      nixpkgs.overlays = (lib.attrValues self.overlays) ++ [
        inputs.nur.overlay
      ];
    }
    # Include generic settings
    "${self}/modules/nixos"
  ];

  buildHost = name: system: lib.nixosSystem {
    inherit system;
    modules = defaultModules ++ [
      "${self}/hosts/nixos/${name}"
    ];
    specialArgs = {
      # Use my extended lib in NixOS configuration
      inherit (self) lib;
      # Inject inputs to use them in global registry
      inherit inputs;
    };
  };
in
{
  flake.nixosConfigurations = lib.mapAttrs buildHost {
    # "blackberry" = "aarch64-linux";
    # "neon" = "x86_64-linux";
    "polonium" = "x86_64-linux";
    "radon" = "x86_64-linux";
    # "xenon" = "x86_64-linux";
  };
}
