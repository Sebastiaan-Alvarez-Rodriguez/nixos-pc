# system package configuration
{ config, lib, pkgs, ... }: let
  cfg = config.my.system.packages;
in {
  options.my.system.packages = with lib; {
    enable = mkEnableOption "packages configuration";
    allowAliases = mkEnableOption "allow package aliases";
    allowUnfree = mkEnableOption "allow unfree packages";
    default-pkgs =  mkOption {
      type = with types; listOf (package);
      default = [];
      description = "Default systempackages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = cfg.default-pkgs;

    nixpkgs.config = {
      inherit (cfg) allowAliases allowUnfree;
    };
  };
}
