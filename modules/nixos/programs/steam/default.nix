{ config, lib, pkgs, ... }: let
  cfg = config.my.programs.steam;
  steam = pkgs.steam;
in {
  options.my.programs.steam = with lib; {
    enable = mkEnableOption "steam configuration";
    enable-proton-ge = mkEnableOption "enable proton GE (from here: https://github.com/GloriousEggroll/proton-ge-custom)";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        extraCompatPackages = lib.optional cfg.enable-proton-ge pkgs.proton-ge-bin;

        package = pkgs.steam.override {
          extraEnv = {
            STEAM_DISABLE_GPU_ACCELERATION = "1"; # also possible from steam ui: steam > settings > interface > enable GPU accelerated rendering in web views
          };
        };
      };
      nix-ld.enable = true; # for all those executables with hardcoded /lib64 dynamic linker
    };
  };
}
