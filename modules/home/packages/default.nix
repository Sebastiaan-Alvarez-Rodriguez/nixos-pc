{ config, lib, pkgs, ... }:
let
  cfg = config.my.home.packages;
in
{
  options.my.home.packages = with lib; {
    enable = my.mkDisableOption "user packages";

    allowAliases = mkEnableOption "allow package aliases";
    allowUnfree = my.mkDisableOption "allow unfree packages";

    additionalPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.additionalPackages;

    nixpkgs.config = {
      inherit (cfg) allowAliases allowUnfree;
    };
  };
}