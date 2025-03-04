{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.librewolf;
in {
  options.my.home.librewolf = with lib; {
    enable = mkEnableOption "librewolf configuration";
    nightly = mkEnableOption "Get nightly build instead of beta.";
  };

  config.programs.librewolf = lib.mkIf cfg.enable {
    enable = true;
  };
}
