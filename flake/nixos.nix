# host definitions for flake.
{ self, inputs, lib, nixpkgs, ... }: let
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
      inherit nixpkgs lib inputs system; # Inject inputs to use them in global registry
    };
  };
in nixpkgs.lib.mapAttrs buildHost {
  # "blackberry" = "aarch64-linux";
  "helium" = "x86_64-linux";
  "polonium" = "x86_64-linux";
  "radon" = "x86_64-linux";
  "xenon" = "x86_64-linux";
}
