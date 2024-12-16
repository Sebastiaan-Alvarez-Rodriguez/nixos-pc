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
  buildImageHost = name: system: let
    base = buildHost name system;
  in { modules = defaultModules ++ [ "${self}/hosts/nixos/${name}" "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];} // base;

in rec {
  flake.nixosConfigurations = lib.mapAttrs buildHost {
    "helium" = "x86_64-linux";
    "polonium" = "x86_64-linux";
    "radon" = "x86_64-linux";
    "xenon" = "x86_64-linux";
  } // lib.mapAttrs buildImageHost {
    "blackberry" = "aarch64-linux";
  };

  flake.images = {
    "blackberry" = flake.nixosConfigurations."blackberry".config.system.build.sdImage;
  };
}
