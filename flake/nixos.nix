{ self, inputs, lib, ... }: let
  defaultModules = [
    {
      system.configurationRevision = self.rev or "dirty"; # Let 'nixos-version --json' know about the Git revision
      nixpkgs.overlays = (lib.attrValues self.overlays) ++ [ inputs.nur.overlay ];
      nix.settings.trusted-users = [ "@wheel" ]; # Required for accepting remote builds
      disabledModules = [
        "services/home-automation/home-assistant.nix" # override with unstable (note: also needs package overlay)
      ];
      imports = [
        "${inputs.nixos-unstable}/nixos/modules/services/home-automation/home-assistant.nix" # override default services.home-assistant
      ];
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
