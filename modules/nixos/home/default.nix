{ config, inputs, lib, pkgs, ... }: let
  actualPath = [ "my" "system" "home" "generic" ];
  aliasPath = [ "my" "home" ];
  cfg = config.my.system.home;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager # enable home-manager options
    (lib.mkAliasOptionModule aliasPath actualPath) # simplify setting home options for all users
  ];

  options.my.system.home = with lib; {
    users = mkOption {
      type = with types; listOf (str);
      default = builtins.attrNames (lib.filterAttrs (n: v: v.isNormalUser) config.users.users); # NOTE: all normal i.e. user-defined users.
      description = "users";
    };
    generic = mkOption {
      type = with types; attrs;
      default = {};
      description = "Generic config to be applied to all home-manager users.";
    };
  };

  config = let
    generate-default-home-config = name: system: ({pkgs, ...}: {
      imports = [
        "${inputs.self}/modules/home" # generic home module so we have access to all my.home.... options.
        "${inputs.self}/hosts/homes/${name}@${system}" # specific home module of a user, e.g. hosts/homes/user@host.
      ];
      my.home = cfg.generic; # sets options of my.home modules. Options defined here are defined in the host's configuration, applied to all users.
    });
    simple-gen = name: generate-default-home-config name config.my.hardware.networking.hostname;
    mkUser = name: lib.nameValuePair name (simple-gen name);
    mkUsers = list: builtins.listToAttrs (builtins.map mkUser list);
  in {
    home-manager = {
      users = mkUsers cfg.users; # For each user, provides the methodology.
      # Above works like https://github.com/nix-community/home-manager/blob/8d5e27b4807d25308dfe369d5a923d87e7dbfda3/templates/nixos/flake.nix#L20
      # It declares home-manager config for a given 'user' from the 'system' configuration.
      # Does that imply that I don't have to execute home-manager commands for the users specified here, and those user configs are processed alongside system configs?
      # This probably means I don't have to execute home-manager commands for the users declared in the system config?
      # https://github.com/nix-community/home-manager/blob/8d5e27b4807d25308dfe369d5a923d87e7dbfda3/docs/manual/installation/nix-darwin.md?plain=1#L35

      # Nix Flakes compatibility
      useGlobalPkgs = true;
      useUserPackages = true;

      # Forward inputs to home-manager configuration
      extraSpecialArgs = {
        inherit inputs pkgs;
      };
    };
  };
}
