{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.zen-browser;
  zen = inputs.zen-browser.packages.${pkgs.system};
in {
  options.my.home.zen-browser = with lib; {
    enable = mkEnableOption "zen-browser configuration";
    nightly = mkEnableOption "Get nightly build instead of beta.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ (if cfg.nightly then zen.twilight else zen.beta) ];
  };
}
