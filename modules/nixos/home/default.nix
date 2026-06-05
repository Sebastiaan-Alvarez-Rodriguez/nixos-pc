{ config, inputs, lib, pkgs, system, ... }: let
  cfg = config.my.system.home;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager # enable home-manager options
  ];

  options.my.system.home = with lib; {
    users = mkOption {
      type = with types; attrs;
      default = {};
      example = litteralExample ''
        {
          users."testname" = { ... }: {
            my.home.some.module.option.enable = true;
          };
        }
      '';
      description = "user configurations";
    };
  };

  config = {
    home-manager = {
      useGlobalPkgs = true; # seb NOTE: cannot have `nixpkgs.config` and/or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`
      useUserPackages = true; # To decide whether to keep true or set false: https://discourse.nixos.org/t/home-manager-useuserpackages-useglobalpkgs-settings/34506/10
      extraSpecialArgs = { inherit inputs; };
      backupFileExtension = "hm-bkp";
      overwriteBackup = true;
      
      users = cfg.users;
    };
  };
}
