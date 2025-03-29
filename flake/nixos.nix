{ self, inputs, lib, ... }: let
  defaultModules = [
    {
      system.configurationRevision = self.rev or "dirty"; # Let 'nixos-version --json' know about the Git revision
    }
    {
      nixpkgs.overlays = (lib.attrValues self.overlays) ++ [ inputs.nur.overlays.default ];
      nix.settings.trusted-users = [ "@wheel" ]; # Required for accepting remote builds
    }
    { # override home-assistant
      disabledModules = [ "services/home-automation/home-assistant.nix" ]; # override with unstable (note: also needs package overlay)
      imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/home-automation/home-assistant.nix" ]; # override default services.home-assistant
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

  buildImageHost = name: system: lib.nixosSystem {
    inherit system;
    modules = defaultModules ++ [ "${self}/hosts/nixos/${name}" "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];
    specialArgs = {
      inherit (self) lib; # use custom lib when configuring.
      inherit inputs system;
    };
  };

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

  # perSystem = { inputs', system, ...}: {
    # extraSpecialArgs = { inherit inputs' system;};

  flake.nixosModules.nixos-pc = let
  # try 1
  #   nested-paths = (import ../modules/nixos {inherit lib system;}).imports;
  #   unnest-import = path: (import path { }).imports;
  #   import-paths = paths: lib.flatten (builtins.map unnest-import paths); # --> [ [./something ./other] [./hi ]} ] --> [ ./something ./other ./hi ...]
  #   final-paths = import-paths nested-paths;
  #   name-it = path: let
  #     parts = builtins.split "/" (toString path);
  #   in lib.nameValuePair (builtins.elemAt parts (builtins.length parts -1)) path;
  # in lib.listToAttrs (builtins.map name-it final-paths);
  # try 2 (exposes paths, did not import them?)
  #   mk-paths = paths: lib.flatten (builtins.map (p: (import p {inherit lib;}).imports) paths);
  #   name-it = path: let
  #     parts = builtins.split "/" (toString path);
  #   in lib.nameValuePair (builtins.elemAt parts (builtins.length parts -1)) path;
  #   expose-modules = paths: lib.listToAttrs (builtins.map name-it (mk-paths paths));
  # in (expose-modules [ ../modules/nixos/hardware ../modules/nixos/programs ../modules/nixos/services  ../modules/nixos/system]) // {
  #   secrets = ../secrets;
  # };
    # try 3
    mk-paths = paths: lib.flatten (builtins.map (p: (import p {inherit lib;}).imports) paths);
    name-it = path: let parts = builtins.split "/" (toString path); in lib.nameValuePair (builtins.elemAt parts (builtins.length parts -1)) (import path);
    expose-modules = paths: lib.listToAttrs (builtins.map name-it (mk-paths paths));
  in (expose-modules [ ../modules/nixos/hardware ../modules/nixos/programs ../modules/nixos/services  ../modules/nixos/system]) // {
    secrets = import ../secrets;
  }; 
  # };
    # {jellyfin = import ../modules/nixos/services/jellyfin; }
  # flake.nixosModules = import ../modules/nixos { inherit lib; };

  # flake.nixosModules = { # used for export only
  #   nixos-pc = import "${self}/modules/nixos";
  # };
}
