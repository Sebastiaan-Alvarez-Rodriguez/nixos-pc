{ config, lib, pkgs, ... }: let
  cfg = config.my.programs.steam;
  steam = pkgs.steam;
in {
  options.my.programs.steam = with lib; {
    enable = mkEnableOption "steam configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    };
  };
}
