{ config, inputs, lib, pkgs, ... }: let
  # actualPath = [ "home-manager" "users" config.my.user.name "my" "home" ];
  # actualPath = [ "home-manager" "users" "rdn" "my" "home" ];
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
      default = builtins.attrNames (lib.filterAttrs (n: v: v.isNormalUser) config.users.users); # seb TODO: check if I get too many users back (e.g. all those module-defined system users)
      # default = lib.filterAttrs (n: v: v.isNormalUser) config.users.users;
      # default = config.users.users;
      description = "users";
    };
    generic = mkOption {
      type = with types; attrs;
      default = {};
      description = "Generic config to be applied to all home-manager users.";
    };
  };

  config = let
    default-home-config = {pkgs, ...}: { 
      imports = ["${inputs.self}/modules/home"];
      my.home = cfg.generic;
    };
    mkUser = name: lib.nameValuePair name default-home-config;
    mkUsers = list: builtins.listToAttrs (builtins.map mkUser list);
  in {
    home-manager = {
      # users.rdn = import "${inputs.self}/modules/home"; # works, not what I want (must iterate cfg.users)
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
        inherit inputs;
      };
    };
  };
}
