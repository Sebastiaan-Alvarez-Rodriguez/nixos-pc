{ config, lib, pkgs, ... }: let
  cfg = config.my.home.zen-browser;
in {
  options.my.home.zen-browser = with lib; {
    enable = mkEnableOption "zen-browser configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ inputs.zen-browser.packages."${system}".beta ];
  };
}
