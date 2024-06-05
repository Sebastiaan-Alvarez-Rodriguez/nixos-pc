# Common packages
{ config, lib, pkgs, ... }: let
  cfg = config.my.system.packages;
in {
  options.my.system.packages = with lib; {
    enable = mkEnableOption "packages configuration";
    allowAliases = mkEnableOption "allow package aliases";
    allowUnfree = mkEnableOption "allow unfree packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ micro vim wget ];

    programs = {
      fish.enable = true;
    };

    nixpkgs.config = {
      inherit (cfg) allowAliases allowUnfree;
    };
  };
}
